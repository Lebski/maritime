import Foundation

/// Thin wrapper over fal.ai's HTTP API for the Nano Banana 2 model.
///
/// Designed to be constructed per-call with a fresh API key so the
/// key can be read from Keychain on demand (see AppSettings).
struct FalaiClient {

    let apiKey: String
    var session: URLSession = .shared

    private static let runBase = "https://fal.run"
    private static let metadataURL = URL(string: "https://api.fal.ai/v1/models")!

    static let modelID = "fal-ai/nano-banana-2"

    // MARK: Types

    enum ClientError: Error, LocalizedError {
        case missingKey
        case http(status: Int, body: String)
        case decode(String)
        case network(URLError)
        case empty

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "No fal.ai API key configured. Open Preferences (⌘,) to add one."
            case .http(let status, let body):
                return "fal.ai API returned \(status). \(body)"
            case .decode(let detail):
                return "Couldn't read fal.ai response: \(detail)"
            case .network(let err):
                return "Network error: \(err.localizedDescription)"
            case .empty:
                return "fal.ai returned no images."
            }
        }
    }

    /// Shared shape for both T2I (`POST /fal-ai/nano-banana-2`) and image-to-image
    /// (`POST /fal-ai/nano-banana-2/edit`). The only difference is whether
    /// `image_urls` is present.
    struct GenerateRequest: Encodable {
        var prompt: String
        var image_urls: [String]?
        var num_images: Int? = 1
        var aspect_ratio: String? = "1:1"
        var output_format: String? = "png"
        var resolution: String? = "1K"
        var seed: Int?
        var safety_tolerance: String?
    }

    struct GenerateResponse: Decodable {
        struct Image: Decodable {
            let url: String
            let content_type: String?
            let width: Int?
            let height: Int?
        }
        let images: [Image]
        let description: String?
    }

    // MARK: Public API

    /// Submit a generation. `edit == true` uses the /edit endpoint and requires
    /// `image_urls` to be non-empty. Returns the parsed response — call
    /// `downloadImage(url:)` to get the bytes for the first result.
    func generate(_ request: GenerateRequest, edit: Bool, label: String? = nil) async throws -> GenerateResponse {
        guard !apiKey.isEmpty else { throw ClientError.missingKey }

        let endpointString = edit
            ? "\(Self.runBase)/\(Self.modelID)/edit"
            : "\(Self.runBase)/\(Self.modelID)"
        guard let endpoint = URL(string: endpointString) else {
            throw ClientError.decode("bad endpoint URL")
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder.fal.encode(request)
        } catch {
            throw ClientError.decode("encode failed: \(error.localizedDescription)")
        }

        let logID = await AIRequestLog.shared.begin(
            provider: .fal,
            endpoint: endpointString,
            model: Self.modelID,
            label: label,
            requestBody: AIRequestLog.prettyJSON(request)
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let err as URLError {
            let clientErr = ClientError.network(err)
            await AIRequestLog.shared.fail(id: logID, error: clientErr.errorDescription ?? err.localizedDescription)
            throw clientErr
        }

        guard let http = response as? HTTPURLResponse else {
            let clientErr = ClientError.decode("non-HTTP response")
            await AIRequestLog.shared.fail(id: logID, error: clientErr.errorDescription ?? "non-HTTP response")
            throw clientErr
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<binary>"
            let clientErr = ClientError.http(status: http.statusCode, body: bodyText)
            await AIRequestLog.shared.fail(id: logID, error: clientErr.errorDescription ?? "HTTP \(http.statusCode)")
            throw clientErr
        }

        let decoded: GenerateResponse
        do {
            decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        } catch {
            let clientErr = ClientError.decode(error.localizedDescription)
            await AIRequestLog.shared.fail(id: logID, error: clientErr.errorDescription ?? error.localizedDescription)
            throw clientErr
        }

        guard !decoded.images.isEmpty else {
            let clientErr = ClientError.empty
            await AIRequestLog.shared.fail(id: logID, error: clientErr.errorDescription ?? "empty")
            throw clientErr
        }

        let first = decoded.images[0]
        let dims: String = {
            if let w = first.width, let h = first.height { return " · \(w)×\(h)" }
            return ""
        }()
        let summary = "\(decoded.images.count) image\(decoded.images.count == 1 ? "" : "s")\(dims)"
        await AIRequestLog.shared.succeed(
            id: logID,
            summary: summary,
            body: AIRequestLog.prettyJSON(data: data)
        )

        return decoded
    }

    /// Convenience: run a generation and return the bytes of the first result image.
    func generateAndFetch(_ request: GenerateRequest, edit: Bool, label: String? = nil) async throws -> Data {
        let response = try await generate(request, edit: edit, label: label)
        return try await downloadImage(url: response.images[0].url)
    }

    /// Free key validation against the models metadata endpoint.
    /// Throws `.http(401, …)` for an invalid key, `.network(…)` for offline.
    func ping() async throws {
        guard !apiKey.isEmpty else { throw ClientError.missingKey }

        var urlRequest = URLRequest(url: Self.metadataURL)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
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
}

/// Encode `Data` (PNG/JPEG/etc) as a `data:` URI suitable for `image_urls`.
/// Nano Banana sniffs the content type from the bytes; we always declare `image/png`
/// since the file picker most commonly produces PNG and the model accepts mismatches.
func dataURIForImage(_ data: Data) -> String {
    "data:image/png;base64,\(data.base64EncodedString())"
}

private extension JSONEncoder {
    static let fal: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return encoder
    }()
}
