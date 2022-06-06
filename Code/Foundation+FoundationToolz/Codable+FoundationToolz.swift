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
        guard let jsonData = jsonData else { return nil }
        
        do
        {
            self = try Self(jsonData: jsonData)
        }
        catch
        {
            log(error)
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
    func save(toFilePath filePath: String) -> URL?
    {
        encode()?.save(toFilePath: filePath)
    }
    
    @discardableResult
    func save(to file: URL?) -> URL?
    {
        encode()?.save(to: file)
    }
    
    func encode() -> Data?
    {
        do
        {
            return try encode() as Data
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    func encode() throws -> Data
    {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return try jsonEncoder.encode(self)
    }
}
