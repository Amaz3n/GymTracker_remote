import SwiftUI
import PhotosUI
import AVFoundation
import AVKit

struct ExerciseDetailView: View {
    @Binding var exercise: ExerciseLog
    @Binding var workouts: [Date: [ExerciseLog]]
    @Binding var selectedDate: Date
    @State private var localExercise: ExerciseLog
    @State private var showingMediaPicker = false
    @State private var showingCamera = false
    @State private var selectedItems = [PhotosPickerItem]()
    @State private var inputImage: UIImage?
    @State private var inputVideo: URL?
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    
    // State variables for autocomplete
    @State private var suggestions: [String] = []
    @State private var showSuggestions = false
    
    // State variables for animation
    @State private var isAnimating = false
    @State private var animatedText = ""
    @State private var bounceOffsets: [CGFloat] = []
    @State private var glowOpacity: Double = 0
    @State private var suggestionHeight: CGFloat = 0
    @State private var showingSetPicker = false
    @State private var currentSetIndex: Int?
    @State private var tempWeight: Double = 0
    @State private var tempReps: Int = 0
    @State private var textColor: Color = .primary
    @AppStorage("weightUnit") private var weightUnit = WeightUnit.pounds
    @State private var showAlert = false
    @State private var alertMessage = ""
    @StateObject private var viewModel: ExerciseViewModel


    
    init(exercise: Binding<ExerciseLog>, workouts: Binding<[Date: [ExerciseLog]]>, selectedDate: Binding<Date>) {
        self._exercise = exercise
        self._workouts = workouts
        self._selectedDate = selectedDate
        let initialExercise = exercise.wrappedValue
        self._localExercise = State(initialValue: ExerciseLog(
            name: initialExercise.name,
            sets: initialExercise.sets.isEmpty ? [SetLog(weight: 0, reps: 0)] : initialExercise.sets,
            notes: initialExercise.notes,
            mediaAttachments: initialExercise.mediaAttachments
        ))
        let allExerciseNames = Self.getAllUniqueExerciseNames(from: workouts.wrappedValue)
        self._viewModel = StateObject(wrappedValue: ExerciseViewModel(allExerciseNames: allExerciseNames))
    }
    
    var isNewExercise: Bool {
        workouts[selectedDate]?.contains(where: { $0.id == exercise.id }) != true
    }
    
    var body: some View {
        Form {
            exerciseDetailsSection
            setsSection
            notesSection
            mediaAttachmentsSection
            deleteExerciseSection
        }
        .navigationTitle(localExercise.name.isEmpty ? "New Exercise" : localExercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveExercise()
                }
            }
        }
        .onAppear {
            viewModel.name = localExercise.name
        }
    
    
        .onChange(of: selectedItems) { newValue in
            Task {
                await handleSelectedItems(newValue)
            }
        }
        .photosPicker(
            isPresented: $showingMediaPicker,
            selection: $selectedItems,
            matching: .any(of: [.images, .videos]),
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showingCamera, content: {
                    CameraPicker(image: $inputImage, videoURL: $inputVideo, showAlert: $showAlert, alertMessage: $alertMessage)
                })
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Camera Access"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
        .actionSheet(isPresented: $showingDeleteAlert) {
            ActionSheet(
                title: Text("Delete Exercise"),
                message: Text("Are you sure you want to delete this exercise?"),
                buttons: [
                    .destructive(Text("Delete")) {
                        deleteExercise()
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingSetPicker) {
            SetPickerView(sets: $localExercise.sets)
                .presentationDetents([.height(300)])
        }
    }
    
    private var exerciseDetailsSection: some View {
        Section(header: Text("Exercise Details")) {
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Exercise Name", text: $viewModel.name)
                        .onChange(of: viewModel.name) { newValue in
                            localExercise.name = newValue
                            viewModel.updateSuggestions(for: newValue)
                        }
                        .foregroundColor(viewModel.textColor)
                        .shadow(color: .blue.opacity(viewModel.glowOpacity), radius: 2, x: 0, y: 0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.textColor)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.glowOpacity)
                    
                    if viewModel.showSuggestions && !viewModel.suggestions.isEmpty {
                        Text("Suggested Matches")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                    SuggestionButton(suggestion: suggestion) {
                                        viewModel.animateTextSelection(suggestion)
                                    }
                                }
                            }
                        }
                        .frame(height: 40)
                    }
                }
                .animation(.easeInOut, value: viewModel.showSuggestions)
            }
        }
    private var setsSection: some View {
        Section(header: Text("Sets")) {
            ForEach(localExercise.sets.indices, id: \.self) { index in
                HStack {
                    Text("Set \(index + 1)")
                    Spacer()
                    Text(WeightUtils.formatWeight(localExercise.sets[index].weight, unit: weightUnit))
                    Text("\(localExercise.sets[index].reps) reps")
                }
            }
            .onDelete(perform: deleteSets)
            
            Button(action: {
                showingSetPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add/Edit Sets")
                }
            }
        }
        }
    
    private var notesSection: some View {
        Section(header: Text("Notes")) {
            TextEditor(text: $localExercise.notes)
                .frame(height: 100)
        }
    }
    
    private var mediaAttachmentsSection: some View {
        Section(header: Text("Media Attachments")) {
            if !localExercise.mediaAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(localExercise.mediaAttachments) { attachment in
                            MediaThumbnail(attachment: attachment)
                        }
                    }
                    .frame(height: 100)
                    .padding(.vertical, 8)
                }
            }
            
            Button(action: {
                showingMediaPicker = true
            }) {
                HStack {
                    Image(systemName: "photo")
                    Text("Add Media")
                }
            }
            
            Button(action: {
                showingCamera = true
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo or Video")
                }
            }
        }
    }
    
    private var deleteExerciseSection: some View {
        Section {
            Button(action: {
                withAnimation {
                    showingDeleteAlert = true
                }
            }) {
                Text("Delete Exercise")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func animateTextSelection(_ suggestion: String) {
            isAnimating = true
            withAnimation {
                showSuggestions = false
                textColor = .blue
                glowOpacity = 1
            }
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            
            for (index, _) in suggestion.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    localExercise.name = String(suggestion.prefix(index + 1))
                    impact.impactOccurred()
                    
                    if index == suggestion.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isAnimating = false
                                textColor = .primary
                                glowOpacity = 0
                            }
                        }
                    }
                }
            }
        }
    
    private func showCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.showingCamera = true
                    }
                } else {
                    self.showCameraAccessDeniedAlert()
                }
            }
        case .denied, .restricted:
            showCameraAccessDeniedAlert()
        @unknown default:
            break
        }
    }


    private func showCameraAccessDeniedAlert() {
        alertMessage = "Camera access is required to take photos. Please enable it in Settings."
        showAlert = true
    }

 
    private func updateSuggestions(for input: String) {
        guard !input.isEmpty else {
            viewModel.suggestions = []
            withAnimation {
                viewModel.showSuggestions = false
            }
            return
        }
        
        viewModel.suggestions = viewModel.allExerciseNames.filter { $0.lowercased().hasPrefix(input.lowercased()) }
        withAnimation {
            viewModel.showSuggestions = !viewModel.suggestions.isEmpty
        }
    }
    
    private static func getAllUniqueExerciseNames(from workouts: [Date: [ExerciseLog]]) -> [String] {
        var exerciseNames = Set<String>()
        for exercises in workouts.values {
            for exercise in exercises {
                exerciseNames.insert(exercise.name)
            }
        }
        return Array(exerciseNames)
    }
    
    private static func getAllExerciseNames(from workouts: [Date: [ExerciseLog]]) -> [String] {
        var exerciseNames = Set<String>()
        for exercises in workouts.values {
            for exercise in exercises {
                exerciseNames.insert(exercise.name)
            }
        }
        return Array(exerciseNames)
    }
    
    private func handleSelectedItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        saveMedia(uiImage.jpegData(compressionQuality: 0.8), type: .image)
                    }
                } else {
                    await MainActor.run {
                        saveMedia(data, type: .video)
                    }
                }
            }
        }
        await MainActor.run {
            selectedItems.removeAll()
        }
    }
    
    private func loadCameraMedia() {
        if let inputImage = inputImage {
            saveMedia(inputImage.jpegData(compressionQuality: 0.8), type: .image)
        } else if let inputVideo = inputVideo {
            if let videoData = try? Data(contentsOf: inputVideo) {
                saveMedia(videoData, type: .video)
            }
        }
    }
    
    private func saveExercise() {
        // Convert weights to pounds before saving
        let updatedLocalExercise = ExerciseLog(
            id: localExercise.id,
            name: localExercise.name,
            sets: localExercise.sets.map { set in
                SetLog(
                    id: set.id,
                    weight: WeightUtils.convert(set.weight, from: weightUnit, to: .pounds),
                    reps: set.reps
                )
            },
            notes: localExercise.notes,
            mediaAttachments: localExercise.mediaAttachments,
            date: localExercise.date
        )

        var updatedWorkouts = workouts
        if var exercisesForDate = updatedWorkouts[selectedDate] {
            if let index = exercisesForDate.firstIndex(where: { $0.id == updatedLocalExercise.id }) {
                exercisesForDate[index] = updatedLocalExercise
            } else {
                exercisesForDate.append(updatedLocalExercise)
            }
            updatedWorkouts[selectedDate] = exercisesForDate
        } else {
            updatedWorkouts[selectedDate] = [updatedLocalExercise]
        }
        
        workouts = updatedWorkouts
        exercise = updatedLocalExercise
        
        let stringKeyedWorkouts = updatedWorkouts.reduce(into: [String: [ExerciseLog]]()) { result, element in
            let dateString = element.key.toString()
            result[dateString] = element.value
        }
        FileStorage.save(stringKeyedWorkouts)
        
        presentationMode.wrappedValue.dismiss()
    }

    private func saveMedia(_ data: Data?, type: MediaAttachment.MediaType) {
        guard let data = data,
              let url = FileStorage.saveMedia(data, with: UUID(), type: type) else { return }
        let attachment = MediaAttachment(url: url, type: type)
        localExercise.mediaAttachments.append(attachment)
        
        updateWorkout()
    }
    
    private func updateWorkout() {
        var updatedWorkouts = workouts
        
        if var exercisesForDate = updatedWorkouts[selectedDate] {
            if let index = exercisesForDate.firstIndex(where: { $0.id == localExercise.id }) {
                exercisesForDate[index] = localExercise
            } else {
                exercisesForDate.append(localExercise)
            }
            updatedWorkouts[selectedDate] = exercisesForDate
        } else {
            updatedWorkouts[selectedDate] = [localExercise]
        }
        
        workouts = updatedWorkouts
        exercise = localExercise
        
        let stringKeyedWorkouts = updatedWorkouts.toStringKeys()
        FileStorage.save(stringKeyedWorkouts)
    }
    
    private func deleteExercise() {
        var updatedWorkouts = workouts
        updatedWorkouts[selectedDate]?.removeAll(where: { $0.id == localExercise.id })
        
        workouts = updatedWorkouts
        
        let stringKeyedWorkouts = updatedWorkouts.toStringKeys()
        FileStorage.save(stringKeyedWorkouts)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteSets(at offsets: IndexSet) {
        localExercise.sets.remove(atOffsets: offsets)
    }
}



struct SetPickerView: View {
    @Binding var sets: [SetLog]
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("weightUnit") private var weightUnit = WeightUnit.pounds
    @State private var currentSetIndex = 0
    @State private var tempWeight: Double = 0
    @State private var tempReps: Int = 0

    init(sets: Binding<[SetLog]>) {
        self._sets = sets
        if sets.wrappedValue.isEmpty {
            sets.wrappedValue.append(SetLog(weight: 0, reps: 0))
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            topBar
            pickerSection
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    private var topBar: some View {
        HStack {
            cancelButton
            Spacer()
            setIndicators
            Spacer()
            saveButton
        }
        .padding(.horizontal)
    }

    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private var saveButton: some View {
        Button("Save") {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private var setIndicators: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Spacer()
                    ForEach(0..<sets.count, id: \.self) { index in
                        setIndicator(for: index)
                    }
                    addSetButton
                    Spacer()
                }
            }
            .frame(height: 40)
            .onAppear {
                proxy.scrollTo(currentSetIndex, anchor: .center)
            }
        }
    }

    private func setIndicator(for index: Int) -> some View {
        Circle()
            .fill(index == currentSetIndex ? Color.blue : Color.gray)
            .frame(width: 30, height: 30)
            .overlay(Text("\(index + 1)").foregroundColor(.white))
            .onTapGesture {
                currentSetIndex = index
                tempWeight = sets[index].weight
                tempReps = sets[index].reps
            }
            .id(index)
    }

    private var addSetButton: some View {
        Button(action: addNewSet) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .font(.title)
        }
    }

    private var pickerSection: some View {
        HStack {
            weightPicker
            repsPicker
        }
        .onChange(of: tempWeight) { newValue in
            let weightInPounds = WeightUtils.convert(newValue, from: weightUnit, to: .pounds)
            sets[currentSetIndex].weight = weightInPounds
        }
        .onChange(of: tempReps) { newValue in
            sets[currentSetIndex].reps = newValue
        }
        
        .onAppear {
            if !sets.isEmpty {
                tempWeight = sets[currentSetIndex].weightInPreferredUnit(weightUnit)
                tempReps = sets[currentSetIndex].reps
            }
        }
        
    }

    private var weightPicker: some View {
        Picker("Weight", selection: $tempWeight) {
            ForEach(0...1000, id: \.self) { w in
                Text("\(w) \(weightUnit == .pounds ? "lbs" : "kg")").tag(Double(w))
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(width: 100)
    }


    private var repsPicker: some View {
        Picker("Reps", selection: $tempReps) {
            ForEach(0...100, id: \.self) { r in
                Text("\(r)").tag(r)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(width: 100)
    }

    private func addNewSet() {
        sets.append(SetLog(weight: 0, reps: 0))
        currentSetIndex = sets.count - 1
        tempWeight = 0
        tempReps = 0
    }
}

struct MediaAttachmentsView: View {
    let attachments: [MediaAttachment]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(attachments) { attachment in
                    MediaThumbnail(attachment: attachment)
                }
            }
            .frame(height: 100)
            .padding(.vertical, 8)
        }
    }
}

struct MediaButtonsView: View {
    let onAddMedia: () -> Void
    let onTakePhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onAddMedia) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Add Media")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            Button(action: onTakePhoto) {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo or Video")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.vertical, 8)
    }
}

struct SuggestionButton: View {
    let suggestion: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            Text(suggestion)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.blue.opacity(0.1)))
                .foregroundColor(.blue)
        }
        .scaleEffect(isPressed ? 0.95 : 1)
    }
}

struct MediaThumbnail: View {
    let attachment: MediaAttachment
    @State private var isShowingFullScreen = false
    
    var body: some View {
        Button(action: {
            isShowingFullScreen = true
        }) {
            if attachment.type == .image {
                AsyncImage(url: attachment.url) {
                    ProgressView()
                }
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                VideoThumbnail(url: attachment.url)
            }
        }
        .fullScreenCover(isPresented: $isShowingFullScreen) {
            MediaViewer(attachment: attachment)
        }
    }
    struct VideoThumbnail: View {
        let url: URL
        @State private var thumbnail: UIImage?
        
        var body: some View {
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "video")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .background(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onAppear(perform: loadThumbnail)
        }
        
        private func loadThumbnail() {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _, image, _, _, _ in
                if let image = image {
                    DispatchQueue.main.async {
                        self.thumbnail = UIImage(cgImage: image)
                    }
                }
            }
        }
    }
    
    struct MediaViewer: View {
        let attachment: MediaAttachment
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if attachment.type == .image {
                    if let image = UIImage(contentsOfFile: attachment.url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    VideoPlayer(player: AVPlayer(url: attachment.url))
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }
}
