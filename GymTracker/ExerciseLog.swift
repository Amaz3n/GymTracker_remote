// ExerciseLog.swift
import Foundation

struct MediaAttachment: Codable, Identifiable, Equatable {
    var id: UUID
    var url: URL
    var type: MediaType
    
    enum MediaType: String, Codable, Equatable {
        case image
        case video
    }
    
    static func == (lhs: MediaAttachment, rhs: MediaAttachment) -> Bool {
        lhs.id == rhs.id &&
        lhs.url == rhs.url &&
        lhs.type == rhs.type
    }
}
struct SetLog: Codable, Identifiable, Equatable {
    var id: UUID
    var weight: Double
    var reps: Int
    
    init(id: UUID = UUID(), weight: Double, reps: Int) {
        self.id = id
        self.weight = weight
        self.reps = reps
    }
    
    func weightInPreferredUnit(_ unit: WeightUnit) -> Double {
        switch unit {
        case .pounds:
            return weight
        case .kilograms:
            return weight * 0.453592
        }
    }
}

struct ExerciseLog: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var sets: [SetLog]
    var notes: String
    var mediaAttachments: [MediaAttachment]
    var date: Date // Add this line
    
    init(id: UUID = UUID(), name: String, sets: [SetLog] = [], notes: String = "", mediaAttachments: [MediaAttachment] = [], date: Date = Date()) {
        self.id = id
        self.name = name
        self.sets = sets
        self.notes = notes
        self.mediaAttachments = mediaAttachments
        self.date = date // Add this line
    }
    
    static func == (lhs: ExerciseLog, rhs: ExerciseLog) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.sets == rhs.sets &&
        lhs.notes == rhs.notes &&
        lhs.mediaAttachments == rhs.mediaAttachments &&
        lhs.date == rhs.date // Add this line
    }
}

