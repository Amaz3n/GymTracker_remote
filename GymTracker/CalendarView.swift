import SwiftUI

struct CalendarView: View {
    @Binding var workouts: [Date: [ExerciseLog]]
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    private let monthsToShow = 49 // Show 2 years before and after the current month
    private let currentDate: Date
    private let startDate: Date
    private let initialScrollIndex: Int
    
    init(workouts: Binding<[Date: [ExerciseLog]]>, selectedDate: Binding<Date>) {
        self._workouts = workouts
        self._selectedDate = selectedDate
        
        let calendar = Calendar.current
        self.currentDate = Date()
        self.startDate = calendar.date(byAdding: .month, value: -24, to: self.currentDate.startOfMonth)!
        self.initialScrollIndex = 24 // Middle of the 49 months
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<monthsToShow, id: \.self) { index in
                            if let monthDate = Calendar.current.date(byAdding: .month, value: index, to: startDate) {
                                MonthView(date: monthDate, workouts: workouts, selectedDate: $selectedDate, dismissAction: { presentationMode.wrappedValue.dismiss() })
                                    .id(index)
                            }
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo(initialScrollIndex, anchor: .center)
                }
            }
            .navigationBarTitle("Workout Calendar", displayMode: .inline)
            .navigationBarItems(leading: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }
}

struct MonthView: View {
    let date: Date
    let workouts: [Date: [ExerciseLog]]
    @Binding var selectedDate: Date
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(monthYearString(from: date))
                .font(.headline)
                .padding(.leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(for: date), id: \.id) { day in
                    if let date = day.date {
                        DayCell(date: date, hasWorkout: workouts.keys.contains { Calendar.current.isDate($0, inSameDayAs: date) }, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                selectedDate = date
                                dismissAction()
                            }
                    } else {
                        Color.clear
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth(for date: Date) -> [DayItem] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [DayItem] = Array(repeating: DayItem(id: UUID(), date: nil), count: firstWeekday - 1)
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(DayItem(id: UUID(), date: date))
            }
        }
        
        return days
    }
}

struct DayItem: Identifiable {
    let id: UUID
    let date: Date?
}

struct DayCell: View {
    let date: Date
    let hasWorkout: Bool
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(hasWorkout ? Color.blue : Color.clear)
                .frame(width: 32, height: 32)
            
            Circle()
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                .frame(width: 32, height: 32)
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14))
                .foregroundColor(hasWorkout ? .white : .primary)
        }
        .frame(height: 40)
    }
}
