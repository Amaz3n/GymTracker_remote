import SwiftUI

struct CalendarView: View {
    @Binding var workouts: [Date: [ExerciseLog]]
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var currentMonthDate: Date = Date()
    
    private let calendar = Calendar.current
    private let monthsToShow = 24 // Show 2 years
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        ZStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 30) // Spacer for fixed header
                        
                        ForEach(0..<monthsToShow, id: \.self) { index in
                            if let date = calendar.date(byAdding: .month, value: index, to: Date().startOfMonth) {
                                MonthView(date: date, selectedDate: $selectedDate, workouts: workouts)
                                    .id(index)
                            }
                        }
                    }
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                                               value: geometry.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        updateCurrentMonth()
                    }
                    .onAppear {
                        let selectedMonthIndex = calendar.dateComponents([.month], from: Date(), to: selectedDate).month ?? 0
                        proxy.scrollTo(selectedMonthIndex, anchor: .top)
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            
            VStack {
                fixedHeader
                Spacer()
            }
            
            monthOverlay
        }
        .navigationBarTitle("Calendar", displayMode: .inline)
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
        .gesture(
            DragGesture()
                .onChanged { _ in isDragging = true }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
    
    private var fixedHeader: some View {
        HStack(spacing: 0) {
            ForEach(dayNames, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .frame(height: 30)
        .background(Color(.systemBackground).opacity(0.8))
    }
    
    private var monthOverlay: some View {
        GeometryReader { geometry in
            Text(currentMonthDate.monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .padding()
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(10)
                .opacity(isDragging ? 1 : 0)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
        }
    }
    
    private func updateCurrentMonth() {
        let monthHeight = UIScreen.main.bounds.height / 2 // Approximate height of a month
        let currentMonthIndex = Int(-scrollOffset / monthHeight)
        if let date = calendar.date(byAdding: .month, value: currentMonthIndex, to: Date().startOfMonth) {
            currentMonthDate = date
        }
    }
}

struct DayItem: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
}

struct MonthView: View {
    let date: Date
    @Binding var selectedDate: Date
    let workouts: [Date: [ExerciseLog]]
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(date.monthYearString)
                .font(.headline)
                .padding(.leading)
                .padding(.top, 10)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: daysInWeek), spacing: 0) {
                ForEach(days()) { day in
                    DayCell(date: day.date, isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate),
                            hasWorkout: workouts.keys.contains { calendar.isDate($0, inSameDayAs: day.date) },
                            isCurrentMonth: day.isCurrentMonth)
                        .onTapGesture {
                            selectedDate = day.date
                        }
                }
            }
            Divider()
        }
    }
    
    private func days() -> [DayItem] {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        let startDate = calendar.date(byAdding: .day, value: -(calendar.component(.weekday, from: monthStart) - 1), to: monthStart)!
        
        var result: [DayItem] = []
        var currentDate = startDate
        
        while currentDate <= monthEnd || result.count % 7 != 0 {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: date, toGranularity: .month)
            result.append(DayItem(date: currentDate, isCurrentMonth: isCurrentMonth))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasWorkout: Bool
    let isCurrentMonth: Bool
    
    var body: some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .frame(height: 40)
            .foregroundColor(cellTextColor)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .overlay(
                Circle()
                    .fill(hasWorkout ? Color.blue : Color.clear)
                    .frame(width: 5, height: 5)
                    .offset(y: 12)
            )
    }
    
    private var cellTextColor: Color {
        if isSelected {
            return .blue
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}
