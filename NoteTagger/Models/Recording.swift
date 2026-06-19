import Foundation

struct Recording: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var fileURL: URL
    var duration: TimeInterval
    var createdAt: Date
    var bookmarks: [Bookmark]

    init(
        id: UUID = UUID(),
        title: String,
        fileURL: URL,
        duration: TimeInterval = 0,
        createdAt: Date = Date(),
        bookmarks: [Bookmark] = []
    ) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.createdAt = createdAt
        self.bookmarks = bookmarks
    }

    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var fileSize: Int64 {
        (try? FileManager.default.attributesOfItem(atPath: fileURL.path))
            .flatMap { $0[.size] as? Int64 } ?? 0
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}
