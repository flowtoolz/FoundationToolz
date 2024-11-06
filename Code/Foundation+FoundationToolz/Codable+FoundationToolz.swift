import Foundation
import SwiftyToolz

public extension Decodable
{
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    init?(fromFilePath filePath: String)
    {
        self.init(from: URL(fileURLWithPath: filePath))
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    init?(from file: URL?)
    {
        if let decodedSelf = Self(Data(from: file))
        {
            self = decodedSelf
        }
        else
        {
            return nil
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    init?(_ jsonData: Data?)
    {
        guard let jsonData else { return nil }
        
        do
        {
            self = try Self(jsonData: jsonData)
        }
        catch
        {
            log(error.readable)
            return nil
        }
    }
    
    init(jsonData: Data) throws
    {
        self = try JSONDecoder().decode(Self.self, from: jsonData)
    }
}

public extension Encodable
{
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func save(toFilePath filePath: String,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) -> URL?
    {
        encode(options: options)?.save(toFilePath: filePath)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func save(to file: URL?,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) -> URL?
    {
        encode(options: options)?.save(to: file)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func encode(options: JSONEncoder.OutputFormatting = .prettyPrinted) -> Data?
    {
        do
        {
            return try encode(options: options) as Data
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    func encode(options: JSONEncoder.OutputFormatting = .prettyPrinted) throws -> Data
    {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = options
        return try jsonEncoder.encode(self)
    }
}
