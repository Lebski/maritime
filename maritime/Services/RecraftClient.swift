import Foundation

/// Thin wrapper over fal.ai's HTTP API for the Recraft v4 model.
///
/// Used to generate the initial batch of character portrait variations.
/// Constructed per-call with a fresh API key so the value is read from
/// Keychain on demand (see AppSettings).
struct RecraftClient {

    let apiKey: String
    var session: URLSession = .shared

    private static let runBase = "https://fal.run"

    static let modelID = "fal-ai/recraft-v4"

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
                return "fal.ai (recraft-v4) returned \(status). \(body)"
            case .decode(let detail):
                return "Couldn't read recraft-v4 response: \(detail)"
            case .network(let err):
                return "Network error: \(err.localizedDescription)"
            case .empty:
                return "recraft-v4 returned no images."
            }
        }
    }

    /// Recraft v4 request shape. The model accepts a prompt + image_size +
    /// optional style. We always ask for portrait_4_3 + realistic_image style
    /// for character work; callers control prompt and num_images.
    struct GenerateRequest: Encodable {
        var prompt: String
        var image_size: String? = "portrait_4_3"
        var style: String? = "realistic_image"
        var num_images: Int? = 1
        var negative_prompt: String?
        var seed: Int?
    }

    struct GenerateResponse: Decodable {
        struct Image: Decodable {
            let url: String
            let content_type: String?
            let width: Int?
            let height: Int?
        }
        let images: [Image]
        let seed: Int?
    }

    /// Submit a generation. Returns the parsed response — call
    /// `downloadImage(url:)` per image to get the bytes.
    func generate(_ request: GenerateRequest) async throws -> GenerateResponse {
        guard !apiKey.isEmpty else { throw ClientError.missingKey }

        let endpointString = "\(Self.runBase)/\(Self.modelID)"
        guard let endpoint = URL(string: endpointString) else {
            throw ClientError.decode("bad endpoint URL")
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 120

        do {
            urlRequest.httpBody = try JSONEncoder.recraft.encode(request)
        } catch {
            throw ClientError.decode("encode failed: \(error.localizedDescription)")
        }

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

        let decoded: GenerateResponse
        do {
            decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        } catch {
            throw ClientError.decode(error.localizedDescription)
        }

        guard !decoded.images.isEmpty else { throw ClientError.empty }
        return decoded
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

private extension JSONEncoder {
    static let recraft: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return encoder
    }()
}
