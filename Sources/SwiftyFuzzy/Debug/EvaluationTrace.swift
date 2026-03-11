import Foundation

/// Snapshot of a single evaluation run, for debugging and inspection.
///
/// Populated by `BasicFuzzyController` after `evaluate(inputs:outputLabels:)` (and thus after `evaluate(inputs:)`).
/// Read `controller.lastEvaluation` to inspect inputs, per-variable degrees of membership, rule firing strengths, and outputs.
public struct EvaluationTrace: Sendable {
    /// Crisp input values (variable label → value).
    public let inputs: [String: Double]

    /// For each input variable label, the degree of membership of each of its sets after fuzzification (set label → DOM).
    public let inputVariableDegrees: [String: [String: Double]]

    /// For each rule index (order added), the firing strength applied to its consequent (antecedent DOM × weight, clamped to [0, 1]).
    public let ruleFiringStrengths: [Double]

    /// For each output variable label, the degree of membership of each of its sets after all rules fired, before defuzzification (set label → DOM).
    public let outputVariableDegrees: [String: [String: Double]]

    /// Defuzzified output values (output variable label → crisp value).
    public let outputValues: [String: Double]

    public init(
        inputs: [String: Double],
        inputVariableDegrees: [String: [String: Double]],
        ruleFiringStrengths: [Double],
        outputVariableDegrees: [String: [String: Double]],
        outputValues: [String: Double]
    ) {
        self.inputs = inputs
        self.inputVariableDegrees = inputVariableDegrees
        self.ruleFiringStrengths = ruleFiringStrengths
        self.outputVariableDegrees = outputVariableDegrees
        self.outputValues = outputValues
    }
}
