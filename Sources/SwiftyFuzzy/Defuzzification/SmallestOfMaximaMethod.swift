import Foundation

/// Smallest of Maxima (SOM) defuzzification: returns the smallest x where aggregated membership is maximum.
///
/// The aggregated output at each x is the maximum (union) of each set's clipped membership. When the maximum
/// membership is zero, returns the variable minimum.
public struct SmallestOfMaximaMethod: DefuzzifierMethod, Sendable {
    /// Number of sample points (minimum 1).
    public var sampleCount: Int

    public init(sampleCount: Int = 100) {
        self.sampleCount = max(1, sampleCount)
    }

    public func defuzzifiedValue(for variable: LinguisticVariable) -> Double {
        let xAtMax = MeanOfMaximaMethod.xValuesAtMaximumMembership(variable: variable, sampleCount: sampleCount)
        return xAtMax.min() ?? variable.min
    }
}
