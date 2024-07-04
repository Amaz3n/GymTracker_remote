import Foundation

struct WeightUtils {
    static func convert(_ weight: Double, from fromUnit: WeightUnit, to toUnit: WeightUnit) -> Double {
        if fromUnit == toUnit {
            return weight
        }
        switch (fromUnit, toUnit) {
        case (.pounds, .kilograms):
            return weight * 0.453592
        case (.kilograms, .pounds):
            return weight / 0.453592
        case (.pounds, .pounds), (.kilograms, .kilograms):
            return weight
        }
    }
}
