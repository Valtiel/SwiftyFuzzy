import Foundation

/// A linguistic variable: a named quantity with multiple fuzzy sets (e.g. "Temperature" with sets "cold", "warm", "hot").
///
/// Labels are compared case-insensitively. Use the `FzSet` returned by `addSet` when building rules.
public final class LinguisticVariable {
    public let label: String
    private var fuzzySets: [FuzzySet] = []

    public init(label: String) {
        self.label = label
    }

    // MARK: - Sets

    /// Adds a fuzzy set and returns a `FuzzySetProxy` reference for use in rules.
    /// - Throws: `DuplicateSetLabelError` if a set with the same label already exists.
    @discardableResult
    public func addSet(_ setLabel: String, membershipFunction: MembershipFunction) throws -> FuzzySetProxy {
        let set = FuzzySet(label: setLabel, membershipFunction: membershipFunction)
        if fuzzySets.contains(where: { $0.label.isEqualCaseInsensitive(to: setLabel) }) {
            throw DuplicateSetLabelError(label: setLabel)
        }
        fuzzySets.append(set)
        return FuzzySetProxy(set: set)
    }

    /// Adds an existing fuzzy set and returns a `FuzzySetProxy` reference for rules.
    /// - Throws: `DuplicateSetLabelError` if a set with the same label already exists.
    @discardableResult
    public func addSet(_ set: FuzzySet) throws -> FuzzySetProxy {
        if fuzzySets.contains(where: { $0.label.isEqualCaseInsensitive(to: set.label) }) {
            throw DuplicateSetLabelError(label: set.label)
        }
        fuzzySets.append(set)
        return FuzzySetProxy(set: set)
    }

    /// Removes the set with the given label. Returns `true` if a set was removed.
    @discardableResult
    public func removeSet(label: String) -> Bool {
        guard let index = fuzzySets.firstIndex(where: { $0.label.isEqualCaseInsensitive(to: label) }) else {
            return false
        }
        fuzzySets.remove(at: index)
        return true
    }

    /// The fuzzy sets in this variable (read-only).
    public var sets: [FuzzySet] { fuzzySets }

    /// **Deprecated:** Use `sets` instead.
    @available(*, deprecated, renamed: "sets")
    public var setList: [FuzzySet] { fuzzySets }

    // MARK: - Fuzzification

    /// Updates each set's degree of membership for the given crisp input.
    public func fuzzify(input: Double) {
        fuzzySets.forEach { $0.calculateDOM(for: input) }
    }

    /// Label of the set with the highest current degree of membership.
    public var bestLabel: String {
        fuzzySets.max(by: { $0.degreeOfMembership < $1.degreeOfMembership })?.label ?? ""
    }

    /// Current degree of membership for each set (set label → DOM). Useful for debugging after `fuzzify` or after rules have fired.
    public var currentDegreesOfMembership: [String: Double] {
        Dictionary(uniqueKeysWithValues: fuzzySets.map { ($0.label, $0.degreeOfMembership) })
    }

    /// For a given input, returns the label of the set with the highest raw membership (ignores stored DOM).
    public func bestFuzzyValue(for input: Double) -> String {
        fuzzySets.max(by: { $0.value(for: input) < $1.value(for: input) })?.label ?? ""
    }

    /// Membership values for each set label at the given input (no modifiers).
    public func normalValues(for input: Double) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: fuzzySets.map { ($0.label, $0.value(for: input)) })
    }

    /// Membership values with "fairly" (√μ) modifier.
    public func fairlyValues(for input: Double) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: fuzzySets.map { ($0.label, $0.fairlyValue(for: input)) })
    }

    /// Membership values with "very" (μ²) modifier.
    public func veryValues(for input: Double) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: fuzzySets.map { ($0.label, $0.veryValue(for: input)) })
    }

    // MARK: - Bounds (for defuzzification)

    /// Minimum finite x across all sets.
    public var min: Double {
        fuzzySets.map(\.membershipFunction.min).filter { $0.isFinite }.min() ?? 0
    }

    /// Maximum finite x across all sets.
    public var max: Double {
        fuzzySets.map(\.membershipFunction.max).filter { $0.isFinite }.max() ?? 0
    }
}

// MARK: - Private helpers

private extension String {
    func isEqualCaseInsensitive(to other: String) -> Bool {
        lowercased() == other.lowercased()
    }
}
