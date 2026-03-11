import Foundation

/// Gaussian (bell) membership function: μ(x) = exp(-(x - mean)² / (2σ²)), peak 1 at mean.
///
/// Bounds for defuzzification sampling are mean ± 3σ (covers ~99.7% of the bell).
public struct GaussianMembershipFunction: MembershipFunction, Sendable {
    private let mean: Double
    private let sigma: Double
    private let minX: Double
    private let maxX: Double

    /// - Parameters:
    ///   - mean: Center of the bell (μ = 1).
    ///   - sigma: Standard deviation; must be finite and positive.
    /// - Throws: `InvalidMembershipFunctionError` if sigma is not finite or not positive.
    public init(mean: Double, sigma: Double) throws {
        guard sigma.isFinite, sigma > 0 else {
            throw InvalidMembershipFunctionError(reason: "sigma must be finite and positive")
        }
        guard mean.isFinite else {
            throw InvalidMembershipFunctionError(reason: "mean must be finite")
        }
        self.mean = mean
        self.sigma = sigma
        self.minX = mean - 3 * sigma
        self.maxX = mean + 3 * sigma
    }

    public func value(for input: Double) -> Double {
        let z = (input - mean) / sigma
        return exp(-0.5 * z * z)
    }

    public func clippedValue(for input: Double, clip: Double) -> Double {
        Swift.min(value(for: input), clip)
    }

    public var min: Double { minX }
    public var max: Double { maxX }
}
