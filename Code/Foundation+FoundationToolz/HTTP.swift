import Foundation

@available(macOS 14.0, *)
public enum HTTP {
    static func sendRequest<Response: Decodable>(
        to endpoint: URLString,
        using method: Method = .GET,
        content: Encodable? = nil,
        authorizationValue: String? = nil,
        addingHeaders headersToAdd: [String: String]? = nil,
        timeoutInterval: Duration = .seconds(10)
    ) async throws(RequestError) -> Response {
        let url: URL
        
        do {
            url = try URL(validating: endpoint)
        } catch {
            throw .invalidURLString(error)
        }
        
        return try await sendRequest(to: url,
                                     using: method,
                                     content: content,
                                     authorizationValue: authorizationValue,
                                     addingHeaders: headersToAdd,
                                     timeoutInterval: timeoutInterval)
    }
    
    static func sendRequest<Response: Decodable>(
        to endpoint: URL,
        using method: Method = .GET,
        content: Encodable? = nil,
        authorizationValue: String? = nil,
        addingHeaders headersToAdd: [String: String]? = nil,
        timeoutInterval: Duration = .seconds(10)
    ) async throws(RequestError) -> Response {
        let (responseContent, httpResponse) = try await sendRequest(to: endpoint,
                                                                       using: method,
                                                                       content: content,
                                                                       authorizationValue: authorizationValue,
                                                                       addingHeaders: headersToAdd,
                                                                       timeoutInterval: timeoutInterval)
        
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw .unexpectedStatusCode(httpResponse, responseContent)
        }
        
        do {
            return try JSONDecoder().decode(Response.self, from: responseContent)
        } catch {
            throw RequestError(error)
        }
    }
    
    static func sendRequest(
        to endpoint: URL,
        using method: Method = .GET,
        content: Encodable? = nil,
        authorizationValue: String? = nil,
        addingHeaders headersToAdd: [String: String]? = nil,
        timeoutInterval: Duration = .seconds(10)
    ) async throws(RequestError) -> (Data, HTTPURLResponse) {
        var urlRequest = URLRequest(url: endpoint)
        
        urlRequest.httpMethod = method.rawValue
        
        if let authorizationValue {
            urlRequest.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        }
        
        for (field, value) in (headersToAdd ?? [:]) {
            urlRequest.addValue(value, forHTTPHeaderField: field)
        }
        
        let (responseContent, response): (Data, URLResponse)
        
        do {
            if let content {
                urlRequest.httpBody = try JSONEncoder().encode(content)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            (responseContent, response) = try await withTimeout(after: timeoutInterval) {
                try await URLSession.shared.data(for: urlRequest)
            }
        } catch {
            throw RequestError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw .noHTTPResponse(response, responseContent)
        }
        
        return (responseContent, httpResponse)
    }
    
    enum Method: String {
        case GET, POST, PUT, DELETE, PATCH
    }
    
    public enum RequestError: Error, CustomStringConvertible {
        init(_ error: Error) {
            switch error {
            case let requestError as RequestError:
                self = requestError
            case let invalidStringError as InvalidURLStringError:
                self = .invalidURLString(invalidStringError)
            case let encodingError as EncodingError:
                self = .encodingError(encodingError)
            case let timeoutError as TimeoutError:
                self = .timeout(timeoutError)
            case let urlError as URLError:
                self = .urlError(urlError)
            case let decodingError as DecodingError:
                self = .decodingError(decodingError)
            default:
                self = .unexpectedError(error)
            }
        }
        
        public var description: String {
            switch self {
            case .invalidURLString(let invalidURLStringError):
                "💥 Invalid URL string: \"" + invalidURLStringError.invalidURLString.value + "\""
            case .encodingError(let encodingError):
                "💥 Encoding error (reason: \(encodingError.failureReason ?? "nil")): " + encodingError.localizedDescription
            case .timeout(let timeoutError):
                "💥 Timeout after " + timeoutError.duration.description
            case .urlError(let urlError):
                "💥 URL error (error code: \(urlError.code.rawValue)): " + urlError.localizedDescription
            case .noHTTPResponse(_, let responseContent):
                "💥 Response is not an HTTP response. Response content: " + responseContent.asString
            case .unexpectedStatusCode(let httpResponse, let responseContent):
                "💥 Unexpected HTTP response status code \(httpResponse.statusCode). Response content: " + responseContent.asString
            case .decodingError(let decodingError):
                "💥 Decoding error (reason: \(decodingError.failureReason ?? "nil")): " + decodingError.localizedDescription
            case .unexpectedError(let error):
                "💥 Unexpected error: " + error.localizedDescription
            }
        }
        
        case invalidURLString(InvalidURLStringError)
        case encodingError(EncodingError)
        case timeout(TimeoutError)
        case urlError(URLError)
        case noHTTPResponse(URLResponse, Data)
        case unexpectedStatusCode(HTTPURLResponse, Data)
        case decodingError(DecodingError)
        case unexpectedError(Error)
    }
}

extension Data {
    var asString: String {
        String(data: self, encoding: .utf8) ?? debugDescription
    }
}

@available(macOS 14.0, *)
extension URL {
    init(validating urlString: URLString) throws(InvalidURLStringError) {
        if let url = URL(string: urlString.value, encodingInvalidCharacters: false) {
            self = url
        } else {
            throw InvalidURLStringError(invalidURLString: urlString)
        }
    }
}

public struct InvalidURLStringError: Error {
    let invalidURLString: URLString
}

public struct URLString: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.value = value
    }
    
    init(_ value: String) {
        self.value = value
    }
    
    let value: String
}

@available(macOS 13.0, *)
func withTimeout<Result>(
    after duration: Duration,
    startLongOperation: @escaping () async throws -> Result
) async throws -> Result {
    try await withThrowingTaskGroup(of: Result.self) { tasks in
        tasks.addTask {
            try await startLongOperation()
        }
        
        tasks.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError(duration: duration)
        }
        
        guard let result = try await tasks.next() else {
            /// will never happen since `tasks` is not empty
            throw CancellationError()
        }
        
        tasks.cancelAll()
        return result
    }
}

@available(macOS 13.0, *)
public struct TimeoutError: Error {
    let duration: Duration
}
