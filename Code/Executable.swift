#if os(macOS)

import Foundation
import SwiftyToolz

/// This does not work in a sandboxed app!
@available(macOS 10.15, *)
public final class Executable: Sendable
{
    // MARK: - Life Cycle
    
    public init(config: Configuration,
                processor: ExecutableProcessor) throws {
        guard FileManager.default.fileExists(atPath: config.command) else {
            throw "Executable does not exist at given path \(config.command)"
        }
        
        self.processor = processor
        
        try setupProcess(with: config)
        setupInput()
        setupOutput()
        setupErrorOutput()
    }
    
    deinit { if isRunning { stop() } }
    
    // MARK: - Output
    
    private func setupOutput() {
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] outHandle in
            let processOutput = outHandle.availableData
            if processOutput.count > 0 {
                self?.processor.didSend(output: processOutput)
            }
        }
        
        process.standardOutput = outPipe
    }
    
    private let outPipe = Pipe()
    
    // MARK: - Input
    
    private func setupInput() {
        process.standardInput = inPipe
    }
    
    @available(macOS 10.15, *)
    public func receive(input: Data) {
        guard isRunning else {
            log(error: "\(Self.self) cannot receive input while not running.")
            return
        }
        
        if input.isEmpty {
            log(warning: "\(Self.self) received empty input data.")
        }
        
        do {
            if #available(macOS 10.15.4, *) {
                try inPipe.fileHandleForWriting.write(contentsOf: input)
            } else {
                inPipe.fileHandleForWriting.write(input)
            }
        } catch { log(error.readable) }
    }
    
    private let inPipe = Pipe()
    
    // MARK: - Error Output
    
    private func setupErrorOutput() {
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] errorHandle in
            let errorData = errorHandle.availableData
            if errorData.count > 0 { self?.processor.didSend(error: errorData) }
        }
        process.standardError = errorPipe
    }
    
    private let errorPipe = Pipe()
    
    // MARK: - Process
    
    private func setupProcess(with config: Configuration) throws {
        // use a regular shell session, so we can add paths to PATH before running the command
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        // give the command and its arguments as arguments to the Z-Shell, add 2 paths to the environment
        let commandArgumentList = config.arguments.joined(separator: " ")
        
        let additionalPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin"
        ]
        
        // alternatively we could "source ~/.zprofile; source ~/.zshrc;" or maybe add the "-i" argument to process arguments to start an interactive shell which might get all the usual environment variables by sourcing .zshrc etc.
        let addAdditionalPathsCommand = "PATH=$PATH:\(additionalPaths.joined(separator: ":"));"
        
        process.arguments = [
            "-c",
            "\(addAdditionalPathsCommand) \(config.command) \(commandArgumentList)"
        ]
        
        // Our basic environment is the one of the current process extended by the given custom one
        let currentEnvironment = ProcessInfo.processInfo.environment
        process.environment = currentEnvironment.merging(config.environment) { $1 }
        
        // call the client's termination handler when the process terminates
        process.terminationHandler = { [weak self] process in
            log("\(Self.self) terminated. code: \(process.terminationReason.rawValue)")
            self?.processor.didTerminate()
        }
    }
    
    public func run() throws {
        guard process.executableURL != nil else {
            throw "\(Self.self) has no valid executable set"
        }
        
        guard !isRunning else {
            log(warning: "\(Self.self) is already running.")
            return
        }
        
        try process.run()
    }
    
    public func stop() {
        if process.isRunning { process.terminate() }
    }
    
    public var isRunning: Bool { process.isRunning }
    
    public let process = Process()
    
    private let processor: ExecutableProcessor
    
    // MARK: - Configuration
    
    public struct Configuration: Codable {
        
        public init(path: String,
                    arguments: [String] = [],
                    environment: [String : String] = [:]) {
            self.command = path
            self.arguments = arguments
            self.environment = environment
        }
        
        public var command: String
        public var arguments: [String]
        public var environment: [String: String]
    }
}

public protocol ExecutableProcessor: Sendable {
    func didSend(output: Data)
    func didSend(error: Data)
    func didTerminate()
}

#endif
