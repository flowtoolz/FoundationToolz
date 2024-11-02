import Foundation
import SwiftyToolz

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

public struct InvalidURLStringError: Error
{
    let invalidURLString: URLString
}

public extension URL
{
    func mapSecurityScoped<Mapped>(_ map: (URL) throws -> Mapped) throws -> Mapped
    {
        guard startAccessingSecurityScopedResource() else
        {
            throw "Couldn't access security scoped URL"
        }
        
        let mapped = try map(self)
        
        stopAccessingSecurityScopedResource()
        
        return mapped
    }
    
    /// query parameters
    func parameters() -> [String : String]?
    {
        guard let query = self.query,
            query.count > 0 else
        {
            return nil
        }
        
        let keyValueStrings = query.components(separatedBy: "&")
        
        var parameters = [String : String]()
        
        for keyValueString in keyValueStrings
        {
            let keyAndValue = keyValueString.components(separatedBy: "=")
            
            if keyAndValue.count != 2 { continue }
            
            let key = keyAndValue[0]
            let value = keyAndValue[1]
            
            parameters[key] = value
        }
        
        return parameters
    }
    
    func queryDictionary() -> [String: String]?
    {
        guard let queryString = "\(self)".components(separatedBy: "?").last else
        {
            return nil
        }
        
        var query = [String: String]()
        
        let queryComponents = queryString.components(separatedBy: "&")
        
        for queryComponent in queryComponents
        {
            let keyValuePair = queryComponent.components(separatedBy: "=")
            
            guard keyValuePair.count == 2 else
            {
                continue
            }
            
            let key = keyValuePair[0]
            let value = keyValuePair[1].removingPercentEncoding
            
            query[key] = value
        }
        
        guard query.keys.count > 0 else
        {
            return nil
        }
        
        return query
    }
    
    static var documentDirectory: URL?
    {
        do
        {
            return try FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    static func + (url: URL, pathComponent: String) -> URL
    {
        url.appendingPathComponent(pathComponent)
    }
    
    var isDirectory: Bool
    {
        do
        {
            if let result = try resourceValues(forKeys: [.isDirectoryKey]).isDirectory
            {
                return result
            }
        }
        catch { log(error.readable) }
        
        return hasDirectoryPath
    }
}
