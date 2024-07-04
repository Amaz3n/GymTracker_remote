import SwiftUI

struct MainCalendarView: View {
    @State private var showWorkoutEntry = false
    @Binding var selectedDate: Date
    @Binding var workouts: [Date: [ExerciseLog]]
    @State private var selectedExercise: ExerciseLog?
    
    var body: some View {
        VStack {
            CalendarOverlayView(selectedDate: $selectedDate, workouts: $workouts)
                .padding()
            
            if let workoutForSelectedDate = workoutsForSelectedDate() {
                List {
                    ForEach(workoutForSelectedDate) { exercise in
                        NavigationLink(destination: ExerciseDetailView(
                            exercise: binding(for: exercise),
                            workouts: $workouts,
                            selectedDate: $selectedDate
                        )) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .font(.headline)
                                    HStack {
                                        if let firstSet = exercise.sets.first {
                                            Text("Weight: \(firstSet.weight, specifier: "%.2f") lbs")
                                            Text("Reps: \(firstSet.reps)")
                                        }
                                        Text("Sets: \(exercise.sets.count)")
                                    }
                                    .font(.subheadline)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            } else {
                Text("No workout recorded for this day")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Gym Tracker")
        .navigationBarItems(trailing: addButton())
        .onAppear {
            print("MainCalendarView appeared. Workouts: \(workouts)")
        }
        .onChange(of: selectedDate) { newValue in
            print("Selected date changed to: \(newValue)")
            print("Workouts for this date: \(workoutsForSelectedDate() ?? [])")
        }
    }
    
    private func addButton() -> some View {
        Button(action: {
            showWorkoutEntry = true
        }) {
            Image(systemName: "plus")
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(Color.blue))
                .frame(width: 40, height: 40)
        }
        .sheet(isPresented: $showWorkoutEntry) {
            WorkoutEntryView(date: $selectedDate, workouts: $workouts, isPresented: $showWorkoutEntry)
        }
    }
    
    private func workoutsForSelectedDate() -> [ExerciseLog]? {
        let calendar = Calendar.current
        return workouts.first { calendar.isDate($0.key, inSameDayAs: selectedDate) }?.value
    }
    
    private func binding(for exercise: ExerciseLog) -> Binding<ExerciseLog> {
        Binding<ExerciseLog>(
            get: { exercise },
            set: { newValue in
                if var dateExercises = workouts[selectedDate] {
                    if let index = dateExercises.firstIndex(where: { $0.id == exercise.id }) {
                        dateExercises[index] = newValue
                        workouts[selectedDate] = dateExercises
                    }
                }
            }
        )
    }
}
