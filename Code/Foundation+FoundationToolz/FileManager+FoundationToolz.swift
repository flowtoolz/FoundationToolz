import Foundation
import SwiftyToolz

public extension FileManager
{
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func ensureDirectoryExists(_ dir: URL) -> URL?
    {
        if itemExists(dir) { return dir }
        
        do
        {
            try createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func removeItems(in directory: URL?) -> Bool
    {
        remove(items(inDirectory: directory, recursive: false))
    }
    
    func items(inDirectory directory: URL?, recursive: Bool) -> [URL]
    {
        guard let directory else { return [] }
        
        var options: DirectoryEnumerationOptions =
        [
            .skipsHiddenFiles,
            .skipsPackageDescendants
        ]
        
        if !recursive
        {
            options.insert(.skipsSubdirectoryDescendants)
        }
        
        return enumerator(at: directory,
                          includingPropertiesForKeys: [.isDirectoryKey],
                          options: options,
                          errorHandler: nil)?.compactMap { $0 as? URL } ?? []
    }
    
    /**
     Removes items if they exist
     - Returns: `true` if all items were actually removed. `false` if at least one doesn't exist or an error occured.
     **/
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func remove(_ items: [URL]) -> Bool
    {
        items.reduce(true) { removedAll, item in removedAll && remove(item) }
    }
    
    /**
     Removes an item if it exists
     - Returns: `true` if the item actually was removed. `false` if it doesn't exist or some error occured.
     **/
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func remove(_ item: URL?) -> Bool
    {
        guard let item = item, itemExists(item) else { return false }
        
        do
        {
            try removeItem(at: item)
            return true
        }
        catch
        {
            log(error: error.localizedDescription)
            return false
        }
    }
    
    func itemExists(_ item: URL?) -> Bool
    {
        guard let item else { return false }
        return fileExists(atPath: item.path)
    }
}
