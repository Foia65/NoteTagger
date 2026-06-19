import Foundation

struct Bookmark: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var timestamp: TimeInterval
    var createdAt: Date

    init(id: UUID = UUID(), title: String = "", timestamp: TimeInterval, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.createdAt = createdAt
    }

    var formattedTimestamp: String {
        let totalSeconds = Int(timestamp)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
