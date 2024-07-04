import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme = ColorSchemeOption.system
    @AppStorage("weightUnit") private var weightUnit = WeightUnit.pounds
    @State private var selectedIcon = "dumbbell"
    @State private var showingExporter = false
    @State private var showingImporter = false
    @Binding var workouts: [Date: [ExerciseLog]]
    
    let icons = ["dumbbell", "figure.walk", "heart.fill", "bed.double.fill"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Color Scheme", selection: $colorScheme) {
                        Text("Auto").tag(ColorSchemeOption.system)
                        Text("Light").tag(ColorSchemeOption.light)
                        Text("Dark").tag(ColorSchemeOption.dark)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    NavigationLink(destination: IconSelectionView(selectedIcon: $selectedIcon, icons: icons)) {
                        HStack {
                            Text("App Icon")
                            Spacer()
                            Image(systemName: selectedIcon)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Units")) {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Pounds (lbs)").tag(WeightUnit.pounds)
                        Text("Kilograms (kg)").tag(WeightUnit.kilograms)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("App")) {
                    Button("Rate App") {
                        // Implement app rating functionality
                    }
                    
                    Button("Send Feedback") {
                        // Implement feedback functionality
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Text("About")
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button("Export Data") {
                        showingExporter = true
                    }
                    Button("Import Data") {
                        showingImporter = true
                    }
                }
                
                Section(header: Text("Backups")) {
                    Button("Backup to iCloud") {
                        // Implement iCloud backup functionality
                    }
                    
                    Button("Restore from iCloud") {
                        // Implement iCloud restore functionality
                    }
                }
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $showingExporter,
                document: WorkoutsDocument(workouts: workouts),
                contentType: .json,
                defaultFilename: "workouts_export"
            ) { result in
                switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    // Handle importing data
                    importData(from: url)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func importData(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedWorkouts = try decoder.decode([String: [ExerciseLog]].self, from: data)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            workouts = importedWorkouts.reduce(into: [Date: [ExerciseLog]]()) { result, element in
                if let date = dateFormatter.date(from: element.key) {
                    result[date] = element.value
                }
            }
            print("Data imported successfully")
        } catch {
            print("Failed to import data: \(error.localizedDescription)")
        }
    }
}

enum WeightUnit: String, Codable {
    case pounds
    case kilograms
}


struct WorkoutsDocument: FileDocument {
    var workouts: [Date: [ExerciseLog]]
    
    static var readableContentTypes: [UTType] { [.json] }
    
    init(workouts: [Date: [ExerciseLog]]) {
        self.workouts = workouts
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let decodedWorkouts = try? JSONDecoder().decode([String: [ExerciseLog]].self, from: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        self.workouts = decodedWorkouts.reduce(into: [Date: [ExerciseLog]]()) { result, element in
            if let date = dateFormatter.date(from: element.key) {
                result[date] = element.value
            }
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let encodableWorkouts = workouts.reduce(into: [String: [ExerciseLog]]()) { result, element in
            let dateString = dateFormatter.string(from: element.key)
            result[dateString] = element.value
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(encodableWorkouts)
        return .init(regularFileWithContents: data)
    }
}

struct IconSelectionView: View {
    @Binding var selectedIcon: String
    let icons: [String]
    
    var body: some View {
        List {
            ForEach(icons, id: \.self) { icon in
                Button(action: {
                    selectedIcon = icon
                    // Implement icon changing functionality here
                }) {
                    HStack {
                        Image(systemName: icon)
                        Text(icon.capitalized)
                        Spacer()
                        if selectedIcon == icon {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select App Icon")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Gym Tracker App")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .font(.subheadline)
            
            Text("© 2024 Your Company Name")
                .font(.caption)
            
            Text("This app helps you track your gym workouts and monitor your progress over time.")
                .multilineTextAlignment(.center)
                .padding()
            
            Link("Visit Our Website", destination: URL(string: "https://www.yourcompany.com")!)
                .padding()
        }
        .navigationTitle("About")
    }
}
