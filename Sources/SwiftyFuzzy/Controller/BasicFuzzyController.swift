import Foundation

/// A fuzzy logic controller that holds linguistic variables and rules, and performs fuzzification and defuzzification.
///
/// **Convention:** Add variables with explicit roles via `addVariable(_:role:)`. Then `evaluate(inputs:)` will
/// fuzzify the given inputs and defuzzify all variables with role `.output`. If you use `addVariable(_)` only (no role),
/// the legacy convention applies: `evaluate(inputs:)` defuzzifies every variable whose label is not in `inputs`.
public final class BasicFuzzyController {
    private var variableEntries: [(variable: LinguisticVariable, role: VariableRole?)] = []
    private var rules: [Rule] = []
    private var defuzzifier: DefuzzifierMethod = CentroidMethod(sampleCount: 10)

    public init() {}

    // MARK: - Configuration

    /// Adds a linguistic variable with no explicit role (legacy). For `evaluate(inputs:)`, it is treated as output only if its label is not in `inputs`.
    public func addVariable(_ variable: LinguisticVariable) {
        variableEntries.append((variable, nil))
    }

    /// Adds a linguistic variable with an explicit input or output role. Use this so `inputVariables` / `outputVariables` and role-based `evaluate(inputs:)` work as intended.
    public func addVariable(_ variable: LinguisticVariable, role: VariableRole) {
        variableEntries.append((variable, role))
    }

    /// Variables that were added with role `.input`.
    public var inputVariables: [LinguisticVariable] {
        variableEntries.filter { $0.role == .input }.map(\.variable)
    }

    /// Variables that were added with role `.output`.
    public var outputVariables: [LinguisticVariable] {
        variableEntries.filter { $0.role == .output }.map(\.variable)
    }

    /// Trace of the last `evaluate(inputs:outputLabels:)` or `evaluate(inputs:)` run, for debugging. `nil` before any evaluation or if only `defuzzify(label:)` was used.
    public private(set) var lastEvaluation: EvaluationTrace?

    /// Sets the defuzzification method (default: centroid with 10 samples).
    public func setDefuzzifier(_ method: DefuzzifierMethod) {
        defuzzifier = method
    }

    /// Adds a rule: IF antecedent THEN consequent. Variable labels are matched case-insensitively.
    /// - Parameter weight: Rule weight in [0, 1] (default 1). Firing strength = antecedent DOM × weight, clamped to [0, 1].
    public func addRule(antecedent: FuzzyTerm, consequent: FuzzyTerm, weight: Double = 1) {
        rules.append(Rule(antecedent: antecedent, consequent: consequent, weight: weight))
    }

    // MARK: - Execution

    /// Fuzzifies the variable with the given label using the crisp input value.
    /// - Returns: `true` if a variable with that label was found and fuzzified, otherwise `false`.
    @discardableResult
    public func fuzzify(label: String, value: Double) -> Bool {
        guard let variable = variable(matching: label) else { return false }
        variable.fuzzify(input: value)
        return true
    }

    /// Defuzzifies the output variable with the given label.
    /// - Returns: The crisp output value.
    /// - Throws: `UnknownVariableError` if no variable has the given label.
    public func defuzzify(label: String) throws -> Double {
        guard let variable = variable(matching: label) else {
            throw UnknownVariableError(label: label)
        }
        rules.forEach { $0.consequent.clearDOM() }
        rules.forEach { $0.calculate() }
        return defuzzifier.defuzzifiedValue(for: variable)
    }

    // MARK: - Batch evaluation

    /// Runs a full evaluate cycle: fuzzifies the given inputs, fires all rules, and defuzzifies the requested outputs.
    ///
    /// - Parameters:
    ///   - inputs: Map of variable label → crisp value. Each label must match a variable in the controller.
    ///   - outputLabels: Labels of variables to defuzzify. Each must match a variable.
    /// - Returns: Map of output variable label → crisp defuzzified value (same order as `outputLabels`; duplicate labels overwrite).
    /// - Throws: `UnknownVariableError` if any input or output label does not match a variable.
    public func evaluate(inputs: [String: Double], outputLabels: [String]) throws -> [String: Double] {
        for (label, value) in inputs {
            guard let variable = variable(matching: label) else {
                throw UnknownVariableError(label: label)
            }
            variable.fuzzify(input: value)
        }

        var inputVariableDegrees: [String: [String: Double]] = [:]
        for (label, _) in inputs {
            if let variable = variable(matching: label) {
                inputVariableDegrees[label] = variable.currentDegreesOfMembership
            }
        }

        rules.forEach { $0.consequent.clearDOM() }
        let ruleFiringStrengths = rules.map(\.effectiveFiringStrength)
        rules.forEach { $0.calculate() }

        var outputVariableDegrees: [String: [String: Double]] = [:]
        for label in outputLabels {
            if let variable = variable(matching: label) {
                outputVariableDegrees[label] = variable.currentDegreesOfMembership
            }
        }

        var result: [String: Double] = [:]
        for label in outputLabels {
            guard let variable = variable(matching: label) else {
                throw UnknownVariableError(label: label)
            }
            result[label] = defuzzifier.defuzzifiedValue(for: variable)
        }

        lastEvaluation = EvaluationTrace(
            inputs: inputs,
            inputVariableDegrees: inputVariableDegrees,
            ruleFiringStrengths: ruleFiringStrengths,
            outputVariableDegrees: outputVariableDegrees,
            outputValues: result
        )
        return result
    }

    /// Runs a full evaluate cycle: fuzzifies the given inputs, fires all rules, and defuzzifies outputs.
    ///
    /// **With explicit roles:** If every variable was added via `addVariable(_:role:)`, defuzzifies all variables with role `.output`.
    ///
    /// **Legacy (no roles):** Defuzzifies every variable whose label is not in `inputs`. Variable labels are compared case-insensitively.
    ///
    /// - Parameter inputs: Map of variable label → crisp value. Each label must match a variable.
    /// - Returns: Map of output variable label → crisp defuzzified value.
    /// - Throws: `UnknownVariableError` if any input label does not match a variable.
    public func evaluate(inputs: [String: Double]) throws -> [String: Double] {
        let outputLabels: [String]
        let allWithRole = variableEntries.allSatisfy { $0.role != nil }
        if allWithRole && !outputVariables.isEmpty {
            outputLabels = outputVariables.map(\.label)
        } else {
            let inputLabelsLower = Set(inputs.keys.map { $0.lowercased() })
            outputLabels = variableEntries
                .map(\.variable)
                .filter { !inputLabelsLower.contains($0.label.lowercased()) }
                .map(\.label)
        }
        return try evaluate(inputs: inputs, outputLabels: outputLabels)
    }
}

// MARK: - Private

private extension BasicFuzzyController {
    var variables: [LinguisticVariable] {
        variableEntries.map(\.variable)
    }

    func variable(matching label: String) -> LinguisticVariable? {
        variables.first { $0.label.lowercased() == label.lowercased() }
    }
}
