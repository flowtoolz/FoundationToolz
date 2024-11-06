import Foundation
import SwiftyToolz

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URL
{
    func webSocket(processor: WebSocketProcessor) throws -> WebSocket
    {
        try WebSocket(self, processor: processor)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class WebSocket: Sendable
{
    // MARK: - Life Cycle
    
    init(_ url: URL, processor: WebSocketProcessor) throws
    {
        self.url = try url.with(scheme: .ws)
        self.processor = processor
        
        webSocketTask = URLSession.shared.webSocketTask(with: self.url)
        webSocketTask.resume()
        receiveNextMessage()
    }
    
    deinit
    {
        if webSocketTask.state == .suspended || webSocketTask.state == .running
        {
            processor.didCloseWithError(webSocket: self,
                                        error: "WebSocket is being deinitialized while still suspended or running")
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
            case .data(let data): processor.didReceive(data: data)
            case .string(let text): processor.didReceive(text: text)
            default: log(error: "Unknown type of WebSocket message")
            }
            
            receiveNextMessage()
        case .failure(let error):
            processor.didCloseWithError(webSocket: self, error: error)
        }
    }
    
    private let processor: WebSocketProcessor
    
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

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol WebSocketProcessor: Sendable {
    func didReceive(data: Data)
    func didReceive(text: String)
    func didCloseWithError(webSocket: WebSocket, error: Error)
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
