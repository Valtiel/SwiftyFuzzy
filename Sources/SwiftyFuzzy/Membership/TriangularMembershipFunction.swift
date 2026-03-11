import Foundation

/// Triangular membership function: zero at `a` and `c`, peak 1 at `b` (must satisfy a ≤ b ≤ c).
public struct TriangularMembershipFunction: MembershipFunction, Sendable {
    private let leftZero: Double   // a
    private let peak: Double       // b
    private let rightZero: Double  // c

    /// - Parameters:
    ///   - a: Left x where μ = 0.
    ///   - b: Center x where μ = 1 (peak). Must satisfy `a ≤ b ≤ c`.
    ///   - c: Right x where μ = 0.
    /// - Throws: `InvalidMembershipFunctionError` if parameters are non-finite or if a ≤ b ≤ c does not hold.
    public init(a: Double, b: Double, c: Double) throws {
        guard a.isFinite, b.isFinite, c.isFinite else {
            throw InvalidMembershipFunctionError(reason: "All parameters must be finite")
        }
        guard a <= b, b <= c else {
            throw InvalidMembershipFunctionError(reason: "Parameters must satisfy a ≤ b ≤ c")
        }
        self.leftZero = a
        self.peak = b
        self.rightZero = c
    }

    /// Peak at (a + c) / 2.
    public init(a: Double, c: Double) throws {
        try self.init(a: a, b: (a + c) / 2, c: c)
    }

    public func value(for input: Double) -> Double {
        if input >= leftZero && input <= peak {
            let denom = peak - leftZero
            return denom > 0 ? (input - leftZero) / denom : 1
        }
        if input >= peak && input <= rightZero {
            let denom = peak - rightZero
            return denom != 0 ? (input - rightZero) / denom : 1
        }
        return 0
    }

    public func clippedValue(for input: Double, clip: Double) -> Double {
        Swift.min(value(for: input), clip)
    }

    public var min: Double { leftZero }
    public var max: Double { rightZero }
}
