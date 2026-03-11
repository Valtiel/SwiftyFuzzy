import SwiftyFuzzy

print("=== SwiftyFuzzy usage examples ===\n")

do {
    // ─────────────────────────────────────────────────────────────
    // Example 1: Smart thermostat (temperature + humidity → fan speed)
    // ─────────────────────────────────────────────────────────────
    print("1. Smart thermostat: temperature & humidity → fan speed\n")

    let thermostat = BasicFuzzyController()

    let temp = LinguisticVariable(label: "TEMPERATURE")
    let cold = try temp.addSet("cold", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 60, d: 68))
    _ = try temp.addSet("cool", membershipFunction: TriangularMembershipFunction(a: 62, b: 68, c: 74))
    let comfortable = try temp.addSet("comfortable", membershipFunction: try GaussianMembershipFunction(mean: 72, sigma: 3))
    let warm = try temp.addSet("warm", membershipFunction: TriangularMembershipFunction(a: 70, b: 76, c: 82))
    let hot = try temp.addSet("hot", membershipFunction: TrapezoidalMembershipFunction(a: 78, b: 85, c: .infinity, d: .infinity))
    thermostat.addVariable(temp, role: .input)

    let humidity = LinguisticVariable(label: "HUMIDITY")
    let dry = try humidity.addSet("dry", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 30, d: 45))
    let moderate = try humidity.addSet("moderate", membershipFunction: TriangularMembershipFunction(a: 35, b: 50, c: 70))
    let humid = try humidity.addSet("humid", membershipFunction: TrapezoidalMembershipFunction(a: 60, b: 85, c: 100, d: 100))
    thermostat.addVariable(humidity, role: .input)

    let fanSpeed = LinguisticVariable(label: "FAN_SPEED")
    let off = try fanSpeed.addSet("off", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 10, d: 25))
    let low = try fanSpeed.addSet("low", membershipFunction: TriangularMembershipFunction(a: 15, b: 30, c: 45))
    let medium = try fanSpeed.addSet("medium", membershipFunction: TriangularMembershipFunction(a: 35, b: 50, c: 65))
    let high = try fanSpeed.addSet("high", membershipFunction: TrapezoidalMembershipFunction(a: 55, b: 75, c: 100, d: 100))
    thermostat.addVariable(fanSpeed, role: .output)

    thermostat.addRule(antecedent: FuzzyOp.and(cold, dry), consequent: off)
    thermostat.addRule(antecedent: FuzzyOp.and(cold, moderate), consequent: low)
    thermostat.addRule(antecedent: FuzzyOp.and(comfortable, moderate), consequent: low)
    thermostat.addRule(antecedent: FuzzyOp.and(comfortable, humid), consequent: medium)
    thermostat.addRule(antecedent: FuzzyOp.and(warm, moderate), consequent: medium)
    thermostat.addRule(antecedent: FuzzyOp.and(warm, humid), consequent: high)
    thermostat.addRule(antecedent: FuzzyOp.and(hot, dry), consequent: medium)
    thermostat.addRule(antecedent: FuzzyOp.and(hot, moderate), consequent: high)
    thermostat.addRule(antecedent: FuzzyOp.and(hot, humid), consequent: high)

    thermostat.setDefuzzifier(CentroidMethod(sampleCount: 50))
    let fanResult = try thermostat.evaluate(inputs: ["TEMPERATURE": 78, "HUMIDITY": 60])
    print("   Input: 78°F, 60% humidity → Fan speed: \(String(format: "%.1f", fanResult["FAN_SPEED"]!))%")

    if let trace = thermostat.lastEvaluation {
        print("   Trace: temp sets = \(trace.inputVariableDegrees["TEMPERATURE"] ?? [:])")
        print("   Trace: rule strengths = \(trace.ruleFiringStrengths)")
    }
    print("")

    // ─────────────────────────────────────────────────────────────
    // Example 2: Washing machine (load size + dirt level → wash duration)
    // ─────────────────────────────────────────────────────────────
    print("2. Washing machine: load size & dirt level → wash duration (minutes)\n")

    let washer = BasicFuzzyController()

    let load = LinguisticVariable(label: "LOAD_SIZE")
    let small = try load.addSet("small", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 2, d: 4))
    let mediumLoad = try load.addSet("medium", membershipFunction: try GaussianMembershipFunction(mean: 5, sigma: 1.5))
    let large = try load.addSet("large", membershipFunction: TrapezoidalMembershipFunction(a: 6, b: 8, c: 10, d: 10))
    washer.addVariable(load, role: .input)

    let dirt = LinguisticVariable(label: "DIRT_LEVEL")
    let light = try dirt.addSet("light", membershipFunction: TrapezoidalMembershipFunction(a: 0, b: 0, c: 2, d: 4))
    let normal = try dirt.addSet("normal", membershipFunction: TriangularMembershipFunction(a: 2, b: 5, c: 8))
    let heavy = try dirt.addSet("heavy", membershipFunction: TrapezoidalMembershipFunction(a: 6, b: 9, c: 10, d: 10))
    washer.addVariable(dirt, role: .input)

    let duration = LinguisticVariable(label: "WASH_DURATION")
    let short = try duration.addSet("short", membershipFunction: try RectangularMembershipFunction(a: 15, b: 30, y: 1))
    let mediumDur = try duration.addSet("medium", membershipFunction: TriangularMembershipFunction(a: 25, b: 40, c: 55))
    let long = try duration.addSet("long", membershipFunction: TrapezoidalMembershipFunction(a: 45, b: 60, c: 90, d: 90))
    washer.addVariable(duration, role: .output)

    washer.addRule(antecedent: FuzzyOp.and(small, light), consequent: short)
    washer.addRule(antecedent: FuzzyOp.and(small, normal), consequent: short)
    washer.addRule(antecedent: FuzzyOp.and(small, heavy), consequent: mediumDur)
    washer.addRule(antecedent: FuzzyOp.and(mediumLoad, light), consequent: short, weight: 0.8)
    washer.addRule(antecedent: FuzzyOp.and(mediumLoad, normal), consequent: mediumDur)
    washer.addRule(antecedent: FuzzyOp.and(mediumLoad, heavy), consequent: long, weight: 1.0)
    washer.addRule(antecedent: FuzzyOp.and(large, light), consequent: mediumDur)
    washer.addRule(antecedent: FuzzyOp.and(large, normal), consequent: long)
    washer.addRule(antecedent: FuzzyOp.and(large, heavy), consequent: long)

    washer.setDefuzzifier(MeanOfMaximaMethod(sampleCount: 80))
    let washResult = try washer.evaluate(inputs: ["LOAD_SIZE": 5, "DIRT_LEVEL": 7], outputLabels: ["WASH_DURATION"])
    print("   Input: load 5 kg, dirt 7/10 → Wash duration: \(String(format: "%.0f", washResult["WASH_DURATION"]!)) min (MOM defuzzifier)")

    washer.setDefuzzifier(CentroidMethod(sampleCount: 50))
    let washCentroid = try washer.evaluate(inputs: ["LOAD_SIZE": 5, "DIRT_LEVEL": 7])
    print("   Same inputs with centroid: \(String(format: "%.0f", washCentroid["WASH_DURATION"]!)) min\n")

    // ─────────────────────────────────────────────────────────────
    // Example 3: Step-by-step and inspectability
    // ─────────────────────────────────────────────────────────────
    print("3. Step-by-step fuzzify/defuzzify and variable inspection\n")

    thermostat.fuzzify(label: "TEMPERATURE", value: 75)
    thermostat.fuzzify(label: "HUMIDITY", value: 55)
    let tempVar = thermostat.inputVariables.first { $0.label == "TEMPERATURE" }!
    print("   After fuzzify(75°F): \(tempVar.currentDegreesOfMembership)")
    print("   Best matching set: \"\(tempVar.bestLabel)\"")

    let stepResult = try thermostat.defuzzify(label: "FAN_SPEED")
    print("   Defuzzified FAN_SPEED: \(String(format: "%.1f", stepResult))%\n")

    // ─────────────────────────────────────────────────────────────
    // Example 4: Modifiers (very / fairly) and NOT
    // ─────────────────────────────────────────────────────────────
    print("4. Modifiers: .very() and .fairly() on sets\n")

    let comfort = LinguisticVariable(label: "COMFORT")
    _ = try comfort.addSet("mild", membershipFunction: TriangularMembershipFunction(a: 0, b: 50, c: 100))
    comfort.fuzzify(input: 70)
    let mildSet = comfort.sets[0]
    let mildRef = FuzzySetProxy(set: mildSet)
    print("   \"mild\" at 70: DOM = \(mildSet.degreeOfMembership)")
    print("   \"very mild\" (μ²): DOM = \(mildRef.very().degreeOfMembership)")
    print("   \"fairly mild\" (√μ): DOM = \(mildRef.fairly().degreeOfMembership)\n")

    print("=== Done ===")
} catch {
    print("Error: \(error)")
}
