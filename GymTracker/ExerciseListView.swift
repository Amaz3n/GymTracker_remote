import SwiftUI

struct AllExercisesView: View {
    @Binding var workouts: [Date: [ExerciseLog]]
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(searchResults, id: \.self) { exercise in
                    NavigationLink(destination: ExerciseHistoryView(exercise: exercise, workouts: $workouts)) {
                        Text(exercise)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Exercises", displayMode: .inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        }
    }
    
    private var searchResults: [String] {
        let allExercises = getAllExercises()
        if searchText.isEmpty {
            return allExercises
        } else {
            return allExercises.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private func getAllExercises() -> [String] {
        var exerciseSet = Set<String>()
        for exercises in workouts.values {
            for exercise in exercises {
                exerciseSet.insert(exercise.name)
            }
        }
        return Array(exerciseSet).sorted()
    }
}

struct ExerciseHistoryView: View {
    let exercise: String
    @Binding var workouts: [Date: [ExerciseLog]]
    
    var body: some View {
        List {
            ForEach(getExerciseLogs(), id: \.id) { log in
                NavigationLink(destination: ExerciseDetailView(exercise: .constant(log), workouts: $workouts, selectedDate: .constant(log.date))) {
                    VStack(alignment: .leading) {
                        Text(log.date, style: .date)
                        Text("Sets: \(log.sets.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(exercise)
    }
    
    private func getExerciseLogs() -> [ExerciseLog] {
        var logs: [ExerciseLog] = []
        for (date, exercises) in workouts {
            if let log = exercises.first(where: { $0.name == exercise }) {
                var logWithDate = log
                logWithDate.date = date
                logs.append(logWithDate)
            }
        }
        return logs.sorted(by: { $0.date > $1.date })
    }
}
