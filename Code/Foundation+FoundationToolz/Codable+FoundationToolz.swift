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
        guard let jsonData else { throw "data is nil" }
        self = try JSONDecoder().decode(Self.self, from: jsonData)
    }
}

public extension Encodable
{
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func save(toFilePath filePath: String,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) throws -> URL
    {
        try encode(options: options).save(toFilePath: filePath)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func save(to file: URL?,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) throws -> URL
    {
        try encode(options: options).save(to: file)
    }
    
    func encode(options: JSONEncoder.OutputFormatting = .prettyPrinted) throws -> Data
    {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = options
        return try jsonEncoder.encode(self)
    }
}
