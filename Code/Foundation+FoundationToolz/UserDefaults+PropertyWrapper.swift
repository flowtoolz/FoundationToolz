import Foundation

@propertyWrapper
public struct UserDefault<Value>
{
    public init(key: String,
                defaultValue: Value,
                container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }
    
    public let key: String
    public let defaultValue: Value
    public var container: UserDefaults

    public var wrappedValue: Value
    {
        get
        {
            container.object(forKey: key) as? Value ?? defaultValue
        }
        
        set
        {
            container.set(newValue, forKey: key)
        }
    }
}
