import Foundation
import SwiftyToolz

extension Dictionary
{
    // MARK: - Dictionary representing URL query parameters
    
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
