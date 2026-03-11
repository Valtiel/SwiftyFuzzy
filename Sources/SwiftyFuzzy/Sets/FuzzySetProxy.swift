import Foundation

/// A reference to a `FuzzySet` for use in rules, with an optional linguistic modifier (e.g. "very", "fairly").
///
/// Use the `FuzzySetProxy` returned by `LinguisticVariable.addSet(_:membershipFunction:)` when building rules.
/// Call `.very()` or `.fairly()` to apply a modifier to the set's degree of membership.
public final class FuzzySetProxy: FuzzyTerm {
    private let set: FuzzySet
    private let modifier: Modifier

    public init(set: FuzzySet, modifier: Modifier = .normal) {
        self.set = set
        self.modifier = modifier
    }

    public var degreeOfMembership: Double {
        modifier.apply(to: set.degreeOfMembership)
    }

    public func clearDOM() {
        set.clearDOM()
    }

    public func orWithDOM(_ value: Double) {
        set.orWithDOM(value)
    }

    /// Returns a new reference with the "fairly" (dilation √μ) modifier.
    public func fairly() -> FuzzySetProxy {
        FuzzySetProxy(set: set, modifier: .fairly)
    }

    /// Returns a new reference with the "very" (concentration μ²) modifier.
    public func very() -> FuzzySetProxy {
        FuzzySetProxy(set: set, modifier: .very)
    }
}

/// Backward-compatible alias.
@available(*, deprecated, renamed: "FuzzySetProxy")
public typealias FzSet = FuzzySetProxy
