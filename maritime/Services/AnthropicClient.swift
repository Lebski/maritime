import Foundation

/// Thin wrapper over the Anthropic Messages API.
///
/// Designed to be constructed per-call with a fresh API key so the
/// key can be read from Keychain on demand (see AppSettings).
struct AnthropicClient {

    let apiKey: String
    var model: String = "claude-sonnet-4-6"
    var maxTokens: Int = 1024
    var session: URLSession = .shared

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let apiVersion = "2023-06-01"

    // MARK: Types

    enum Role: String, Codable { case user, assistant }

    struct Message: Codable {
        let role: Role
        let content: String
    }

    /// The system prompt is sent as a cacheable block so repeat generations
    /// in a session reuse Anthropic's prompt cache.
    struct Request {
        var system: String
        var messages: [Message]
        var maxTokens: Int?
        var model: String?
    }

    struct Response {
        var text: String
        var stopReason: String?
        var inputTokens: Int?
        var outputTokens: Int?
        var cacheReadTokens: Int?
        var cacheWriteTokens: Int?
    }

    enum ClientError: Error, LocalizedError {
        case missingKey
        case http(status: Int, body: String)
        case decode(String)
        case network(URLError)
        case empty

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "No Anthropic API key configured. Open Preferences (⌘,) to add one."
            case .http(let status, let body):
                return "Anthropic API returned \(status). \(body)"
            case .decode(let detail):
                return "Couldn't read Anthropic response: \(detail)"
            case .network(let err):
                return "Network error: \(err.localizedDescription)"
            case .empty:
                return "Claude returned an empty response."
            }
        }
    }

    // MARK: Public API

    func send(_ request: Request) async throws -> Response {
        guard !apiKey.isEmpty else { throw ClientError.missingKey }

        var urlRequest = URLRequest(url: Self.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 180
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")

        let body = RequestBody(
            model: request.model ?? model,
            maxTokens: request.maxTokens ?? maxTokens,
            system: [SystemBlock(text: request.system)],
            messages: request.messages
        )

        do {
            urlRequest.httpBody = try JSONEncoder.anthropic.encode(body)
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

        let decoded: ResponseBody
        do {
            decoded = try JSONDecoder.anthropic.decode(ResponseBody.self, from: data)
        } catch {
            throw ClientError.decode(error.localizedDescription)
        }

        let text = decoded.content
            .compactMap { $0.type == "text" ? $0.text : nil }
            .joined()

        guard !text.isEmpty else { throw ClientError.empty }

        return Response(
            text: text,
            stopReason: decoded.stopReason,
            inputTokens: decoded.usage?.inputTokens,
            outputTokens: decoded.usage?.outputTokens,
            cacheReadTokens: decoded.usage?.cacheReadInputTokens,
            cacheWriteTokens: decoded.usage?.cacheCreationInputTokens
        )
    }

    // MARK: Wire format

    private struct SystemBlock: Encodable {
        let type = "text"
        let text: String
        let cacheControl = CacheControl()

        struct CacheControl: Encodable {
            let type = "ephemeral"
        }

        enum CodingKeys: String, CodingKey {
            case type, text
            case cacheControl = "cache_control"
        }
    }

    private struct RequestBody: Encodable {
        let model: String
        let maxTokens: Int
        let system: [SystemBlock]
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model, system, messages
            case maxTokens = "max_tokens"
        }
    }

    private struct ResponseBody: Decodable {
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
        struct Usage: Decodable {
            let inputTokens: Int?
            let outputTokens: Int?
            let cacheCreationInputTokens: Int?
            let cacheReadInputTokens: Int?

            enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
                case cacheCreationInputTokens = "cache_creation_input_tokens"
                case cacheReadInputTokens = "cache_read_input_tokens"
            }
        }
        let content: [ContentBlock]
        let stopReason: String?
        let usage: Usage?

        enum CodingKeys: String, CodingKey {
            case content, usage
            case stopReason = "stop_reason"
        }
    }
}

private extension JSONEncoder {
    static let anthropic: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return encoder
    }()
}

private extension JSONDecoder {
    static let anthropic: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}
