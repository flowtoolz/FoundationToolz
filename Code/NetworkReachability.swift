import Foundation
import Network
import SwiftyToolz

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor NetworkReachability
{
    // MARK: - Initialization
    
    public static let shared = NetworkReachability()
    
    private init()
    {
        pathMonitor.pathUpdateHandler = {
            [weak self] networkPath in
            
            let update: Update =
            {
                guard networkPath.status == .satisfied else { return .noInternet }
                return networkPath.isExpensive ? .expensiveInternet : .fullInternet
            }()
            
            Task { [weak self] in
                await self?.sendToObservers(update)
            }
        }
        
        pathMonitor.start(queue: DispatchQueue(label: "Network Reachability Monitor",
                                               qos: .default))
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
    
    public enum Update: Sendable { case noInternet, expensiveInternet, fullInternet }
    
    private let pathMonitor = NWPathMonitor()
}
