#if os(macOS)

import Foundation
import SwiftyToolz

/// This does not work in a sandboxed app!
open class Executable
{
    // MARK: - Life Cycle
    
    public init(config: Configuration) throws {
        guard FileManager.default.fileExists(atPath: config.path) else {
            throw "Executable does not exist at given path \(config.path)"
        }
        
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
                self?.didSendOutput(processOutput)
            }
        }
        
        process.standardOutput = outPipe
    }
    
    public var didSendOutput: (Data) -> Void = { _ in
        log(warning: "Executable did send output, but handler has not been set")
    }
    
    private let outPipe = Pipe()
    
    // MARK: - Input
    
    private func setupInput() {
        process.standardInput = inPipe
    }
    
    public func receive(input: Data) {
        guard isRunning else {
            log(error: "\(Self.self) cannot receive input while not running.")
            return
        }
        
        if input.isEmpty {
            log(warning: "\(Self.self) received empty input data.")
        }
        
        do {
            if #available(OSX 10.15.4, *) {
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
            if errorData.count > 0 { self?.didSendError(errorData) }
        }
        process.standardError = errorPipe
    }
    
    public var didSendError: (Data) -> Void = { _ in
        log(warning: "Executable did send error, but handler has not been set")
    }
    
    private let errorPipe = Pipe()
    
    // MARK: - Process
    
    private func setupProcess(with config: Configuration) throws {
        process.executableURL = URL(fileURLWithPath: config.path)
        
        let currentEnvironment = ProcessInfo.processInfo.environment
        process.environment = currentEnvironment.merging(config.environment) { $1 }
        
        process.arguments = config.arguments
        
        process.terminationHandler = { [weak self] process in
            log("\(Self.self) terminated. code: \(process.terminationReason.rawValue)")
            self?.didTerminate()
        }
    }
    
    public var didTerminate: () -> Void = {
        log(warning: "Executable did terminate, but handler has not been set")
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
    
    // MARK: - Configuration
    
    public struct Configuration: Codable {
        
        public init(path: String,
                    arguments: [String] = [],
                    environment: [String : String] = [:]) {
            self.path = path
            self.arguments = arguments
            self.environment = environment
        }
        
        public var path: String
        public var arguments: [String]
        public var environment: [String: String]
    }
}

#endif
