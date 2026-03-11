import Foundation

/// Trapezoidal membership: ramps from a→b and c→d, flat 1 between b and c. Supports infinite bounds for open-ended sets.
public struct TrapezoidalMembershipFunction: MembershipFunction, Sendable {
    private let a: Double
    private let b: Double
    private let c: Double
    private let d: Double

    /// - Parameters:
    ///   - a: Left foot (start of ramp up). May be `-.infinity` for left-open sets.
    ///   - b: Left shoulder (end of ramp up). Must satisfy `a ≤ b`.
    ///   - c: Right shoulder (start of ramp down). Must satisfy `b ≤ c`.
    ///   - d: Right foot (end of ramp down). May be `.infinity` for right-open sets. Must satisfy `c ≤ d`.
    /// - Throws: `InvalidMembershipFunctionError` if the ordering `a ≤ b ≤ c ≤ d` is violated.
    public init(a: Double, b: Double, c: Double, d: Double) throws {
        guard a <= b, b <= c, c <= d else {
            throw InvalidMembershipFunctionError(reason: "Parameters must satisfy a ≤ b ≤ c ≤ d")
        }
        self.a = a
        self.b = b
        self.c = c
        self.d = d
    }

    /// Left- or right-sided trapezoid: if `right` is true, d = c (flat from c onward); else a = b (flat up to b, then ramp down).
    /// - Throws: `InvalidMembershipFunctionError` if the resulting ordering `a ≤ b ≤ c ≤ d` is violated.
    public init(a: Double, b: Double, c: Double, right: Bool) throws {
        if right {
            try self.init(a: a, b: b, c: c, d: c)
        } else {
            try self.init(a: a, b: a, c: b, d: c)
        }
    }

    public func value(for input: Double) -> Double {
        if a == -.infinity && input <= b { return 1 }
        if a.isFinite, b.isFinite, input >= a, input <= b {
            return (b - a) > 0 ? (input - a) / (b - a) : 1
        }
        if input >= b && input <= c { return 1 }
        if d.isInfinite && input >= c { return 1 }
        if c.isFinite, d.isFinite, input >= c, input <= d {
            return (c - d) != 0 ? (input - d) / (c - d) : 1
        }
        return 0
    }

    public func clippedValue(for input: Double, clip: Double) -> Double {
        Swift.min(value(for: input), clip)
    }

    public var max: Double {
        if d.isInfinite {
            if c.isInfinite { return b.isInfinite ? a : b }
            return c
        }
        return d
    }

    public var min: Double {
        if a.isInfinite {
            if b.isInfinite { return c.isInfinite ? d : c }
            return b
        }
        return a
    }
}
