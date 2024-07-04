import SwiftUI

struct WorkoutEntryView: View {
    @Binding var date: Date
    @Binding var workouts: [Date: [ExerciseLog]]
    @State private var selectedWorkout = "Chest and Triceps"
    @State private var exercises: [ExerciseLog] = []
    @Binding var isPresented: Bool
    @State private var currentWeekOffset = 0
    @State private var selectedExercise: ExerciseLog?
    @AppStorage("weightUnit") private var weightUnit = WeightUnit.pounds

    let workoutTypes = ["Chest and Triceps", "Legs", "Back and Biceps", "Shoulders and Abs"]

    @Environment(\.dismiss) private var dismiss



    var body: some View {
        NavigationView {
            Form {
                Section {
                    weekSlider
                    
                    Picker("Select Workout", selection: $selectedWorkout) {
                        ForEach(workoutTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                ForEach($exercises) { $exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: $exercise, workouts: $workouts, selectedDate: $date)) {
                        Text(exercise.name.isEmpty ? "Unnamed Exercise" : exercise.name)
                    }
                }
                .onDelete(perform: deleteExercise)

                Button(action: addExercise) {
                    Text("Add Exercise")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                }

                Button(action: saveWorkout) {
                    Text("Save Workout")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Workout Entry")
            .navigationBarItems(leading: cancelButton(), trailing: EditButton())
            .onAppear {
                loadExistingWorkout()
            }
        }
    }


    private var weekSlider: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 8
            let buttonWidth = (geometry.size.width - (spacing * 6) - 40) / 7

            TabView(selection: $currentWeekOffset) {
                ForEach(-10...10, id: \.self) { offset in
                    HStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { index in
                            let weekDate = Calendar.current.date(byAdding: .day, value: index + (offset * 7), to: date.startOfCurrentWeek) ?? date
                            Button(action: {
                                date = weekDate
                            }) {
                                VStack {
                                    Text("\(Calendar.current.component(.day, from: weekDate))")
                                        .font(.headline)
                                        .frame(width: buttonWidth, height: 36)
                                        .background(date == weekDate ? Color.blue : Color.clear)
                                        .foregroundColor(date == weekDate ? .white : .black)
                                        .cornerRadius(18)
                                        .padding(.vertical, 5)

                                    Text(dayAbbreviation(for: weekDate))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .tag(offset)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .frame(height: 100)
    }

    private func dayAbbreviation(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date).uppercased()
    }

    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }


    private func addExercise() {
        let newExercise = ExerciseLog(id: UUID(), name: "", sets: [SetLog(weight: 0, reps: 0)])
        exercises.append(newExercise)
    }

    private func saveWorkout() {
        let updatedExercises = exercises.map { exercise in
            ExerciseLog(
                id: exercise.id,
                name: exercise.name,
                sets: exercise.sets.map { set in
                    SetLog(
                        id: set.id,
                        weight: WeightUtils.convert(set.weight, from: weightUnit, to: .pounds),
                        reps: set.reps
                    )
                },
                notes: exercise.notes,
                mediaAttachments: exercise.mediaAttachments,
                date: exercise.date
            )
        }

        var updatedWorkouts = workouts
        if var existingExercises = updatedWorkouts[date] {
            for updatedExercise in updatedExercises {
                if let index = existingExercises.firstIndex(where: { $0.id == updatedExercise.id }) {
                    existingExercises[index] = updatedExercise
                } else {
                    existingExercises.append(updatedExercise)
                }
            }
            updatedWorkouts[date] = existingExercises
        } else {
            updatedWorkouts[date] = updatedExercises
        }
        workouts = updatedWorkouts
        
        let stringKeyedWorkouts = updatedWorkouts.toStringKeys()
        FileStorage.save(stringKeyedWorkouts)
        
        isPresented = false
        dismiss()
    }
    

    private func loadExistingWorkout() {
        exercises = workouts[date] ?? []
    }

    private func cancelButton() -> some View {
        Button("Cancel") {
            isPresented = false
            dismiss()
        }
    }
}

extension Date {
    var startOfCurrentWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!.addingTimeInterval(86400)
    }
}
