import Foundation
import SwiftyToolz

public extension Dictionary
{
    var prettyPrinted: String
    {
        get throws
        {
            try Data(jsonObject: self).utf8String
        }
    }
    
    /// Dictionary representing URL query parameters
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func stringFromParameters() -> String
    {
        let parameterArray = self.map
        {
            (key, value) in
            
            let key = String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let value = String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            guard let definiteKey = key, let definiteValue = value else {
                log(error: "Couldn't parse to string")
                return ""
            }
            
            return "\(definiteKey)=\(definiteValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
}
