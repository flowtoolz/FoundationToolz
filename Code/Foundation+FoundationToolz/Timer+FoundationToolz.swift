import Foundation

public extension Timer {
    static func seconds(_ seconds: Int,
                        repeat: Bool = false,
                        action: @escaping @Sendable () -> Void) -> Timer {
        .scheduledTimer(withTimeInterval: TimeInterval(seconds),
                        repeats: `repeat`,
                        block: { _ in action() })
    }
}
