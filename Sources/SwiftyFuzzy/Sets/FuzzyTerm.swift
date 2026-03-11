import Foundation

/// A fuzzy term in the composite pattern; used as building blocks for rule antecedents and consequents.
///
/// Antecedents and consequents are typically `FzSet` (optionally wrapped with `FuzzyAND`/`FuzzyOR`/`FuzzyNOT`).
/// The controller evaluates antecedents to obtain a degree of membership, then applies that to consequents via OR (max).
public protocol FuzzyTerm: AnyObject {
    /// Current degree of membership in [0, 1].
    var degreeOfMembership: Double { get }

    /// Resets the stored degree of membership to zero (used before re-evaluating rules).
    func clearDOM()

    /// Combines the current degree with `value` using fuzzy OR (max) and stores the result.
    func orWithDOM(_ value: Double)
}
