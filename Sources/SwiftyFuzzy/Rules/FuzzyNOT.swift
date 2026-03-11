import Foundation

/// Fuzzy NOT: degree of membership is 1 minus the term's degree.
public final class FuzzyNOT: FuzzyTerm {
    private let term: FuzzyTerm

    public init(_ term: FuzzyTerm) {
        self.term = term
    }

    public var degreeOfMembership: Double {
        1 - term.degreeOfMembership
    }

    public func clearDOM() {
        term.clearDOM()
    }

    public func orWithDOM(_ value: Double) {
        term.orWithDOM(value)
    }
}
