import SwiftUI
import Charts

struct PerformanceComparisonView: View {
    @Binding var workouts: [Date: [ExerciseLog]]
    @State private var selectedExercise = ""
    @State private var uniqueExercises: [String] = []
    @State private var dataPoints: [ChartData] = []
    @State private var selectedDataPoint: ChartData?
    @State private var dateRange: DateRangeSelection = .monthly
    
    enum DateRangeSelection: String, CaseIterable {
        case weekly = "W"
        case monthly = "M"
        case sixMonths = "6M"
        case yearly = "Y"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                exerciseAndDateSelector
                    .padding(.horizontal)
                
                averageAndDateRangeInfo
                    .padding(.horizontal)
                
                if dataPoints.isEmpty {
                    Text("No data available for the selected exercise and date range.")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    chartView
                        .frame(height: 300)
                        .padding(.top, 10)
                }
            }
        }
        .navigationTitle("Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUniqueExercises()
            updateChartData()
        }
    }
    
    private var exerciseAndDateSelector: some View {
        VStack(spacing: 10) {
            Menu {
                ForEach(uniqueExercises, id: \.self) { exercise in
                    Button(exercise) {
                        selectedExercise = exercise
                        updateChartData()
                    }
                }
            } label: {
                HStack {
                    Text(selectedExercise.isEmpty ? "Select Exercise" : selectedExercise)
                        .foregroundColor(selectedExercise.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            
            Picker("Date Range", selection: $dateRange) {
                ForEach(DateRangeSelection.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: dateRange) { _ in
                updateChartData()
            }
        }
    }
    
    private var averageAndDateRangeInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AVERAGE")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(averageWeight())
                .font(.title2)
                .fontWeight(.bold)
            Text(dateRangeText())
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var chartView: some View {
        GeometryReader { geometry in
            Chart {
                ForEach(dataPoints) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Weight", data.weight)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.linear)
                    
                    PointMark(
                        x: .value("Date", data.date),
                        y: .value("Weight", data.weight)
                    )
                    .foregroundStyle(.blue)
                }
                
                if let highlightDate = selectedDataPoint?.date {
                    RuleMark(x: .value("Selected Date", highlightDate))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
            }
            .chartXScale(domain: xAxisDomain)
            .chartXAxis {
                AxisMarks(values: xAxisValues()) { value in
                    if let date = value.as(Date.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            switch dateRange {
                            case .weekly:
                                Text(date, format: .dateTime.weekday(.abbreviated))
                            case .monthly:
                                Text("\(Calendar.current.component(.day, from: date))")
                            case .sixMonths, .yearly:
                                Text(date, format: .dateTime.month(.abbreviated))
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            .chartYScale(domain: yAxisDomain)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color(UIColor.systemBackground))
            }
            .frame(width: geometry.size.width, height: 300)
            .chartOverlay { proxy in
                GeometryReader { innerGeometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let currentX = value.location.x - innerGeometry[proxy.plotAreaFrame].origin.x
                                    guard currentX >= 0, currentX < proxy.plotAreaSize.width else {
                                        selectedDataPoint = nil
                                        return
                                    }
                                    
                                    let dateAtLocation = proxy.value(atX: currentX, as: Date.self)!
                                    if let closestDataPoint = dataPoints.min(by: {
                                        abs($0.date.timeIntervalSince(dateAtLocation)) < abs($1.date.timeIntervalSince(dateAtLocation))
                                    }) {
                                        selectedDataPoint = closestDataPoint
                                    }
                                }
                                .onEnded { _ in
                                    selectedDataPoint = nil
                                }
                        )
                    
                    if let selectedDataPoint = selectedDataPoint,
                       let pointX = proxy.position(forX: selectedDataPoint.date) {
                        let boxWidth: CGFloat = 100
                        let boxHeight: CGFloat = 50
                        let xPosition = min(max(pointX - boxWidth / 2, 0), innerGeometry.size.width - boxWidth)
                        let yPosition: CGFloat = 0
                        
                        VStack {
                            Text("\(selectedDataPoint.weight, specifier: "%.1f") lbs")
                                .font(.headline)
                            Text(selectedDataPoint.date, format: .dateTime.day().month())
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .frame(width: boxWidth, height: boxHeight)
                        .position(x: xPosition + boxWidth / 2, y: yPosition + boxHeight / 2)
                    }
                }
            }
        }
    }
    
    private func xAxisValues() -> [Date] {
        guard let startDate = dataPoints.map({ $0.date }).min(),
              let endDate = dataPoints.map({ $0.date }).max() else {
            return []
        }
        
        let calendar = Calendar.current
        
        switch dateRange {
        case .weekly:
            return (0...6).compactMap { day in
                calendar.date(byAdding: .day, value: day, to: startDate)
            }
        case .monthly:
            let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)?.count ?? 30
            let days = [5, 10, 15, 20, 25, min(30, daysInMonth)]
            return days.compactMap { day in
                calendar.date(bySetting: .day, value: day, of: startDate)
            }.filter { $0 <= endDate }
        case .sixMonths, .yearly:
            var dateComponents = DateComponents()
            dateComponents.day = 1
            return calendar.generateDates(
                inside: DateInterval(start: startDate, end: endDate),
                matching: dateComponents
            )
        }
    }


    
    private func dateFormatForRange() -> Date.FormatStyle {
        switch dateRange {
        case .weekly:
            return .dateTime.weekday(.abbreviated)
        case .monthly:
            return .dateTime.day()
        case .sixMonths, .yearly:
            return .dateTime.month(.abbreviated)
        }
    }
    
    private var xAxisDomain: ClosedRange<Date> {
        guard let minDate = dataPoints.map({ $0.date }).min(),
              let maxDate = dataPoints.map({ $0.date }).max() else {
            return Date()...Date()
        }
        
        let calendar = Calendar.current
        
        switch dateRange {
        case .weekly:
            let weekStart = calendar.date(byAdding: .day, value: -1, to: minDate)!
            let weekEnd = calendar.date(byAdding: .day, value: 1, to: maxDate)!
            return weekStart...weekEnd
        case .monthly:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: minDate))!
            let monthEnd = calendar.date(byAdding: .day, value: 1, to: maxDate)!
            return monthStart...monthEnd
        case .sixMonths, .yearly:
            let totalDays = calendar.dateComponents([.day], from: minDate, to: maxDate).day ?? 0
            let extraDays = Double(totalDays) * 0.1
            let extendedStart = calendar.date(byAdding: .day, value: -Int(extraDays), to: minDate)!
            let extendedEnd = calendar.date(byAdding: .day, value: Int(extraDays), to: maxDate)!
            return extendedStart...extendedEnd
        }
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        let minWeight = dataPoints.map { $0.weight }.min() ?? 0
        let maxWeight = dataPoints.map { $0.weight }.max() ?? 100
        let padding = (maxWeight - minWeight) * 0.1
        return (minWeight - padding)...(maxWeight + padding)
    }
    
    private func loadUniqueExercises() {
        var exerciseSet = Set<String>()
        for exercises in workouts.values {
            for exercise in exercises {
                exerciseSet.insert(exercise.name)
            }
        }
        uniqueExercises = Array(exerciseSet).sorted()
        if !uniqueExercises.isEmpty && selectedExercise.isEmpty {
            selectedExercise = uniqueExercises[0]
        }
    }
    
    private func updateChartData() {
        guard !selectedExercise.isEmpty else {
            dataPoints = []
            return
        }
        
        let filteredWorkouts = filterWorkoutsByDateRange()
        var points: [ChartData] = []
        
        for (date, exercises) in filteredWorkouts {
            if let exercise = exercises.first(where: { $0.name == selectedExercise }) {
                let averageWeight = exercise.sets.isEmpty ? 0 : exercise.sets.reduce(0) { $0 + $1.weight } / Double(exercise.sets.count)
                points.append(ChartData(date: date, weight: averageWeight))            }
        }
        
        dataPoints = points.sorted(by: { $0.date < $1.date })
    }
    
    private func filterWorkoutsByDateRange() -> [Date: [ExerciseLog]] {
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .weekly:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return workouts.filter { $0.key >= weekStart && $0.key < weekEnd }
        case .monthly:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            return workouts.filter { $0.key >= monthStart && $0.key <= monthEnd }
        case .sixMonths:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            return workouts.filter { $0.key >= sixMonthsAgo }
        case .yearly:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return workouts.filter { $0.key >= yearAgo }
        }
    }
    
    private func averageWeight() -> String {
           let weights = dataPoints.map { $0.weight }
           if weights.isEmpty {
               return "No data"
           }
           let average = weights.reduce(0, +) / Double(weights.count)
           return String(format: "%.1f lbs", average)
       }
       
       private func dateRangeText() -> String {
           guard let startDate = dataPoints.map({ $0.date }).min(),
                 let endDate = dataPoints.map({ $0.date }).max() else {
               return "No data available"
           }
           
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "MMM d, yyyy"
           
           return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
       }
       
    private func strideByForDateRange() -> Calendar.Component {
        switch dateRange {
        case .weekly: return .day
        case .monthly: return .day
        case .sixMonths: return .month
        case .yearly: return .month
        }
    }
   }

   struct ChartData: Identifiable {
       var id = UUID()
       var date: Date
       var weight: Double
   }

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        Calendar.current.enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}
