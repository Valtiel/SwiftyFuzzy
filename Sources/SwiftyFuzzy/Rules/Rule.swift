import Foundation

/// A fuzzy rule: IF antecedent THEN consequent (optionally weighted).
///
/// When the rule is fired, the consequent's degree of membership is updated using
/// fuzzy OR (max) with the antecedent's degree multiplied by the rule's weight.
/// Weight is typically in [0, 1]; the effective strength is clamped to [0, 1].
public final class Rule {
    private let antecedent: FuzzyTerm
    public let consequent: FuzzyTerm
    /// Rule weight; effective firing strength = min(1, max(0, antecedent DOM × weight)). Default 1.
    public let weight: Double

    public init(antecedent: FuzzyTerm, consequent: FuzzyTerm, weight: Double = 1) {
        self.antecedent = antecedent
        self.consequent = consequent
        self.weight = weight
    }

    /// Effective firing strength (antecedent DOM × weight, clamped to [0, 1]). Same value that would be applied to the consequent when firing. Use for debugging/tracing.
    public var effectiveFiringStrength: Double {
        min(1, max(0, antecedent.degreeOfMembership * weight))
    }

    /// Fires the rule: consequent DOM = max(consequent DOM, antecedent DOM × weight), clamped to [0, 1].
    public func calculate() {
        consequent.orWithDOM(effectiveFiringStrength)
    }
}
