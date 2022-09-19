import Foundation

public struct StopWatch
{
    public init() { startTime = .uptimeNanoSeconds }
    
    public mutating func restart() { startTime = .uptimeNanoSeconds }
    
    public func measure(_ whatIsMeasured: String)
    {
        let durationNanoSeconds = UInt64.uptimeNanoSeconds - startTime
        
        if durationNanoSeconds > 1000000
        {
            print("⏱ " + whatIsMeasured + ": \(Double(durationNanoSeconds) / 1000000000.0) seconds")
        }
        else
        {
            print("⏱ " + whatIsMeasured + ": \(Double(durationNanoSeconds) / 1000000.0) mili seconds")
        }
    }
    
    private var startTime: UInt64
}
