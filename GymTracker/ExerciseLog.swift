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
    
    init(id: UUID = UUID(), url: URL, type: MediaType) {
        self.id = id
        self.url = url
        self.type = type
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let urlString = try container.decode(String.self, forKey: .url)
        url = URL(fileURLWithPath: urlString)
        type = try container.decode(MediaType.self, forKey: .type)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url.path, forKey: .url)
        try container.encode(type, forKey: .type)
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

