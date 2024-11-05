import Foundation
import SwiftyToolz

// TODO: check where this extension is used and dissolve it, it's unnecessary. use directly HTTP instead.
@available(macOS 10.15, iOS 13.0, *)
public extension URL
{
    /**
     Get request returning the server response as JSON encodable type `Value`
     
     This only works when the server returns a valid JSON encoding of `Value`! It might not work for example when the server returns a pure unencoded String. In that case, use `func get() async throws -> Data` instead!
    **/
    func get<Value: Decodable>(_ type: Value.Type = Value.self) async throws(HTTP.RequestError) -> Value
    {
        try await HTTP.sendRequest(to: self)
    }
    
    /// Get request returning the pure data that the server sends in response
    func get() async throws(HTTP.RequestError) -> Data
    {
        try await HTTP.sendRequest(to: self).0
    }
    
    func post<Value: Encodable>(_ value: Value) async throws
    {
        try await _ = HTTP.sendRequest(to: self, using: .POST, content: value)
    }
}
