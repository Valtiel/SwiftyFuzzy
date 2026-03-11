import Foundation

/// Linguistic modifier applied to a fuzzy set's degree of membership (e.g. "very", "fairly").
public enum Modifier: Sendable {
    /// No modification; degree unchanged.
    case normal
    /// Concentration: μ² (narrows the set).
    case very
    /// Dilation: √μ (widens the set).
    case fairly

    /// Returns the modified degree of membership in `[0, 1]`.
    @inlinable
    public func apply(to degreeOfMembership: Double) -> Double {
        switch self {
        case .normal: return degreeOfMembership
        case .very: return degreeOfMembership * degreeOfMembership
        case .fairly: return sqrt(degreeOfMembership)
        }
    }
}
