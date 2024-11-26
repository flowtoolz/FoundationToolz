import Foundation
import SwiftyToolz

public extension Data
{
    init(jsonObject: JSONObject) throws
    {
        guard JSONSerialization.isValidJSONObject(jsonObject) else
        {
            throw "Invalid top-level JSON object: \(jsonObject)"
        }
        
        self = try JSONSerialization.data(withJSONObject: jsonObject,
                                          options: .prettyPrinted)
    }
    
    init(fromFilePath filePath: String) throws
    {
        try self.init(from: URL(fileURLWithPath: filePath))
    }
    
    init(from file: URL?) throws
    {
        guard let file, FileManager.default.itemExists(file) else {
            throw "File does not exist: " + (file?.absoluteString ?? "nil")
        }
        
        self = try Data(contentsOf: file)
    }
    
    var debugPreview: String
    {
        utf8String ?? debugDescription
    }
    
    init(utf8String: String)
    {
        self = Data(utf8String.utf8)
    }
    
    var utf8String: String
    {
        String(decoding: self, as: UTF8.self)
    }
}

public typealias JSONObject = Any
