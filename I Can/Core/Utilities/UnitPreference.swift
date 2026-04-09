import Foundation

enum HeightUnit: String, CaseIterable {
    case cm
    case feet

    var label: String {
        switch self {
        case .cm: return "cm"
        case .feet: return "ft"
        }
    }
}

enum WeightUnit: String, CaseIterable {
    case kg
    case lbs

    var label: String { rawValue }
}

@MainActor
@Observable
final class UnitPreference {
    static let shared = UnitPreference()

    var heightUnit: HeightUnit {
        didSet { UserDefaults.standard.set(heightUnit.rawValue, forKey: "heightUnit") }
    }

    var weightUnit: WeightUnit {
        didSet { UserDefaults.standard.set(weightUnit.rawValue, forKey: "weightUnit") }
    }

    private init() {
        let h = UserDefaults.standard.string(forKey: "heightUnit") ?? HeightUnit.cm.rawValue
        heightUnit = HeightUnit(rawValue: h) ?? .cm
        let w = UserDefaults.standard.string(forKey: "weightUnit") ?? WeightUnit.kg.rawValue
        weightUnit = WeightUnit(rawValue: w) ?? .kg
    }

    // MARK: - Height conversions (DB stores cm)

    /// Cm to feet/inches tuple
    static func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches.rounded()) % 12
        return (feet, inches)
    }

    /// Feet + inches to cm
    static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) * 2.54
    }

    /// Format height for display using current preference
    func formatHeight(_ cm: Double) -> String {
        switch heightUnit {
        case .cm:
            return "\(Int(cm)) cm"
        case .feet:
            let (ft, inch) = Self.cmToFeetInches(cm)
            return "\(ft)'\(inch)\""
        }
    }

    /// Short format for badges
    func formatHeightShort(_ cm: Double) -> String {
        switch heightUnit {
        case .cm:
            return "\(Int(cm)) cm"
        case .feet:
            let (ft, inch) = Self.cmToFeetInches(cm)
            return "\(ft)'\(inch)\""
        }
    }

    // MARK: - Weight conversions (DB stores kg)

    static func kgToLbs(_ kg: Double) -> Double {
        kg * 2.20462
    }

    static func lbsToKg(_ lbs: Double) -> Double {
        lbs / 2.20462
    }

    /// Format weight for display using current preference
    func formatWeight(_ kg: Double) -> String {
        switch weightUnit {
        case .kg:
            return "\(Int(kg)) kg"
        case .lbs:
            return "\(Int(Self.kgToLbs(kg))) lbs"
        }
    }
}
