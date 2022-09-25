import Foundation
import SwiftyToolz

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
public extension URL
{
    func webSocket() throws -> WebSocket
    {
        try WebSocket(self)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
public class WebSocket
{
    // MARK: - Life Cycle
    
    init(_ url: URL) throws
    {
        self.url = try url.with(scheme: .ws)
        webSocketTask = URLSession.shared.webSocketTask(with: self.url)
        webSocketTask.resume()
        receiveNextMessage()
    }
    
    deinit
    {
        if webSocketTask.state == .suspended || webSocketTask.state == .running
        {
            didCloseWithError(self, "WebSocket is being deinitialized while still suspended or running")
        }
    }
    
    // MARK: - Receiving Messages
    
    private func receiveNextMessage()
    {
        webSocketTask.receive
        {
            [weak self] result in self?.didReceive(result)
        }
    }
    
    private func didReceive(_ result: Result<URLSessionWebSocketTask.Message, Error>)
    {
        switch result
        {
        case .success(let message):
            switch message
            {
            case .data(let data): didReceiveData(data)
            case .string(let text): didReceiveText(text)
            default: log(error: "Unknown type of WebSocket message")
            }
            
            receiveNextMessage()
        case .failure(let error):
            didCloseWithError(self, error)
        }
    }
    
    public var didReceiveData: (Data) -> Void =
    {
        _ in log(warning: "Data handler not set")
    }
    
    public var didReceiveText: (String) -> Void =
    {
        _ in log(warning: "Text handler not set")
    }
    
    public var didCloseWithError: (WebSocket, Error) -> Void =
    {
        _, _ in log(warning: "Error handler not set")
    }
    
    // MARK: - Sending Messages
    
    public func send(_ data: Data) async throws
    {
        try await webSocketTask.send(.data(data))
    }
    
    public func send(_ text: String) async throws
    {
        try await webSocketTask.send(.string(text))
    }
    
    // MARK: - WebSocket Task
    
    public let url: URL
    private let webSocketTask: URLSessionWebSocketTask
}

public extension URL
{
    func with(scheme newScheme: Scheme) throws -> URL
    {
        if scheme == newScheme.rawValue { return self }
        
        guard var newComponents = URLComponents(url: self,
                                                resolvingAgainstBaseURL: true) else
        {
            throw "Couldn't detect components of URL: \(absoluteString)"
        }
        
        newComponents.scheme = newScheme.rawValue
        
        guard let newURL = newComponents.url else
        {
            throw "Couldn't create url from: \(newComponents)"
        }
        
        return newURL
    }
    
    enum Scheme: String
    {
        case http, https, ws, wss, ftp, file
    }
}
