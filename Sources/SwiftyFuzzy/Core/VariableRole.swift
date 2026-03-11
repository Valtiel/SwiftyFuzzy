import Foundation

/// Role of a linguistic variable in the controller: input (fuzzified from crisp values) or output (defuzzified to a crisp value).
public enum VariableRole: Sendable {
    /// Variable is an input; use `fuzzify(label:value:)` or pass it in `evaluate(inputs:...)`.
    case input
    /// Variable is an output; use `defuzzify(label:)` or request it in `evaluate(outputLabels:)` / `evaluate(inputs:)`.
    case output
}
