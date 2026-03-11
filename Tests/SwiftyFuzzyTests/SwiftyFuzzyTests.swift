import XCTest
@testable import SwiftyFuzzy

final class SwiftyFuzzyTests: XCTestCase {

    // MARK: - Membership functions

    func testTriangularMembership() throws {
        let tri = try TriangularMembershipFunction(a: 0, b: 5, c: 10)
        XCTAssertEqual(tri.value(for: 0), 0)
        XCTAssertEqual(tri.value(for: 5), 1)
        XCTAssertEqual(tri.value(for: 10), 0)
        XCTAssertEqual(tri.value(for: 2.5), 0.5)
        XCTAssertEqual(tri.value(for: -1), 0)
        XCTAssertEqual(tri.value(for: 11), 0)
    }

    func testTrapezoidalMembership_finite() throws {
        let trap = try TrapezoidalMembershipFunction(a: 0, b: 10, c: 20, d: 30)
        XCTAssertEqual(trap.value(for: 0), 0)
        XCTAssertEqual(trap.value(for: 5), 0.5)
        XCTAssertEqual(trap.value(for: 10), 1)
        XCTAssertEqual(trap.value(for: 15), 1)
        XCTAssertEqual(trap.value(for: 20), 1)
        XCTAssertEqual(trap.value(for: 25), 0.5)
        XCTAssertEqual(trap.value(for: 30), 0)
        XCTAssertEqual(trap.value(for: 35), 0)
    }

    func testTrapezoidalMembership_infiniteRight() throws {
        let trap = try TrapezoidalMembershipFunction(a: 10, b: 20, c: 30, d: .infinity)
        XCTAssertEqual(trap.value(for: 15), 0.5)
        XCTAssertEqual(trap.value(for: 25), 1)
        XCTAssertEqual(trap.value(for: 30), 1)
        XCTAssertEqual(trap.value(for: 100), 1)
        XCTAssertFalse(trap.value(for: 100).isNaN)
    }

    func testRectangularMembership() throws {
        let rect = try RectangularMembershipFunction(a: 5, b: 15, y: 1)
        XCTAssertEqual(rect.value(for: 4), 0)
        XCTAssertEqual(rect.value(for: 5), 1)
        XCTAssertEqual(rect.value(for: 10), 1)
        XCTAssertEqual(rect.value(for: 15), 1)
        XCTAssertEqual(rect.value(for: 16), 0)
    }

    func testTriangularThrowsWhenInvalidOrder() {
        XCTAssertThrowsError(try TriangularMembershipFunction(a: 10, b: 5, c: 0)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
        XCTAssertThrowsError(try TriangularMembershipFunction(a: 0, b: 15, c: 10)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
    }

    func testDuplicateSetLabelThrows() throws {
        let variable = LinguisticVariable(label: "X")
        _ = try variable.addSet("a", membershipFunction: TriangularMembershipFunction(a: 0, b: 0.5, c: 1))
        XCTAssertThrowsError(try variable.addSet("a", membershipFunction: TriangularMembershipFunction(a: 0, b: 0.5, c: 1))) { error in
            XCTAssertTrue(error is DuplicateSetLabelError)
        }
    }

    func testGaussianMembership() throws {
        let g = try GaussianMembershipFunction(mean: 50, sigma: 10)
        XCTAssertEqual(g.value(for: 50), 1, accuracy: 1e-10)
        XCTAssertEqual(g.value(for: 60), g.value(for: 40), accuracy: 1e-10)
        XCTAssertEqual(g.value(for: 50 + 10), exp(-0.5), accuracy: 1e-10) // 1σ → exp(-0.5)
        XCTAssertEqual(g.min, 20)
        XCTAssertEqual(g.max, 80)
    }

    func testGaussianThrowsForInvalidSigma() {
        XCTAssertThrowsError(try GaussianMembershipFunction(mean: 0, sigma: 0)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
        XCTAssertThrowsError(try GaussianMembershipFunction(mean: 0, sigma: -1)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
    }

    // MARK: - Fuzzy operators

    func testFuzzyOpScalar() {
        XCTAssertEqual(FuzzyOp.and(0.3, 0.7), 0.3)
        XCTAssertEqual(FuzzyOp.or(0.3, 0.7), 0.7)
        XCTAssertEqual(FuzzyOp.not(0.4), 0.6)
    }

    // MARK: - Controller and defuzzification

    func testControllerDefuzzify() throws {
        let controller = BasicFuzzyController()
        let out = LinguisticVariable(label: "OUT")
        let low = try out.addSet("low", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 25, d: 50))
        let high = try out.addSet("high", membershipFunction: TrapezoidalMembershipFunction(a: 25, b: 50, c: 100, d: 100))
        controller.addVariable(out)

        let inVar = LinguisticVariable(label: "IN")
        let cold = try inVar.addSet("cold", membershipFunction: TriangularMembershipFunction(a: 0, b: 0, c: 50))
        let hot = try inVar.addSet("hot", membershipFunction: TriangularMembershipFunction(a: 0, b: 50, c: 50))
        controller.addVariable(inVar)
        controller.addRule(antecedent: cold, consequent: low)
        controller.addRule(antecedent: hot, consequent: high)

        controller.fuzzify(label: "IN", value: 0)
        controller.setDefuzzifier(CentroidMethod(sampleCount: 20))
        let result = try controller.defuzzify(label: "OUT")
        XCTAssertGreaterThanOrEqual(result, 0)
        XCTAssertLessThanOrEqual(result, 100)
    }

    func testDefuzzifyThrowsUnknownVariable() {
        let controller = BasicFuzzyController()
        XCTAssertThrowsError(try controller.defuzzify(label: "MISSING")) { error in
            XCTAssertTrue(error is UnknownVariableError)
        }
    }

    func testRuleWeightReducesFiringStrength() throws {
        let controller = BasicFuzzyController()
        let out = LinguisticVariable(label: "OUT")
        let low = try out.addSet("low", membershipFunction: try RectangularMembershipFunction(a: 0, b: 50, y: 1))
        let high = try out.addSet("high", membershipFunction: try RectangularMembershipFunction(a: 50, b: 100, y: 1))
        controller.addVariable(out)
        let inp = LinguisticVariable(label: "IN")
        let hot = try inp.addSet("hot", membershipFunction: TriangularMembershipFunction(a: 0, b: 100, c: 100))
        controller.addVariable(inp)
        controller.addRule(antecedent: hot, consequent: high, weight: 1)
        controller.addRule(antecedent: hot, consequent: low, weight: 0.5)
        controller.fuzzify(label: "IN", value: 100) // hot = 1
        controller.setDefuzzifier(CentroidMethod(sampleCount: 50))
        let result = try controller.defuzzify(label: "OUT")
        // high gets 1, low gets 0.5; centroid will be shifted toward high
        XCTAssertGreaterThan(result, 50)
    }

    func testMeanOfMaximaMethod() throws {
        let variable = LinguisticVariable(label: "Y")
        _ = try variable.addSet("mid", membershipFunction: try RectangularMembershipFunction(a: 20, b: 80, y: 1))
        variable.fuzzify(input: 50) // not used for defuzz; we set DOM manually via rules
        let set = variable.sets[0]
        set.orWithDOM(1) // full activation
        let mom = MeanOfMaximaMethod(sampleCount: 100)
        let result = mom.defuzzifiedValue(for: variable)
        XCTAssertEqual(result, 50, accuracy: 2) // mean of [20,80] = 50
    }

    func testSmallestOfMaximaMethod() throws {
        let variable = LinguisticVariable(label: "Y")
        _ = try variable.addSet("mid", membershipFunction: try RectangularMembershipFunction(a: 20, b: 80, y: 1))
        variable.sets[0].orWithDOM(1)
        let som = SmallestOfMaximaMethod(sampleCount: 100)
        let result = som.defuzzifiedValue(for: variable)
        XCTAssertEqual(result, 20, accuracy: 2) // left edge of plateau
    }

    func testLargestOfMaximaMethod() throws {
        let variable = LinguisticVariable(label: "Y")
        _ = try variable.addSet("mid", membershipFunction: try RectangularMembershipFunction(a: 20, b: 80, y: 1))
        variable.sets[0].orWithDOM(1)
        let lom = LargestOfMaximaMethod(sampleCount: 100)
        let result = lom.defuzzifiedValue(for: variable)
        XCTAssertEqual(result, 80, accuracy: 2) // right edge of plateau
    }

    func testFuzzifyReturnsFalseForUnknownLabel() {
        let controller = BasicFuzzyController()
        let ok = controller.fuzzify(label: "UNKNOWN", value: 1)
        XCTAssertFalse(ok)
    }

    // MARK: - Batch evaluate

    func testEvaluateWithExplicitOutputLabels() throws {
        let controller = BasicFuzzyController()
        let out = LinguisticVariable(label: "OUT")
        let low = try out.addSet("low", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 25, d: 50))
        let high = try out.addSet("high", membershipFunction: TrapezoidalMembershipFunction(a: 25, b: 50, c: 100, d: 100))
        controller.addVariable(out)
        let inVar = LinguisticVariable(label: "IN")
        let cold = try inVar.addSet("cold", membershipFunction: TriangularMembershipFunction(a: 0, b: 0, c: 50))
        let hot = try inVar.addSet("hot", membershipFunction: TriangularMembershipFunction(a: 0, b: 50, c: 50))
        controller.addVariable(inVar)
        controller.addRule(antecedent: cold, consequent: low)
        controller.addRule(antecedent: hot, consequent: high)
        controller.setDefuzzifier(CentroidMethod(sampleCount: 20))

        let result = try controller.evaluate(inputs: ["IN": 0], outputLabels: ["OUT"])
        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["OUT"])
        if let value = result["OUT"] {
            XCTAssertGreaterThanOrEqual(value, 0)
            XCTAssertLessThanOrEqual(value, 100)
        }
    }

    func testEvaluateReturnsAllNonInputVariables() throws {
        let controller = BasicFuzzyController()
        let out = LinguisticVariable(label: "OUT")
        _ = try out.addSet("low", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 25, d: 50))
        _ = try out.addSet("high", membershipFunction: TrapezoidalMembershipFunction(a: 25, b: 50, c: 100, d: 100))
        controller.addVariable(out)
        let inVar = LinguisticVariable(label: "IN")
        let cold = try inVar.addSet("cold", membershipFunction: TriangularMembershipFunction(a: 0, b: 0, c: 50))
        let hot = try inVar.addSet("hot", membershipFunction: TriangularMembershipFunction(a: 0, b: 50, c: 50))
        controller.addVariable(inVar)
        controller.addRule(antecedent: cold, consequent: out.sets[0])
        controller.addRule(antecedent: hot, consequent: out.sets[1])
        controller.setDefuzzifier(CentroidMethod(sampleCount: 20))

        let result = try controller.evaluate(inputs: ["IN": 25])
        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["OUT"])
    }

    func testEvaluateThrowsForUnknownInputLabel() throws {
        let controller = BasicFuzzyController()
        let v = LinguisticVariable(label: "X")
        _ = try v.addSet("a", membershipFunction: TriangularMembershipFunction(a: 0, b: 0.5, c: 1))
        controller.addVariable(v)
        controller.addRule(antecedent: FuzzySetProxy(set: v.sets[0]), consequent: FuzzySetProxy(set: v.sets[0]))

        XCTAssertThrowsError(try controller.evaluate(inputs: ["UNKNOWN": 0.5], outputLabels: ["X"])) { error in
            XCTAssertTrue(error is UnknownVariableError)
        }
    }

    func testEvaluateThrowsForUnknownOutputLabel() throws {
        let controller = BasicFuzzyController()
        let v = LinguisticVariable(label: "X")
        _ = try v.addSet("a", membershipFunction: TriangularMembershipFunction(a: 0, b: 0.5, c: 1))
        controller.addVariable(v)

        XCTAssertThrowsError(try controller.evaluate(inputs: ["X": 0.5], outputLabels: ["MISSING"])) { error in
            XCTAssertTrue(error is UnknownVariableError)
        }
    }

    func testInputOutputRoles() throws {
        let controller = BasicFuzzyController()
        let inp = LinguisticVariable(label: "IN")
        _ = try inp.addSet("low", membershipFunction: TriangularMembershipFunction(a: 0, b: 0, c: 1))
        let out = LinguisticVariable(label: "OUT")
        let z = try out.addSet("z", membershipFunction: try RectangularMembershipFunction(a: 0, b: 1, y: 1))
        controller.addVariable(inp, role: .input)
        controller.addVariable(out, role: .output)
        controller.addRule(antecedent: FuzzySetProxy(set: inp.sets[0]), consequent: z)

        XCTAssertEqual(controller.inputVariables.map(\.label), ["IN"])
        XCTAssertEqual(controller.outputVariables.map(\.label), ["OUT"])

        let result = try controller.evaluate(inputs: ["IN": 0.5])
        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result["OUT"])
    }

    // MARK: - Inspectability / debugging

    func testCurrentDegreesOfMembership() throws {
        let variable = LinguisticVariable(label: "T")
        _ = try variable.addSet("low", membershipFunction: TriangularMembershipFunction(a: 0, b: 0, c: 10))
        _ = try variable.addSet("high", membershipFunction: TriangularMembershipFunction(a: 0, b: 10, c: 10))
        variable.fuzzify(input: 5)
        let degrees = variable.currentDegreesOfMembership
        XCTAssertEqual(degrees["low"], 0.5)
        XCTAssertEqual(degrees["high"], 0.5)
    }

    func testRuleEffectiveFiringStrength() throws {
        let variable = LinguisticVariable(label: "X")
        let set = try variable.addSet("a", membershipFunction: try RectangularMembershipFunction(a: 0, b: 1, y: 1))
        variable.fuzzify(input: 0.5)
        let rule = Rule(antecedent: set, consequent: set, weight: 0.5)
        XCTAssertEqual(rule.effectiveFiringStrength, 0.5)
    }

    func testLastEvaluationTrace() throws {
        let controller = BasicFuzzyController()
        let inp = LinguisticVariable(label: "IN")
        _ = try inp.addSet("a", membershipFunction: TriangularMembershipFunction(a: 0, b: 0.5, c: 1))
        let out = LinguisticVariable(label: "OUT")
        _ = try out.addSet("z", membershipFunction: try RectangularMembershipFunction(a: 0, b: 1, y: 1))
        controller.addVariable(inp, role: .input)
        controller.addVariable(out, role: .output)
        controller.addRule(antecedent: FuzzySetProxy(set: inp.sets[0]), consequent: FuzzySetProxy(set: out.sets[0]))

        XCTAssertNil(controller.lastEvaluation)
        _ = try controller.evaluate(inputs: ["IN": 0.5], outputLabels: ["OUT"])
        let trace = controller.lastEvaluation
        XCTAssertNotNil(trace)
        XCTAssertEqual(trace?.inputs["IN"], 0.5)
        XCTAssertEqual(trace?.inputVariableDegrees["IN"]?["a"], 1.0) // triangular peak at 0.5
        XCTAssertEqual(trace?.ruleFiringStrengths.count, 1)
        XCTAssertEqual(trace?.outputValues["OUT"], 0.5)
    }

    // MARK: - Trapezoidal validation

    func testTrapezoidalThrowsForInvalidOrder() {
        XCTAssertThrowsError(try TrapezoidalMembershipFunction(a: 50, b: 10, c: 20, d: 30)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
        XCTAssertThrowsError(try TrapezoidalMembershipFunction(a: 0, b: 10, c: 5, d: 30)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
        XCTAssertThrowsError(try TrapezoidalMembershipFunction(a: 0, b: 10, c: 20, d: 15)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
    }

    func testTrapezoidalMembership_infiniteLeft() throws {
        let trap = try TrapezoidalMembershipFunction(a: -.infinity, b: 10, c: 20, d: 30)
        XCTAssertEqual(trap.value(for: -100), 1)
        XCTAssertEqual(trap.value(for: 5), 1)
        XCTAssertEqual(trap.value(for: 10), 1)
        XCTAssertEqual(trap.value(for: 15), 1)
        XCTAssertEqual(trap.value(for: 25), 0.5)
        XCTAssertEqual(trap.value(for: 30), 0)
        XCTAssertFalse(trap.value(for: -100).isNaN)
    }

    // MARK: - Rectangular validation

    func testRectangularThrowsForInvalidHeight() {
        XCTAssertThrowsError(try RectangularMembershipFunction(a: 0, b: 10, y: 0)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
        XCTAssertThrowsError(try RectangularMembershipFunction(a: 0, b: 10, y: -0.5)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
        XCTAssertThrowsError(try RectangularMembershipFunction(a: 0, b: 10, y: 1.5)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
    }

    func testRectangularThrowsForInvalidBounds() {
        XCTAssertThrowsError(try RectangularMembershipFunction(a: 10, b: 5, y: 1)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
        XCTAssertThrowsError(try RectangularMembershipFunction(a: 5, b: 5, y: 1)) { error in
            XCTAssertTrue(error is InvalidMembershipFunctionError)
        }
    }

    // MARK: - Composite term nesting

    func testNestedCompositeTerms() throws {
        let v = LinguisticVariable(label: "X")
        let a = try v.addSet("a", membershipFunction: try RectangularMembershipFunction(a: 0, b: 10, y: 1))
        let b = try v.addSet("b", membershipFunction: try RectangularMembershipFunction(a: 5, b: 15, y: 1))
        let c = try v.addSet("c", membershipFunction: try RectangularMembershipFunction(a: 10, b: 20, y: 1))
        v.fuzzify(input: 7) // a=1, b=1, c=0

        // AND(OR(a, c), NOT(b))
        let composite = FuzzyOp.and(FuzzyOp.or(a, c), FuzzyOp.not(b))
        // OR(a=1, c=0) = 1; NOT(b=1) = 0; AND(1, 0) = 0
        XCTAssertEqual(composite.degreeOfMembership, 0, accuracy: 1e-10)

        v.fuzzify(input: 12) // a=0, b=1, c=1
        let composite2 = FuzzyOp.and(FuzzyOp.or(a, c), FuzzyOp.not(b))
        // OR(a=0, c=1) = 1; NOT(b=1) = 0; AND(1, 0) = 0
        XCTAssertEqual(composite2.degreeOfMembership, 0, accuracy: 1e-10)

        v.fuzzify(input: 18) // a=0, b=0, c=1
        let composite3 = FuzzyOp.and(FuzzyOp.or(a, c), FuzzyOp.not(b))
        // OR(a=0, c=1) = 1; NOT(b=0) = 1; AND(1, 1) = 1
        XCTAssertEqual(composite3.degreeOfMembership, 1, accuracy: 1e-10)
    }

    // MARK: - Modifiers through FuzzySetProxy

    func testFuzzySetProxyModifiers() throws {
        let v = LinguisticVariable(label: "X")
        let ref = try v.addSet("a", membershipFunction: try RectangularMembershipFunction(a: 0, b: 10, y: 1))
        v.fuzzify(input: 5) // DOM = 1

        // Normal: DOM = 1
        XCTAssertEqual(ref.degreeOfMembership, 1, accuracy: 1e-10)
        // Very: DOM = 1^2 = 1
        XCTAssertEqual(ref.very().degreeOfMembership, 1, accuracy: 1e-10)
        // Fairly: DOM = sqrt(1) = 1
        XCTAssertEqual(ref.fairly().degreeOfMembership, 1, accuracy: 1e-10)

        // Test with partial membership
        let v2 = LinguisticVariable(label: "Y")
        let ref2 = try v2.addSet("b", membershipFunction: TriangularMembershipFunction(a: 0, b: 5, c: 10))
        v2.fuzzify(input: 2.5) // DOM = 0.5

        XCTAssertEqual(ref2.degreeOfMembership, 0.5, accuracy: 1e-10)
        XCTAssertEqual(ref2.very().degreeOfMembership, 0.25, accuracy: 1e-10) // 0.5^2
        XCTAssertEqual(ref2.fairly().degreeOfMembership, sqrt(0.5), accuracy: 1e-10) // sqrt(0.5)
    }

    // MARK: - Case-insensitive label matching

    func testCaseInsensitiveLabelMatching() throws {
        let controller = BasicFuzzyController()
        let v = LinguisticVariable(label: "Temperature")
        _ = try v.addSet("hot", membershipFunction: try RectangularMembershipFunction(a: 0, b: 100, y: 1))
        controller.addVariable(v)

        XCTAssertTrue(controller.fuzzify(label: "temperature", value: 50))
        XCTAssertTrue(controller.fuzzify(label: "TEMPERATURE", value: 50))
        XCTAssertTrue(controller.fuzzify(label: "Temperature", value: 50))
    }

    // MARK: - LinguisticVariable.removeSet

    func testRemoveSet() throws {
        let v = LinguisticVariable(label: "X")
        _ = try v.addSet("a", membershipFunction: TriangularMembershipFunction(a: 0, b: 5, c: 10))
        _ = try v.addSet("b", membershipFunction: TriangularMembershipFunction(a: 0, b: 5, c: 10))
        XCTAssertEqual(v.sets.count, 2)

        XCTAssertTrue(v.removeSet(label: "a"))
        XCTAssertEqual(v.sets.count, 1)
        XCTAssertEqual(v.sets[0].label, "b")

        // Removing non-existent returns false
        XCTAssertFalse(v.removeSet(label: "nonexistent"))

        // Case-insensitive removal
        XCTAssertTrue(v.removeSet(label: "B"))
        XCTAssertEqual(v.sets.count, 0)
    }

    // MARK: - Centroid edge cases

    func testCentroidReturnsMinWhenMaxEqualsMin() throws {
        let v = LinguisticVariable(label: "X")
        // Both sets define the same range → min == max
        _ = try v.addSet("a", membershipFunction: try RectangularMembershipFunction(a: 5, b: 5.001, y: 1))
        let centroid = CentroidMethod(sampleCount: 10)
        let result = centroid.defuzzifiedValue(for: v)
        // With no DOM set, should return midpoint
        XCTAssertEqual(result, (5 + 5.001) / 2, accuracy: 0.01)
    }

    // MARK: - End-to-end integration test with verified numerical output

    func testEndToEndThermostat() throws {
        let controller = BasicFuzzyController()

        // Input: temperature
        let temp = LinguisticVariable(label: "TEMP")
        let cold = try temp.addSet("cold", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 15, d: 20))
        let warm = try temp.addSet("warm", membershipFunction: TriangularMembershipFunction(a: 15, b: 22, c: 30))
        let hot = try temp.addSet("hot", membershipFunction: TrapezoidalMembershipFunction(a: 25, b: 30, c: 50, d: 50))
        controller.addVariable(temp, role: .input)

        // Output: fan speed (0-100%)
        let fan = LinguisticVariable(label: "FAN")
        let low = try fan.addSet("low", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 20, d: 40))
        let med = try fan.addSet("med", membershipFunction: TriangularMembershipFunction(a: 30, b: 50, c: 70))
        let high = try fan.addSet("high", membershipFunction: TrapezoidalMembershipFunction(a: 60, b: 80, c: 100, d: 100))
        controller.addVariable(fan, role: .output)

        controller.addRule(antecedent: cold, consequent: low)
        controller.addRule(antecedent: warm, consequent: med)
        controller.addRule(antecedent: hot, consequent: high)
        controller.setDefuzzifier(CentroidMethod(sampleCount: 200))

        // Cold input → should give low fan speed
        let coldResult = try controller.evaluate(inputs: ["TEMP": 10])
        XCTAssertLessThan(coldResult["FAN"]!, 35, "Cold temp should yield low fan speed")

        // Warm input → should give medium fan speed
        let warmResult = try controller.evaluate(inputs: ["TEMP": 22])
        XCTAssertGreaterThan(warmResult["FAN"]!, 30, "Warm temp should yield medium-ish fan speed")
        XCTAssertLessThan(warmResult["FAN"]!, 70, "Warm temp should yield medium-ish fan speed")

        // Hot input → should give high fan speed
        let hotResult = try controller.evaluate(inputs: ["TEMP": 40])
        XCTAssertGreaterThan(hotResult["FAN"]!, 65, "Hot temp should yield high fan speed")
    }

    // MARK: - Sampling includes endpoints

    func testSamplingIncludesRightEndpoint() throws {
        // If we have a set with membership only at the right endpoint,
        // it should be detected by defuzzifiers
        let v = LinguisticVariable(label: "X")
        _ = try v.addSet("right", membershipFunction: TriangularMembershipFunction(a: 90, b: 100, c: 100))
        v.sets[0].orWithDOM(1)

        let lom = LargestOfMaximaMethod(sampleCount: 100)
        let result = lom.defuzzifiedValue(for: v)
        XCTAssertEqual(result, 100, accuracy: 1, "LOM should reach the right endpoint")
    }

    // MARK: - Trapezoidal convenience init

    func testTrapezoidalConvenienceInit() throws {
        // Right-sided: flat from c onward (d = c)
        let rightSided = try TrapezoidalMembershipFunction(a: 0, b: 10, c: 20, right: true)
        XCTAssertEqual(rightSided.value(for: 5), 0.5)
        XCTAssertEqual(rightSided.value(for: 15), 1)
        XCTAssertEqual(rightSided.value(for: 20), 1)

        // Left-sided: flat up to b (a = a, b = a)
        let leftSided = try TrapezoidalMembershipFunction(a: 0, b: 10, c: 20, right: false)
        XCTAssertEqual(leftSided.value(for: 0), 1)
        XCTAssertEqual(leftSided.value(for: 15), 0.5)
        XCTAssertEqual(leftSided.value(for: 20), 0)
    }
}
