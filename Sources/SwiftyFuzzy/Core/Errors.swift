import Foundation

// MARK: - DuplicateSetLabelError

/// Thrown when adding a set whose label is already registered in a linguistic variable.
public struct DuplicateSetLabelError: Error, CustomStringConvertible, Sendable {
    public let label: String

    public init(label: String) {
        self.label = label
    }

    public var description: String {
        "Duplicate set label: '\(label)'"
    }
}

// MARK: - InvalidMembershipFunctionError

/// Thrown when membership function parameters are invalid (e.g. out-of-range or non-finite).
public struct InvalidMembershipFunctionError: Error, CustomStringConvertible, Sendable {
    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }

    public var description: String {
        reason
    }
}

// MARK: - UnknownVariableError

/// Thrown when a variable label is not found (e.g. in `fuzzify` or `defuzzify`).
public struct UnknownVariableError: Error, CustomStringConvertible, Sendable {
    public let label: String

    public init(label: String) {
        self.label = label
    }

    public var description: String {
        "Unknown variable: '\(label)'"
    }
}
