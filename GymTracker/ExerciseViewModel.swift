import SwiftUI
import Combine

class ExerciseViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var suggestions: [String] = []
    @Published var showSuggestions = false
    @Published var isAnimating = false
    @Published var textColor: Color = .primary
    @Published var glowOpacity: Double = 0
    
    public let allExerciseNames: [String]
    
    init(allExerciseNames: [String]) {
        self.allExerciseNames = allExerciseNames
        // ... other initialization ...
    }
    
    func updateSuggestions(for input: String) {
        guard !input.isEmpty, !isAnimating else {
            suggestions = []
            withAnimation {
                showSuggestions = false
            }
            return
        }
        
        suggestions = allExerciseNames.filter { $0.lowercased().hasPrefix(input.lowercased()) }
        withAnimation {
            showSuggestions = !suggestions.isEmpty
        }
    }
    
    func animateTextSelection(_ suggestion: String) {
        isAnimating = true
        withAnimation {
            showSuggestions = false
            textColor = .blue
            glowOpacity = 1
        }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        
        for (index, _) in suggestion.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                self.name = String(suggestion.prefix(index + 1))
                impact.impactOccurred()
                
                if index == suggestion.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.isAnimating = false
                            self.textColor = .primary
                            self.glowOpacity = 0
                        }
                    }
                }
            }
        }
    }
}
