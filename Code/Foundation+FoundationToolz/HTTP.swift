import Foundation

@available(macOS 14.0, iOS 17.0, *)
public enum HTTP
{
    public static func sendRequest<Response: Decodable>
    (
        to endpoint: URLString,
        using method: Method = .GET,
        content: Encodable? = nil,
        authorizationValue: String? = nil,
        addingHeaders headersToAdd: [String: String]? = nil,
        timeoutInterval: Duration = defaultTimeoutInterval
    )
    async throws(RequestError) -> Response
    {
        try await throwingRequestError
        {
            try await sendRequest(to: try URL(validating: endpoint),
                                  using: method,
                                  content: content,
                                  authorizationValue: authorizationValue,
                                  addingHeaders: headersToAdd,
                                  timeoutInterval: timeoutInterval)
        }
    }
    
    public static func sendRequest<Response: Decodable>
    (
        to endpoint: URL,
        using method: Method = .GET,
        content: Encodable? = nil,
        authorizationValue: String? = nil,
        addingHeaders headersToAdd: [String: String]? = nil,
        timeoutInterval: Duration = defaultTimeoutInterval
    )
    async throws(RequestError) -> Response
    {
        let (responseContent, httpResponse) = try await sendRequest(to: endpoint,
                                                                    using: method,
                                                                    content: content,
                                                                    authorizationValue: authorizationValue,
                                                                    addingHeaders: headersToAdd,
                                                                    timeoutInterval: timeoutInterval)
        
        guard (200 ... 299).contains(httpResponse.statusCode) else
        {
            throw .unexpectedStatusCode(httpResponse, responseContent)
        }
        
        return try await throwingRequestError
        {
            try JSONDecoder().decode(Response.self,
                                     from: responseContent)
        }
    }
    
    public static func sendRequest
    (
        to endpoint: URL,
        using method: Method = .GET,
        content: Encodable? = nil,
        authorizationValue: String? = nil,
        addingHeaders headersToAdd: [String: String]? = nil,
        timeoutInterval: Duration = defaultTimeoutInterval
    )
    async throws(RequestError) -> (Data, HTTPURLResponse)
    {
        // configure request
        
        var urlRequest = URLRequest(url: endpoint)
        
        urlRequest.httpMethod = method.rawValue
        
        if let authorizationValue
        {
            urlRequest.setValue(authorizationValue, forHTTPHeaderField: "Authorization")
        }
        
        for (field, value) in (headersToAdd ?? [:])
        {
            urlRequest.addValue(value, forHTTPHeaderField: field)
        }
        
        // encode content and send request
        
        return try await throwingRequestError
        {
            if let content
            {
                urlRequest.httpBody = try JSONEncoder().encode(content)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            let (responseContent, response) = try await withTimeout(after: timeoutInterval)
            {
                try await URLSession.shared.data(for: urlRequest)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else
            {
                throw RequestError.noHTTPResponse(response, responseContent)
            }
            
            return (responseContent, httpResponse)
        }
    }
    
    public static var defaultTimeoutInterval: Duration = .seconds(10)
    
    public enum Method: String
    {
        case GET, POST, PUT, DELETE, PATCH
    }
    
    private static func throwingRequestError<Result>
    (
        action: () async throws -> Result
    )
    async throws(RequestError) -> Result
    {
        do { return try await action() }
        catch { throw RequestError(error) }
    }
    
    public enum RequestError: Error, CustomStringConvertible
    {
        init(_ error: Error)
        {
            switch error
            {
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
        
        public var description: String
        {
            switch self
            {
            case .invalidURLString(let invalidURLStringError):
                "💥 Invalid URL string: \"" + invalidURLStringError.invalidURLString.value + "\""
            case .encodingError(let encodingError):
                "💥 Encoding error (reason: \(encodingError.failureReason ?? "nil")): " + encodingError.localizedDescription
            case .timeout(let timeoutError):
                "💥 Timeout after " + timeoutError.duration.description
            case .urlError(let urlError):
                "💥 URL error (error code: \(urlError.code.rawValue)): " + urlError.localizedDescription
            case .noHTTPResponse(_, let responseContent):
                "💥 Response is not an HTTP response. Response content: " + responseContent.debugPreview
            case .unexpectedStatusCode(let httpResponse, let responseContent):
                "💥 Unexpected HTTP response status code \(httpResponse.statusCode). Response content: " + responseContent.debugPreview
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

@available(macOS 14.0, iOS 17.0, *)
extension URL
{
    init(validating urlString: URLString) throws(InvalidURLStringError)
    {
        guard let url = URL(string: urlString.value, encodingInvalidCharacters: false)
        else { throw InvalidURLStringError(invalidURLString: urlString) }
        
        self = url
    }
}

// TODO: everything from here on belongs to SwiftyToolz !

public struct InvalidURLStringError: Error
{
    let invalidURLString: URLString
}

// Allow URLString as right operand
public func + (base: URLString, path: URLString) -> URLString {
   base + path.value
}

// Append path operator
public func + (base: URLString, path: String) -> URLString {
   // Handle empty path
   guard !path.isEmpty else { return base }
   
   // Get base without trailing slash
   let baseValue = base.value.hasSuffix("/")
       ? String(base.value.dropLast())
       : base.value
   
   // Get path without leading slash
   let pathValue = path.hasPrefix("/")
       ? String(path.dropFirst())
       : path
   
   // Combine with single slash
   return URLString(baseValue + "/" + pathValue)
}

public struct URLString: ExpressibleByStringLiteral, Sendable
{
    public init(stringLiteral value: String)
    {
        self.value = value
    }
    
    public init(_ value: String)
    {
        self.value = value
    }
    
    public let value: String
}

@available(macOS 14.0, iOS 16.0, *)
func withTimeout<Result>
(
    after duration: Duration,
    startLongOperation: @escaping () async throws -> Result
)
async throws -> Result
{
    try await withThrowingTaskGroup(of: Result.self)
    {
        tasks in
        
        tasks.addTask
        {
            try await startLongOperation()
        }
        
        tasks.addTask
        {
            try await Task.sleep(for: duration)
            throw TimeoutError(duration: duration)
        }
        
        guard let result = try await tasks.next() else
        {
            /// will never happen since `tasks` is not empty
            throw CancellationError()
        }
        
        tasks.cancelAll()
        return result
    }
}

@available(macOS 13.0, iOS 16.0, *)
public struct TimeoutError: Error
{
    let duration: Duration
}
