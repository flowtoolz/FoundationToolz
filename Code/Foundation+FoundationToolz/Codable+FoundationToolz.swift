import Foundation
import SwiftyToolz

public extension Decodable
{
    init(fromFilePath filePath: String) throws
    {
        try self.init(fromJSONFile: URL(fileURLWithPath: filePath))
    }
    
    init(fromJSONFile file: URL) throws
    {
        self = try Self(jsonData: Data(from: file))
    }
    
    init(jsonData: Data?) throws
    {
        guard let jsonData else { throw "jsonData is nil" }
        self = try JSONDecoder().decode(Self.self, from: jsonData)
    }
}

public extension Encodable
{
    @discardableResult
    func save(toFilePath filePath: String,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) throws -> URL
    {
        if #available(iOS 16.0, macOS 13.0, *)
        {
            try save(to: URL(filePath: filePath))
        }
        else
        {
            try save(to: URL(fileURLWithPath: filePath))
        }
    }
    
    @discardableResult
    func save(to file: URL?,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) throws -> URL
    {
        guard let file else { throw "File is nil" }
        
        let data = try encode(options: options)
        
        if FileManager.default.itemExists(file)
        {
            try data.write(to: file, options: .atomic)
        }
        else if !FileManager.default.createFile(atPath: file.path, contents: data)
        {
            throw "Failed to create file: " + file.absoluteString
        }
        
        return file
    }
    
    func encode(options: JSONEncoder.OutputFormatting = .prettyPrinted) throws -> Data
    {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = options
        return try jsonEncoder.encode(self)
    }
}
