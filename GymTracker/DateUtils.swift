import Foundation

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    static func fromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date!
    }
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}

extension Dictionary where Key == Date, Value == [ExerciseLog] {
    func toStringKeys() -> [String: [ExerciseLog]] {
        var result = [String: [ExerciseLog]]()
        for (date, exercises) in self {
            let dateString = date.toString()
            if let existingExercises = result[dateString] {
                result[dateString] = existingExercises + exercises
            } else {
                result[dateString] = exercises
            }
        }
        return result
    }
}

extension SetLog {
    static func == (lhs: SetLog, rhs: SetLog) -> Bool {
        lhs.id == rhs.id &&
        lhs.weight == rhs.weight &&
        lhs.reps == rhs.reps
    }
}
