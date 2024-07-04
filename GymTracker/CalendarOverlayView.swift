import SwiftUI

struct CalendarOverlayView: View {
    @Binding var selectedDate: Date
    @Binding var workouts: [Date: [ExerciseLog]]
    
    var body: some View {
        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .overlay(
                calendarOverlay()
                    .allowsHitTesting(false)
            )
    }
    
    private func calendarOverlay() -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            let cellWidth = size.width / 7
            let cellHeight = size.height / 6
            let startDate = startOfMonth(for: selectedDate)
            
            ForEach(0..<42, id: \.self) { index in
                let date = calendarDate(at: index, from: startDate)
                if hasWorkout(on: date) {
                    workoutIndicator(at: CGPoint(
                        x: CGFloat(index % 7) * cellWidth + cellWidth / 2,
                        y: CGFloat(index / 7) * cellHeight + cellHeight * 0.8
                    ))
                }
            }
        }
    }
    
    private func workoutIndicator(at position: CGPoint) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 6, height: 6)
            .position(position)
    }
    
    private func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func calendarDate(at index: Int, from startDate: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: index, to: startDate) ?? startDate
    }
    
    private func hasWorkout(on date: Date) -> Bool {
        let calendar = Calendar.current
        return workouts.keys.contains { calendar.isDate($0, inSameDayAs: date) }
    }
}
