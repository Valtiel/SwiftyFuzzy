import Foundation

/// Fuzzy OR: degree of membership is the maximum of all terms.
public final class FuzzyOR: FuzzyTerm {
    private let terms: [FuzzyTerm]

    public init(_ terms: FuzzyTerm...) {
        self.terms = terms
    }

    public init(terms: [FuzzyTerm]) {
        self.terms = terms
    }

    public var degreeOfMembership: Double {
        terms.map(\.degreeOfMembership).max() ?? 0
    }

    public func clearDOM() {
        terms.forEach { $0.clearDOM() }
    }

    public func orWithDOM(_ value: Double) {
        terms.forEach { $0.orWithDOM(value) }
    }
}
