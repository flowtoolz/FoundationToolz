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
        
        output.fileHandleForReading.readabilityHandler =
        {
            output in outputData += output.availableData
        }
        
        try run()
        waitUntilExit()
        
        return String(data: outputData, encoding: .utf8)!
    }
}

#endif
