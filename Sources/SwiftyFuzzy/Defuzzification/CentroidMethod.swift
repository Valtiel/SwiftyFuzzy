import Foundation

/// Centroid (center of gravity) defuzzification: samples the aggregated output membership over [min, max] and returns the weighted average.
///
/// The aggregated output at each x is the maximum (union) of each set's clipped membership, consistent with the other defuzzification methods.
public struct CentroidMethod: DefuzzifierMethod, Sendable {
    /// Number of sample points (minimum 1).
    public var sampleCount: Int

    public init(sampleCount: Int = 10) {
        self.sampleCount = max(1, sampleCount)
    }

    public func defuzzifiedValue(for variable: LinguisticVariable) -> Double {
        let sets = variable.sets
        let minX = variable.min
        let maxX = variable.max

        guard maxX > minX else { return minX }

        let steps = max(1, sampleCount - 1)
        let step = (maxX - minX) / Double(steps)
        var sumWeighted: Double = 0
        var sumMembership: Double = 0

        for i in 0..<sampleCount {
            let x = minX + Double(i) * step
            let μ = sets.map { $0.clippedValue(for: x, clip: $0.degreeOfMembership) }.max() ?? 0
            sumWeighted += x * μ
            sumMembership += μ
        }

        guard sumMembership > 0 else { return (minX + maxX) / 2 }
        return sumWeighted / sumMembership
    }
}
