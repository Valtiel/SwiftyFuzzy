import Foundation

/// A fuzzy set: a named collection defined by a membership function, with mutable degree of membership (DOM).
///
/// After fuzzification, `degreeOfMembership` holds the membership value for the last crisp input.
public final class FuzzySet {
    public let label: String
    private let function: MembershipFunction
    public private(set) var degreeOfMembership: Double = 0

    public init(label: String, membershipFunction: MembershipFunction) {
        self.label = label
        self.function = membershipFunction
    }

    // MARK: - Membership evaluation

    /// Raw membership for the given input (does not update stored DOM).
    public func value(for input: Double) -> Double {
        function.value(for: input)
    }

    /// Dilation modifier: √μ(x).
    public func fairlyValue(for input: Double) -> Double {
        Modifier.fairly.apply(to: function.value(for: input))
    }

    /// Concentration modifier: μ(x)².
    public func veryValue(for input: Double) -> Double {
        Modifier.very.apply(to: function.value(for: input))
    }

    /// Computes and stores DOM for the given input; returns the stored value.
    @discardableResult
    public func calculateDOM(for input: Double) -> Double {
        degreeOfMembership = function.value(for: input)
        return degreeOfMembership
    }

    /// Clipped membership for defuzzification (min of raw value and clip).
    public func clippedValue(for input: Double, clip: Double) -> Double {
        function.clippedValue(for: input, clip: clip)
    }

    /// The underlying membership function (for variable bounds and defuzzification).
    public var membershipFunction: MembershipFunction { function }
}

// MARK: - FuzzyTerm

extension FuzzySet: FuzzyTerm {
    public func clearDOM() {
        degreeOfMembership = 0
    }

    public func orWithDOM(_ value: Double) {
        degreeOfMembership = max(degreeOfMembership, value)
    }
}

// MARK: - Equatable & CustomStringConvertible

extension FuzzySet: Equatable {
    public static func == (lhs: FuzzySet, rhs: FuzzySet) -> Bool {
        lhs.label.lowercased() == rhs.label.lowercased()
    }
}

extension FuzzySet: CustomStringConvertible {
    public var description: String { label }
}
