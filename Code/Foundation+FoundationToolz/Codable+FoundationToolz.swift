import Foundation
import SwiftyToolz

public extension Decodable
{
    init?(fromFilePath filePath: String)
    {
        self.init(from: URL(fileURLWithPath: filePath))
    }
    
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
    @discardableResult
    func save(toFilePath filePath: String,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) -> URL?
    {
        encode(options: options)?.save(toFilePath: filePath)
    }
    
    @discardableResult
    func save(to file: URL?,
              options: JSONEncoder.OutputFormatting = .prettyPrinted) -> URL?
    {
        encode(options: options)?.save(to: file)
    }
    
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
