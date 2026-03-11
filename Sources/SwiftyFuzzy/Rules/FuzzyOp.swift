import Foundation

/// Fuzzy logic operators for scalars and for composing fuzzy terms in rules.
public enum FuzzyOp {
    // MARK: - Scalar (for manual use)

    @inlinable public static func and(_ a: Double, _ b: Double) -> Double { min(a, b) }
    @inlinable public static func or(_ a: Double, _ b: Double) -> Double { max(a, b) }
    @inlinable public static func not(_ a: Double) -> Double { 1 - a }

    // MARK: - Term composition (for rule antecedents)

    /// Fuzzy AND: minimum of the terms' degrees of membership.
    public static func and(_ lhs: FuzzyTerm, _ rhs: FuzzyTerm) -> FuzzyTerm {
        FuzzyAND(lhs, rhs)
    }

    /// Fuzzy OR: maximum of the terms' degrees of membership.
    public static func or(_ lhs: FuzzyTerm, _ rhs: FuzzyTerm) -> FuzzyTerm {
        FuzzyOR(lhs, rhs)
    }

    /// Fuzzy NOT: 1 minus the term's degree of membership.
    public static func not(_ term: FuzzyTerm) -> FuzzyTerm {
        FuzzyNOT(term)
    }
}
