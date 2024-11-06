#if os(macOS)

import Foundation

extension Process
{
    func runExecutable(at filePath: String, arguments: [String]) throws -> String
    {
        let input = Pipe()
        let output = Pipe()
        
        executableURL = URL(fileURLWithPath: filePath)
        standardInput = input
        standardOutput = output
        environment = nil
        self.arguments = arguments
        
        var outputData = Data()
        let semaphore = DispatchSemaphore(value: 0)
        
        output.fileHandleForReading.readabilityHandler =
        {
            outputPipe in
            let data = outputPipe.availableData
            if data.count > 0 {
                // Append data to outputData in a thread-safe manner
                DispatchQueue.main.sync {
                    outputData.append(data)
                }
            } else {
                semaphore.signal() // Signal when there's no more data
            }
        }
        
        try run()
        
        // Wait for the process to finish
        waitUntilExit()
        
        // Wait for the readability handler to finish reading all data
        semaphore.wait()
        
        // Ensure the readability handler is removed to prevent retain cycles
        output.fileHandleForReading.readabilityHandler = nil
        
        return String(data: outputData, encoding: .utf8) ?? ""
    }
}

#endif
