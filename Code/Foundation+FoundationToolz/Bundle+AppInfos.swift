import Foundation
import SwiftyToolz

public extension Bundle
{
    func debugLogInfos()
    {
        if let infoDictionary
        {
            log(infoDictionary.debugDescription)
        }
        else
        {
            log(error: "Bundle \(bundleURL.lastPathComponent) has no infoDictionary")
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
