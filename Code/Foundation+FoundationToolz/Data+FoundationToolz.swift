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
    
    init?(fromFilePath filePath: String)
    {
        self.init(from: URL(fileURLWithPath: filePath))
    }
    
    init?(from file: URL?)
    {
        guard let file = file, FileManager.default.itemExists(file) else { return nil }
        
        do
        {
            self = try Data(contentsOf: file)
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    @discardableResult
    func save(toFilePath filePath: String) -> URL?
    {
        save(to: URL(fileURLWithPath: filePath))
    }
    
    @discardableResult
    func save(to file: URL?) -> URL?
    {
        guard let file else { return nil }
        
        guard FileManager.default.itemExists(file) else
        {
            return FileManager.default.createFile(atPath: file.path,
                                                  contents: self) ? file : nil
        }
        
        do
        {
            try write(to: file)
            return file
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    var debugPreview: String
    {
        utf8String ?? debugDescription
    }
    
    var utf8String: String?
    {
        String(data: self, encoding: .utf8)
    }
}

public typealias JSONObject = Any
