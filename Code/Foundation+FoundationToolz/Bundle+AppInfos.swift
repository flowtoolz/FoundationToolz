import Foundation
import SwiftyToolz

public extension Bundle
{
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func debugLogInfos()
    {
        guard let infoDictionary else
        {
            log(error: "Bundle \(bundleURL.lastPathComponent) has no infoDictionary")
            return
        }
        
        do
        {
            log("Main Bundle:\n" + (try infoDictionary.prettyPrinted))
        }
        catch
        {
            log(error: error.localizedDescription)
        }
    }
    
    var iconName: String?
    {
        infoDictionary?["CFBundleIconName"] as? String
    }
    
    var name: String?
    {
        infoDictionary?[String(kCFBundleNameKey)] as? String
    }
    
    var version: String?
    {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildNumber: String?
    {
        infoDictionary?[String(kCFBundleVersionKey)] as? String
    }
    
    var copyright: String?
    {
        infoDictionary?["NSHumanReadableCopyright"] as? String
    }
}
