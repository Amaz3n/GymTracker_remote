import SwiftUI
import ActivityKit

struct ContentView: View {
    @State private var workouts: [Date: [ExerciseLog]] = [:]
    @State private var selectedDate: Date = Date()
    @AppStorage("colorScheme") private var colorScheme = ColorSchemeOption.system
    
    var body: some View {
        TabView {
            NavigationView {
                WorkoutTrackerView(selectedDate: $selectedDate, workouts: $workouts)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            
            NavigationView {
                PerformanceComparisonView(workouts: $workouts)
            }
            .tabItem {
                Label("Metrics", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            AllExercisesView(workouts: $workouts)
            .tabItem {
                Label("Exercises", systemImage: "dumbbell.fill")
            }
            
            SettingsView(workouts: $workouts)
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .preferredColorScheme(colorScheme.colorScheme)
        .onAppear {
            self.workouts = Self.loadWorkouts()
            self.selectedDate = Date() // Ensuring selected date is set to current date in local time zone
        }
        .onChange(of: workouts) { _, newValue in
            Self.saveWorkouts(newValue)
        }
    }
    
    static func loadWorkouts() -> [Date: [ExerciseLog]] {
        if let loadedData = FileStorage.load() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return loadedData.reduce(into: [Date: [ExerciseLog]]()) { result, element in
                if let date = dateFormatter.date(from: element.key) {
                    result[date.startOfDay()] = element.value
                }
            }
        } else {
            print("Failed to load workouts from file storage")
            return addInitialTestData()
        }
    }

    static func saveWorkouts(_ workouts: [Date: [ExerciseLog]]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let stringKeyedWorkouts = workouts.reduce(into: [String: [ExerciseLog]]()) { result, element in
            let dateString = dateFormatter.string(from: element.key)
            result[dateString] = element.value
        }
        FileStorage.save(stringKeyedWorkouts)
    }
    
    private static func addInitialTestData() -> [Date: [ExerciseLog]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let sampleDate = dateFormatter.date(from: "2024-06-22") else {
            print("Failed to create date from string")
            return [:]
        }
        
        let sampleExercise = ExerciseLog(name: "Test Exercise", sets: [SetLog(weight: 100, reps: 10)], notes: "Sample notes")
        let initialWorkouts = [sampleDate: [sampleExercise]]
        
        print("Added initial test data: \(initialWorkouts)")
        return initialWorkouts
    }
}

struct WorkoutTrackerView: View {
    @Binding var selectedDate: Date
    @Binding var workouts: [Date: [ExerciseLog]]
    @State private var currentWeekOffset = 0
    @State private var showingAddExercise = false
    @State private var showingCalendarView = false
    @State private var newExercise = ExerciseLog(name: "", sets: [], notes: "")
    
    var body: some View {
        VStack(spacing: 0) {
            weekSlider
                .frame(height: 90)
                .padding(.top, 8)
            
            exerciseListOrEmptyState
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingCalendarView = true
                }) {
                    Image(systemName: "calendar")
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Gym Tracker")
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    newExercise = ExerciseLog(name: "", sets: [], notes: "")
                    showingAddExercise = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            self.selectedDate = self.selectedDate.startOfDay()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            self.selectedDate = newValue.startOfDay()
        }
        
        
        .sheet(isPresented: $showingAddExercise) {
            NavigationView {
                ExerciseDetailView(exercise: $newExercise, workouts: $workouts, selectedDate: $selectedDate)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingCalendarView) {
            CalendarView(workouts: $workouts, selectedDate: $selectedDate)
        }
    }
    
    private func saveNewExercise() {
        if !newExercise.name.isEmpty {
            if workouts[selectedDate] != nil {
                workouts[selectedDate]?.append(newExercise)
            } else {
                workouts[selectedDate] = [newExercise]
            }
        }
    }
    
    var weekSlider: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 8
            let buttonWidth = (geometry.size.width - (spacing * 6) - 40) / 7
            
            TabView(selection: $currentWeekOffset) {
                ForEach(-10...10, id: \.self) { offset in
                    WeekView(offset: offset, selectedDate: $selectedDate, buttonWidth: buttonWidth)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: selectedDate) { oldValue, newValue in
                if !Calendar.current.isDate(oldValue, equalTo: newValue, toGranularity: .weekOfYear) {
                    currentWeekOffset = weekOffset(for: newValue)
                }
            }
        }
        .frame(height: 100)
    }
    
    private func weekOffset(for date: Date) -> Int {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let weekDifference = calendar.dateComponents([.weekOfYear], from: referenceDate, to: date).weekOfYear ?? 0
        return weekDifference
    }
    
    struct WeekView: View {
        let offset: Int
        @Binding var selectedDate: Date
        let buttonWidth: CGFloat
        
        var body: some View {
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let weekDate = self.dateForDayInWeek(dayIndex: index)
                    Button(action: {
                        selectedDate = weekDate.startOfDay()
                    }) {
                        VStack {
                            Text("\(Calendar.current.component(.day, from: weekDate))")
                                .font(.headline)
                                .frame(width: buttonWidth, height: 36)
                                .background(selectedDate.isSameDay(as: weekDate) ? Color.blue : Color.clear)
                                .foregroundColor(selectedDate.isSameDay(as: weekDate) ? .white : .primary)
                                .cornerRadius(18)
                            
                            Text(dayAbbreviation(for: weekDate))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        
        private func dateForDayInWeek(dayIndex: Int) -> Date {
            let calendar = Calendar.current
            let referenceDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            return calendar.date(byAdding: .day, value: offset * 7 + dayIndex, to: referenceDate)!
        }
        
        private func dayAbbreviation(for date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE"
            return dateFormatter.string(from: date).uppercased()
        }
    }
    
    private var exerciseListOrEmptyState: some View {
        Group {
            if let exercises = workouts[selectedDate.startOfDay()], !exercises.isEmpty {
                ExerciseListView(workouts: $workouts, selectedDate: selectedDate.startOfDay())
            } else {
                VStack {
                    Spacer()
                    Text("No exercises recorded for this date")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
    }
    struct ExerciseListView: View {
        @Binding var workouts: [Date: [ExerciseLog]]
        let selectedDate: Date
        @AppStorage("weightUnit") private var weightUnit = WeightUnit.pounds
        
        var body: some View {
            List {
                ForEach(workouts[selectedDate] ?? [], id: \.id) { exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: binding(for: exercise), workouts: $workouts, selectedDate: .constant(selectedDate))) {
                        ExerciseRowView(exercise: exercise, weightUnit: weightUnit)
                    }
                }
                .onDelete(perform: deleteExercises)
            }
            .listStyle(InsetGroupedListStyle())
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
        
        private func deleteExercises(at offsets: IndexSet) {
            if var dateExercises = workouts[selectedDate] {
                dateExercises.remove(atOffsets: offsets)
                workouts[selectedDate] = dateExercises
            }
        }
    }
    
    struct ExerciseRowView: View {
        let exercise: ExerciseLog
        let weightUnit: WeightUnit
        
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.headline)
                    Text("\(exercise.sets.count) sets")
                        .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    if !exercise.sets.isEmpty {
                        Text(weightDisplay)
                        Text(repsDisplay)
                    }
                }
                .font(.subheadline)
            }
        }
        
        private var weightDisplay: String {
            let weights = exercise.sets.map { roundWeight($0.weightInPreferredUnit(weightUnit)) }
            let unit = weightUnit == .pounds ? "lbs" : "kg"
            if Set(weights).count == 1, let weight = weights.first {
                return "\(weight) \(unit)"
            } else {
                return "\(weights.min() ?? "0")-\(weights.max() ?? "0") \(unit)"
            }
        }
        
        private func roundWeight(_ weight: Double) -> String {
            switch weightUnit {
            case .pounds:
                return String(format: "%.1f", weight)
            case .kilograms:
                return String(Int(round(weight)))
            }
        }
        
        private var repsDisplay: String {
            let reps = exercise.sets.map { $0.reps }
            if Set(reps).count == 1, let rep = reps.first {
                return "\(rep) reps"
            } else {
                return "\(reps.min() ?? 0)-\(reps.max() ?? 0) reps"
            }
        }
    }
}
