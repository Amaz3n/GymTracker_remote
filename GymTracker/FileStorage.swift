import Foundation

struct FileStorage {
    static let workoutsFileName = "workouts.json"
    static let mediaFolderName = "MediaAttachments"
    
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func getWorkoutsFilePath() -> URL {
        getDocumentsDirectory().appendingPathComponent(workoutsFileName)
    }
    
    static func getMediaFolderPath() -> URL {
        getDocumentsDirectory().appendingPathComponent(mediaFolderName)
    }
    
    static func save(_ workouts: [String: [ExerciseLog]]) {
            let url = getWorkoutsFilePath()
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(workouts)
                try data.write(to: url)
                print("Data saved successfully to \(url)")
            } catch {
                print("Error saving data: \(error)")
            }
        }
    
    static func load() -> [String: [ExerciseLog]]? {
        let url = getWorkoutsFilePath()
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var workouts = try decoder.decode([String: [ExerciseLog]].self, from: data)
            
            // Reconstruct file URLs for media attachments
            for (date, exercises) in workouts {
                workouts[date] = exercises.map { exercise in
                    var updatedExercise = exercise
                    updatedExercise.mediaAttachments = exercise.mediaAttachments.map { attachment in
                        var updatedAttachment = attachment
                        updatedAttachment.url = getMediaFolderPath().appendingPathComponent(attachment.url.lastPathComponent)
                        return updatedAttachment
                    }
                    return updatedExercise
                }
            }
            
            print("Data loaded successfully from \(url)")
            return workouts
        } catch {
            print("Error loading data: \(error)")
            return nil
        }
    }
    
    
    static func saveMedia(_ data: Data, with id: UUID, type: MediaAttachment.MediaType) -> URL? {
        let mediaFolder = getMediaFolderPath()
        do {
            try FileManager.default.createDirectory(at: mediaFolder, withIntermediateDirectories: true, attributes: nil)
            let fileExtension = type == .image ? "jpg" : "mp4"
            let fileName = "\(id.uuidString).\(fileExtension)"
            let fileURL = mediaFolder.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving media: \(error)")
            return nil
        }
    }
    
    static func loadMedia(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Error loading media: \(error)")
            return nil
        }
    }
}
