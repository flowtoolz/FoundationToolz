import Foundation
import Security
import SwiftyToolz

/// High-level interface to Apple's Keychain Services API
public enum Keychain {
    /// A property wrapper that provides convenient access to Keychain items.
    /// Values are automatically encoded/decoded using the Codable protocol.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @propertyWrapper
    public struct Item<Value: Codable> {
        public var wrappedValue: Value? {
            get {
                do {
                    return try load(firstItem: description)
                } catch {
                    log(error: error.localizedDescription)
                    return nil
                }
            }
            
            set {
                do {
                    try update(items: description,
                               with: newValue,
                               addIfNotFound: true)
                } catch {
                    log(error: error.localizedDescription)
                }
            }
        }
        
        public init(_ description: ItemDescription) { self.description = description }
        
        private let description: ItemDescription
    }
    
    /// Adds a new item to the Keychain.
    /// - Parameters:
    ///   - item: Description of the item to add
    ///   - value: The value to store, must conform to Encodable
    ///   - updateIfDuplicate: If true, updates existing item instead of throwing error
    /// - Throws: Error if addition fails or if item exists and updateIfDuplicate is false
    public static func add(item: ItemDescription,
                           value: Encodable,
                           updateIfDuplicate: Bool = false) throws {
        let query: [CFString: Any] = [
            kSecAttrApplicationTag: item.tag,
            kSecClass: item.class.kSecClassValue,
            kSecValueData: try value.encode(),
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
        
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        
        guard addStatus != errSecDuplicateItem else {
            if updateIfDuplicate {
                return try update(items: item, with: value)
            } else {
                throw "Could not add item since it already exists. OS Status: " + addStatus.description
            }
        }
        
        guard addStatus == errSecSuccess else {
            throw "Could not add item. OS Status: " + addStatus.description
        }
    }
    
    /// Updates existing items in the Keychain matching the description.
    /// - Parameters:
    ///   - items: Description of the items to update
    ///   - newValue: The new value to store, must conform to Encodable
    ///   - addIfNotFound: If true, creates new item when no matching items exist
    /// - Throws: Error if update fails or if items don't exist and addIfNotFound is false
    public static func update(items: ItemDescription,
                              with newValue: Encodable,
                              addIfNotFound: Bool = false) throws {
        let query: [CFString: Any] = [
            kSecAttrApplicationTag: items.tag,
            kSecClass: items.class.kSecClassValue,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
        
        let update: [CFString: Any] = [
            kSecValueData: try newValue.encode()
        ]
        
        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        
        guard updateStatus != errSecItemNotFound else {
            if addIfNotFound {
                return try add(item: items, value: newValue)
            } else {
                throw "Could not update items since none were found. OS Status: " + updateStatus.description
            }
        }
        
        guard updateStatus == errSecSuccess else {
            throw "Could not update item. OS Status: " + updateStatus.description
        }
    }
    
    /// Loads the first item from the Keychain matching the description.
    /// - Parameter firstItem: Description of the item to load
    /// - Returns: Decoded value if item exists, nil otherwise
    /// - Throws: Error if reading from Keychain fails or if decoding fails
    public static func load<Item: Decodable>(firstItem: ItemDescription) throws -> Item? {
        // Set up the query for fetching data from Keychain
        let query: [CFString: Any] = [
            kSecAttrApplicationTag: firstItem.tag,
            kSecClass: firstItem.class.kSecClassValue,
            kSecReturnData: true,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        // Fetch the item from Keychain
        var itemReference: CFTypeRef?
        
        let readStatus = SecItemCopyMatching(query as CFDictionary, &itemReference)
        
        guard readStatus == errSecSuccess else {
            throw "Could not read the Keychain. OS Status: " + readStatus.description
        }
        
        guard let itemData = itemReference as? Data else {
            // an item for the given key simply does not exist in the keychain (yet)
            return nil
        }
        
        return try Item(jsonData: itemData)
    }
    
    /// Deletes items from the Keychain matching the description.
    /// - Parameter items: Description of the items to delete
    /// - Throws: Error if deletion fails
    public static func delete(items: ItemDescription) throws {
        // Set up the query to identify which item to delete
        let query: [CFString: Any] = [
            kSecClass: items.class.kSecClassValue,
            kSecAttrApplicationTag: items.tag,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
        
        // Delete the item from Keychain
        let deletionStatus = SecItemDelete(query as CFDictionary)
        
        guard deletionStatus == errSecSuccess else {
            throw "Could not delete items. OS Status: " + deletionStatus.description
        }
    }
    
    /// Describes a Keychain item with its identifying attributes.
    public struct ItemDescription {
        public init(tag: Data,
                    `class`: ItemClass) {
            self.tag = tag
            self.`class` = `class`
        }
        
        public let tag: Data?
        public let `class`: ItemClass
    }
    
    /// Represents the different types of items that can be stored in the Keychain.
    public enum ItemClass {
        fileprivate var kSecClassValue: CFString {
            switch self {
            case .certificate: kSecClassCertificate
            case .genericPassword: kSecClassGenericPassword
            case .identity: kSecClassIdentity
            case .internetPassword: kSecClassInternetPassword
            case .key: kSecClassKey
            }
        }
        
        case key, genericPassword, internetPassword, certificate, identity
    }
}
