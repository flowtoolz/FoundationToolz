import Foundation
import SwiftyToolz

extension LSP.ServerConnection
{
    // TODO: use PromiseKit to make these simple mappings easier
    public func request<Value: Decodable>(_ req: LSP.Message.Request,
                                          as type: Value.Type,
                                          handleResult: @escaping (Result<Value, ResponseError>) -> Void) throws
    {
        try request(req)
        {
            result in
            
            switch result
            {
            case .success(let valueJSON):
                do
                {
                    handleResult(.success(try valueJSON.decode()))
                }
                catch
                {
                    let errorMessage = "Failed to decode result as \(Value.self)"
                    handleResult(.failure(.init(code: -32603,
                                                message: errorMessage,
                                                data: valueJSON)))
                }
            case .failure(let error):
                handleResult(.failure(error))
            }
        }
    }
}

extension LSP
{
    public class ServerConnection
    {
        // MARK: - Initialize
        
        public init(synchronousConnection connection: SynchronousLSPServerConnection)
        {
            self.connection = connection
            
            connection.serverDidSendResponse =
            {
                [weak self] response in self?.serverDidSend(response)
            }
            
            connection.serverDidSendNotification =
            {
                [weak self] notification in self?.serverDidSendNotification(notification)
            }
            
            connection.serverDidSendErrorOutput =
            {
                [weak self] errorOutput in self?.serverDidSendErrorOutput(errorOutput)
            }
        }
        
        // MARK: - Request and Response
        
        public func request(_ request: Message.Request,
                            handleResult: @escaping ResultHandler) throws
        {
            save(handleResult, for: request.id)
            
            do
            {
                try connection.send(.request(request))
            }
            catch
            {
                removeResultHandler(for: request.id)
                throw error
            }
        }
        
        private func serverDidSend(_ response: Message.Response)
        {
            switch response.id
            {
            case .value(let id):
                guard let handleResult = resultHandler(for: id) else
                {
                    log(error: "No result handler found")
                    break
                }
                handleResult(response.result)
            case .null:
                switch response.result
                {
                case .success(let result):
                    log(error: "Did receive result without request ID: \(result)")
                case .failure(let error):
                    serverDidSendError(error)
                }
            }
        }
        
        public var serverDidSendError: (ResponseError) -> Void = { _ in }
        
        // MARK: - Result Handlers
        
        private func save(_ resultHandler: @escaping ResultHandler, for id: Message.ID)
        {
            switch id
            {
            case .string(let idString):
                resultHandlersString[idString] = resultHandler
            case .int(let idInt):
                resultHandlersInt[idInt] = resultHandler
            }
        }
        
        private func removeResultHandler(for id: Message.ID)
        {
            switch id
            {
            case .string(let idString):
                resultHandlersString[idString] = nil
            case .int(let idInt):
                resultHandlersInt[idInt] = nil
            }
        }
        
        private func resultHandler(for id: Message.ID) -> ResultHandler?
        {
            switch id
            {
            case .string(let idString):
                return resultHandlersString[idString]
            case .int(let idInt):
                return resultHandlersInt[idInt]
            }
        }
        
        private var resultHandlersInt = [RequestIDInt: ResultHandler]()
        private typealias RequestIDInt = Int
        
        private var resultHandlersString = [RequestIDString: ResultHandler]()
        private typealias RequestIDString = String
        
        public typealias ResultHandler = (Result<JSON, ResponseError>) -> Void
        public typealias ResponseError = Message.Response.Error
        
        // MARK: - Forward to Connection
        
        public func notify(_ notification: Message.Notification) throws
        {
            try connection.send(.notification(notification))
        }
        
        public var serverDidSendNotification: (Message.Notification) -> Void = { _ in }
        public var serverDidSendErrorOutput: (String) -> Void = { _ in }
        
        private let connection: SynchronousLSPServerConnection
    }
}
