import Foundation
import SwiftyToolz

@available(macOS 12.0, iOS 15.0, *)
public extension URL
{
    func get<Value: Decodable>(_ type: Value.Type = Value.self) async throws -> Value
    {
        do
        {
            let (data, response) = try await URLSession.shared.data(from: self)
            
            let httpResponse = response as! HTTPURLResponse
            
            guard (200 ... 299).contains(httpResponse.statusCode) else
            {
                throw RequestError.validatingResponseStatusFailed(httpResponse, data)
            }
            
            guard let value = Value(data) else
            {
                throw RequestError.decodingDataFailed(httpResponse, data)
            }
            
            return value
        }
        catch let nsError as NSError
        {
            let isURLError = nsError.domain == URLError.errorDomain
            let urlErrorCode = isURLError ? URLError.Code(rawValue: nsError.code) : nil
            let requestError = RequestError.requestFailed(nsError, urlErrorCode)
            log(error: requestError.description)
            throw requestError
        }
        catch let requestError as RequestError
        {
            log(error: requestError.description)
            throw requestError
        }
    }
    
    func post<Value: Encodable>(_ value: Value) async throws
    {
        guard let valueData = value.encode() else
        {
            let requestError = RequestError.encodingDataFailed
            log(error: requestError.description)
            throw requestError
        }
        
        var request = URLRequest(url: self)
        request.httpMethod = "POST"
        request.httpBody = valueData
        
        do
        {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let httpResponse = response as! HTTPURLResponse
            
            guard (200...299).contains(httpResponse.statusCode) else
            {
                throw RequestError.validatingResponseStatusFailed(httpResponse, data)
            }
        }
        catch let nsError as NSError
        {
            let isURLError = nsError.domain == URLError.errorDomain
            let urlErrorCode = isURLError ? URLError.Code(rawValue: nsError.code) : nil
            let requestError = RequestError.requestFailed(nsError, urlErrorCode)
            log(error: requestError.description)
            throw requestError
        }
        catch let requestError as RequestError
        {
            log(error: requestError.description)
            throw requestError
        }
    }
    
    enum RequestError: Error, CustomStringConvertible, CustomDebugStringConvertible
    {
        public var localizedDescription: String { description }
        
        public var debugDescription: String { description }
        
        public var description: String
        {
            switch self
            {
            case .encodingDataFailed:
                return "Could not endecode the data."
            case .requestFailed(let nsError, let urlErrorCode):
                var message = nsError.localizedDescription
                if let urlErrorCode = urlErrorCode
                {
                    message += " URL error code: \(urlErrorCode.rawValue)"
                }
                return message
            case .decodingDataFailed(let response, _):
                let status = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                return "Could not decode the data. HTTP Status: " + status
            case .validatingResponseStatusFailed(let response, let data):
                let status = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                var message = "Unexpected HTTP Status: " + status
                if let dataString = data.utf8String
                {
                    message += "\nResponse data: " + dataString
                }
                return message
            }
        }
        
        case encodingDataFailed
        case requestFailed(NSError, URLError.Code?)
        case validatingResponseStatusFailed(HTTPURLResponse, Data)
        case decodingDataFailed(HTTPURLResponse, Data)
    }
}
