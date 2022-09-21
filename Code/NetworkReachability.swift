import Foundation
import Network
import SwiftyToolz

public class NetworkReachability
{
    // MARK: - Initialization
    
    public static let shared = NetworkReachability()
    
    private init()
    {
        pathMonitor.pathUpdateHandler = notifyObserversWithNetworkPath
        pathMonitor.start(queue: DispatchQueue(label: "Network Reachability Monitor",
                                               qos: .default))
    }
    
    private func notifyObserversWithNetworkPath(_ networkPath: NWPath)
    {
        let update: Update =
        {
            guard networkPath.status == .satisfied else { return .noInternet }
            return networkPath.isExpensive ? .expensiveInternet : .fullInternet
        }()
        
        sendToObservers(update)
    }
    
    // MARK: - Primitive Observability
    
    public func add(observer: AnyObject, receive: @escaping (Update) -> Void)
    {
        observers.append(WeakObserver(observer: observer, receive: receive))
    }
    
    public func remove(observer: AnyObject)
    {
        observers.removeAll { $0.observer === observer }
    }
    
    private func sendToObservers(_ update: Update)
    {
        observers.removeAll { $0.observer == nil }
        observers.forEach { $0.receive(update) }
    }
    
    private var observers = [WeakObserver]()
    
    private struct WeakObserver
    {
        weak var observer: AnyObject?
        let receive: (Update) -> Void
    }
    
    public enum Update { case noInternet, expensiveInternet, fullInternet }
    
    private let pathMonitor = NWPathMonitor()
}
