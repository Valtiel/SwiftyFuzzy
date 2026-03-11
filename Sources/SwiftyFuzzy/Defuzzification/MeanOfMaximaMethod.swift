import Foundation

/// Mean of Maxima (MOM) defuzzification: finds the x values where aggregated membership is maximum, then returns their mean.
///
/// The aggregated output at each x is the maximum (union) of each set's clipped membership. When the maximum
/// membership is zero, returns the midpoint of the variable range.
public struct MeanOfMaximaMethod: DefuzzifierMethod, Sendable {
    /// Number of sample points (minimum 1). Higher values improve accuracy for locating the plateau.
    public var sampleCount: Int

    public init(sampleCount: Int = 100) {
        self.sampleCount = max(1, sampleCount)
    }

    public func defuzzifiedValue(for variable: LinguisticVariable) -> Double {
        let xAtMax = Self.xValuesAtMaximumMembership(variable: variable, sampleCount: sampleCount)
        guard !xAtMax.isEmpty else { return (variable.min + variable.max) / 2 }
        return xAtMax.reduce(0, +) / Double(xAtMax.count)
    }

    /// Aggregated membership at x = max over sets of clippedValue(x); returns x values where μ equals the global max.
    static func xValuesAtMaximumMembership(variable: LinguisticVariable, sampleCount: Int) -> [Double] {
        let sets = variable.sets
        let minX = variable.min
        let maxX = variable.max
        guard maxX > minX, sampleCount > 0 else { return [] }

        let steps = max(1, sampleCount - 1)
        let step = (maxX - minX) / Double(steps)
        var maxMembership: Double = 0
        var xAtMax: [Double] = []

        for i in 0..<sampleCount {
            let x = minX + Double(i) * step
            let μ = sets.map { $0.clippedValue(for: x, clip: $0.degreeOfMembership) }.max() ?? 0
            if μ >= maxMembership {
                if μ > maxMembership {
                    maxMembership = μ
                    xAtMax = [x]
                } else {
                    xAtMax.append(x)
                }
            }
        }
        return xAtMax
    }
}
