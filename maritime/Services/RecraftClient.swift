import Foundation

/// Thin wrapper over fal.ai's queue API for the Recraft v4 Pro model. Each
/// call submits one job, polls its status URL until it completes, then fetches
/// the response. v4 Pro produces a single image per submission, so callers
/// fan out multiple submissions in parallel for portrait grids.
///
/// Constructed per-call with a fresh API key so the value is read from
/// Keychain on demand (see AppSettings).
struct RecraftClient {

    let apiKey: String
    var session: URLSession = .shared

    static let modelID = "fal-ai/recraft/v4/pro/text-to-image"
    static let queueBase = "https://queue.fal.run"

    /// Hard cap on how long we wait for a single submission to finish.
    var pollTimeout: TimeInterval = 180
    /// Initial poll delay; exponential up to ~2s.
    var initialPollDelay: TimeInterval = 0.6
    var maxPollDelay: TimeInterval = 2.0

    enum ClientError: Error, LocalizedError {
        case missingKey
        case http(status: Int, body: String)
        case decode(String)
        case network(URLError)
        case empty
        case timedOut
        case queueFailed(String)

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "No fal.ai API key configured. Open Preferences (⌘,) to add one."
            case .http(let status, let body):
                return "fal.ai returned \(status). \(body)"
            case .decode(let detail):
                return "Couldn't read recraft response: \(detail)"
            case .network(let err):
                return "Network error: \(err.localizedDescription)"
            case .empty:
                return "recraft returned no images."
            case .timedOut:
                return "recraft job didn't finish in time."
            case .queueFailed(let detail):
                return "recraft job failed: \(detail)"
            }
        }
    }

    /// Recraft v4 Pro request shape. v4 Pro accepts prompt + image_size
    /// (preset string) plus a few optional knobs we don't use yet (colors,
    /// background_color, enable_safety_checker).
    struct GenerateRequest: Encodable {
        var prompt: String
        var image_size: String? = "portrait_4_3"
        var enable_safety_checker: Bool? = true
    }

    /// Response shape from `GET {response_url}` once a queued job finishes.
    struct GenerateResponse: Decodable {
        struct Image: Decodable {
            let url: String
            let content_type: String?
            let file_name: String?
            let file_size: Int?
        }
        let images: [Image]
    }

    /// Submit ack returned by `POST {queueBase}/{modelID}`.
    private struct QueueSubmitResponse: Decodable {
        let request_id: String
        let status_url: String
        let response_url: String
    }

    /// Status response shape returned by `GET {status_url}`.
    private struct QueueStatusResponse: Decodable {
        let status: String   // IN_QUEUE | IN_PROGRESS | COMPLETED | FAILED ...
        let response_url: String?
    }

    /// Submit one job, poll until it completes, return the parsed response.
    /// Callers then call `downloadImage(url:)` per image to get bytes. The
    /// submit + final response are recorded as a single AIRequestLog entry;
    /// poll requests aren't logged individually to avoid spamming the log.
    func submitAndAwait(_ request: GenerateRequest, label: String? = nil) async throws -> GenerateResponse {
        guard !apiKey.isEmpty else { throw ClientError.missingKey }

        let submitURL = URL(string: "\(Self.queueBase)/\(Self.modelID)")!

        let logID = await AIRequestLog.shared.begin(
            provider: .recraft,
            endpoint: submitURL.absoluteString,
            model: Self.modelID,
            label: label,
            requestBody: AIRequestLog.prettyJSON(request)
        )

        do {
            let submit = try await postJSON(submitURL, body: request, decodingTo: QueueSubmitResponse.self)
            let statusURL = URL(string: submit.status_url) ?? submitURL
            let responseURL = URL(string: submit.response_url) ?? submitURL

            let deadline = Date().addingTimeInterval(pollTimeout)
            var delay = initialPollDelay

            while Date() < deadline {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay = min(maxPollDelay, delay * 1.4)

                let status = try await getJSON(statusURL, decodingTo: QueueStatusResponse.self)
                switch status.status.uppercased() {
                case "COMPLETED":
                    let resolved = status.response_url.flatMap(URL.init(string:)) ?? responseURL
                    let (decoded, raw) = try await getJSONWithBody(resolved, decodingTo: GenerateResponse.self)
                    guard !decoded.images.isEmpty else {
                        let err = ClientError.empty
                        await AIRequestLog.shared.fail(id: logID, error: err.errorDescription ?? "empty")
                        throw err
                    }
                    let summary = "\(decoded.images.count) portrait\(decoded.images.count == 1 ? "" : "s")"
                    await AIRequestLog.shared.succeed(
                        id: logID,
                        summary: summary,
                        body: AIRequestLog.prettyJSON(data: raw)
                    )
                    return decoded
                case "FAILED", "CANCELLED", "ERROR":
                    let err = ClientError.queueFailed(status.status)
                    await AIRequestLog.shared.fail(id: logID, error: err.errorDescription ?? status.status)
                    throw err
                default:
                    continue
                }
            }
            let err = ClientError.timedOut
            await AIRequestLog.shared.fail(id: logID, error: err.errorDescription ?? "timed out")
            throw err
        } catch let err as ClientError {
            await AIRequestLog.shared.fail(id: logID, error: err.errorDescription ?? "recraft error")
            throw err
        } catch {
            await AIRequestLog.shared.fail(id: logID, error: error.localizedDescription)
            throw error
        }
    }

    /// Download bytes from a fal CDN URL returned by the generate response.
    func downloadImage(url: String) async throws -> Data {
        guard let parsed = URL(string: url) else {
            throw ClientError.decode("bad image URL: \(url)")
        }
        do {
            let (data, response) = try await session.data(from: parsed)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw ClientError.http(status: status, body: "image download failed")
            }
            return data
        } catch let err as URLError {
            throw ClientError.network(err)
        }
    }

    // MARK: - HTTP helpers

    private func postJSON<Body: Encodable, Out: Decodable>(_ url: URL,
                                                           body: Body,
                                                           decodingTo: Out.Type) async throws -> Out {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 60
        do {
            req.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ClientError.decode("encode failed: \(error.localizedDescription)")
        }
        let (decoded, _): (Out, Data) = try await send(req)
        return decoded
    }

    private func getJSON<Out: Decodable>(_ url: URL, decodingTo: Out.Type) async throws -> Out {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 60
        let (decoded, _): (Out, Data) = try await send(req)
        return decoded
    }

    private func getJSONWithBody<Out: Decodable>(_ url: URL,
                                                 decodingTo: Out.Type) async throws -> (Out, Data) {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 60
        return try await send(req)
    }

    private func send<Out: Decodable>(_ req: URLRequest) async throws -> (Out, Data) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch let err as URLError {
            throw ClientError.network(err)
        }
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.decode("non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<binary>"
            throw ClientError.http(status: http.statusCode, body: body)
        }
        do {
            let decoded = try JSONDecoder().decode(Out.self, from: data)
            return (decoded, data)
        } catch {
            throw ClientError.decode(error.localizedDescription)
        }
    }
}
