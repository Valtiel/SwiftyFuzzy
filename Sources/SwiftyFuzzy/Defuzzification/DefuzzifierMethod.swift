import Foundation

/// A strategy that converts the aggregated output fuzzy set(s) of a linguistic variable into a single crisp value.
public protocol DefuzzifierMethod {
    /// Returns the defuzzified (crisp) value for the given variable after rules have been fired.
    func defuzzifiedValue(for variable: LinguisticVariable) -> Double
}
