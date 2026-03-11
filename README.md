# SwiftyFuzzy

Swift fuzzy logic library. Linguistic variables, membership functions, rules, and defuzzification for fuzzy controllers. Port of [EasyFuzzy](https://github.com/cesarrosales/EasyFuzzy) (Java).

Requirements: Swift 6.2+, macOS 13+ / iOS 16+

## Installation

```bash
swift run SwiftyFuzzyDemo
```

Add to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../SwiftyFuzzy"), // or .package(url: "...", from: "0.1.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["SwiftyFuzzy"]),
]
```

## Usage

Create a controller, add variables (with optional `.input` / `.output` roles), add sets and rules, then call `evaluate(inputs:)` or `evaluate(inputs:outputLabels:)`. You can also use `fuzzify` and `defuzzify` step by step.

### Example: Thermostat (temperature + humidity → fan speed)

```swift
import SwiftyFuzzy

let controller = BasicFuzzyController()

let temp = LinguisticVariable(label: "TEMPERATURE")
let cold = try temp.addSet("cold", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 60, d: 68))
let comfortable = try temp.addSet("comfortable", membershipFunction: try GaussianMembershipFunction(mean: 72, sigma: 3))
let hot = try temp.addSet("hot", membershipFunction: TrapezoidalMembershipFunction(a: 78, b: 85, c: .infinity, d: .infinity))
controller.addVariable(temp, role: .input)

let humidity = LinguisticVariable(label: "HUMIDITY")
let dry = try humidity.addSet("dry", membershipFunction: TriangularMembershipFunction(a: 0, b: 0, c: 50))
let humid = try humidity.addSet("humid", membershipFunction: TrapezoidalMembershipFunction(a: 50, b: 80, c: 100, d: 100))
controller.addVariable(humidity, role: .input)

let fanSpeed = LinguisticVariable(label: "FAN_SPEED")
let off = try fanSpeed.addSet("off", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 20, d: 40))
let high = try fanSpeed.addSet("high", membershipFunction: TrapezoidalMembershipFunction(a: 60, b: 80, c: 100, d: 100))
controller.addVariable(fanSpeed, role: .output)

controller.addRule(antecedent: FuzzyOp.and(cold, dry), consequent: off)
controller.addRule(antecedent: FuzzyOp.and(hot, humid), consequent: high)
controller.setDefuzzifier(CentroidMethod(sampleCount: 50))

let outputs = try controller.evaluate(inputs: ["TEMPERATURE": 78, "HUMIDITY": 65])
print("Fan speed: \(outputs["FAN_SPEED"]!)%")
```

### More examples

The demo (`swift run SwiftyFuzzyDemo`) includes a washing-machine style example (load + dirt → duration), step-by-step fuzzify/defuzzify, and use of modifiers (`.very()`, `.fairly()`). See `Sources/SwiftyFuzzyDemo/main.swift`.

## API overview

| Concept | Type |
|--------|------|
| Fuzzy terms (rules) | `FuzzyTerm`, `FuzzySetProxy`, `FuzzyAND`, `FuzzyOR`, `FuzzyNOT` |
| Membership | `MembershipFunction`, `TriangularMembershipFunction`, `TrapezoidalMembershipFunction`, `RectangularMembershipFunction`, `GaussianMembershipFunction` |
| Variables | `LinguisticVariable`, `FuzzySet` |
| Roles | `VariableRole` (`.input` / `.output`), `addVariable(_:role:)`, `inputVariables`, `outputVariables` |
| Rules | `Rule`, `FuzzyOp` (rule weight optional) |
| Defuzzification | `DefuzzifierMethod`, `CentroidMethod`, `MeanOfMaximaMethod`, `SmallestOfMaximaMethod`, `LargestOfMaximaMethod` |
| Controller | `BasicFuzzyController` |
| Debug | `currentDegreesOfMembership`, `effectiveFiringStrength`, `EvaluationTrace`, `lastEvaluation` |
| Errors | `DuplicateSetLabelError`, `InvalidMembershipFunctionError`, `UnknownVariableError` |

## License

LGPL. See [EasyFuzzy](https://github.com/cesarrosales/EasyFuzzy) for details.
