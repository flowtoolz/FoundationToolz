import Foundation

public extension Date
{
    init?(fromString string: String, withFormat format: String)
    {
        let formatter = DateFormatter()
        
        formatter.dateFormat = format
        
        guard let date = formatter.date(from: string) else
        {
            return nil
        }
        
        self = date
    }
    
    init?(year: Int, month: Int, day: Int)
    {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = Calendar.current.date(from: components) else { return nil }
        self = date
    }
    
    var utcString: String
    {
        ISO8601DateFormatter().string(from: self)
    }
    
    func string(withFormat format: String) -> String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
