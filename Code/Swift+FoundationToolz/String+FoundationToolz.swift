import Foundation
import SwiftyToolz

public extension String
{
    func removing(prefix: String) -> String
    {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
    
    var lines: [String]
    {
        components(separatedBy: .newlines)
    }
    
    func removing(_ substring: String) -> String
    {
        replacingOccurrences(of: substring, with: "")
    }
    
    init(unicode: Int)
    {
        var unicodeCharacter = unichar(unicode)
        
        self = String(utf16CodeUnits: &unicodeCharacter, count: 1)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    init?(with filePath: String)
    {
        do
        {
            self = try String(contentsOfFile: filePath)
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    var data: Data? { data(using: .utf8) }
    
    var fileName: String
    {
        URL(fileURLWithPath: self).lastPathComponent
    }
    
    func fileExtension(maxLength: Int = 5) -> String?
    {
        let components = components(separatedBy: ".")
        guard let lastComponent = components.last,
            components.count > 1,
            lastComponent.count > 0,
            lastComponent.count <= maxLength else { return nil }
        return lastComponent
    }
    
    func dateString(fromFormat: String, toFormat: String) -> String
    {
        guard let date = Date(fromString: self, withFormat: fromFormat) else
        {
            return self
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = toFormat
        return formatter.string(from: date)
    }
}
