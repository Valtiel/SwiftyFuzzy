import Foundation

/// A function that maps a crisp input to a membership degree in the range [0, 1].
///
/// Used by fuzzy sets to define how much an input belongs to the set.
/// Implementations must provide finite `min` and `max` for defuzzification sampling.
public protocol MembershipFunction: Sendable {
    /// Returns the membership degree for the given input, in [0, 1].
    func value(for input: Double) -> Double

    /// Returns the membership degree capped at `clip` (used when building the output shape for defuzzification).
    func clippedValue(for input: Double, clip: Double) -> Double

    /// Minimum finite x used by this function (for sampling bounds).
    var min: Double { get }

    /// Maximum finite x used by this function (for sampling bounds).
    var max: Double { get }
}

// MARK: - Default implementation

extension MembershipFunction {
    /// Default: minimum of raw value and clip.
    public func clippedValue(for input: Double, clip: Double) -> Double {
        Swift.min(value(for: input), clip)
    }
}
