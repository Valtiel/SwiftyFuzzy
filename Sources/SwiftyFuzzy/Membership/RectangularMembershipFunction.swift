import Foundation

/// Rectangular (flat) membership: constant height in [a, b], zero elsewhere.
public struct RectangularMembershipFunction: MembershipFunction, Sendable {
    private let a: Double
    private let b: Double
    private let height: Double

    /// - Parameters:
    ///   - a: Left boundary. Must satisfy `a < b`.
    ///   - b: Right boundary.
    ///   - y: Height in (0, 1]; default 1.
    /// - Throws: `InvalidMembershipFunctionError` if `y` is not in (0, 1] or `a >= b`.
    public init(a: Double, b: Double, y: Double = 1) throws {
        guard y > 0, y <= 1 else {
            throw InvalidMembershipFunctionError(reason: "Height y must be in (0, 1]")
        }
        guard a < b else {
            throw InvalidMembershipFunctionError(reason: "Bounds must satisfy a < b")
        }
        self.a = a
        self.b = b
        self.height = y
    }

    public func value(for input: Double) -> Double {
        (input >= a && input <= b) ? height : 0
    }

    public func clippedValue(for input: Double, clip: Double) -> Double {
        if input >= a && input <= b {
            return Swift.min(height, clip)
        }
        return 0
    }

    public var min: Double { a }
    public var max: Double { b }
}
