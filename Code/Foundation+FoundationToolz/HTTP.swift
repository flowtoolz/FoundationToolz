import FoundationToolz
import Foundation
import SwiftyToolz

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
