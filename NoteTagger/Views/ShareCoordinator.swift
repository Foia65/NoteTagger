import UIKit
import UniformTypeIdentifiers

struct ShareCoordinator {
    static func shareRecording(_ recording: Recording) {
        let items = makeShareItems(for: recording)
        guard !items.isEmpty else { return }
        presentShareSheet(items: items)
    }

    static func shareRecording(
        title: String,
        fileURL: URL,
        bookmarks: [Bookmark]
    ) {
        var items: [Any] = [namedAudioURL(title: title, sourceURL: fileURL)]
        if !bookmarks.isEmpty {
            items.append(namedTextFile(title: title, bookmarks: bookmarks))
        }
        presentShareSheet(items: items)
    }

    private static func makeShareItems(for recording: Recording) -> [Any] {
        var items: [Any] = [namedAudioURL(title: recording.title, sourceURL: recording.fileURL)]
        if !recording.bookmarks.isEmpty {
            items.append(namedTextFile(title: recording.title, bookmarks: recording.bookmarks))
        }
        return items
    }

    private static func namedAudioURL(title: String, sourceURL: URL) -> URL {
        let sanitized = sanitizeFilename(title)
        let base = sanitized.isEmpty ? "recording" : sanitized
        let tempDir = FileManager.default.temporaryDirectory
        let dest = tempDir.appendingPathComponent("\(base).m4a")
        try? FileManager.default.removeItem(at: dest)
        _ = try? FileManager.default.copyItem(at: sourceURL, to: dest)
        return dest
    }

    private static func namedTextFile(title: String, bookmarks: [Bookmark]) -> URL {
        let sanitized = sanitizeFilename(title)
        let base = sanitized.isEmpty ? "recording" : sanitized
        let tempDir = FileManager.default.temporaryDirectory
        let dest = tempDir.appendingPathComponent("\(base)_bookmarks.txt")
        try? FileManager.default.removeItem(at: dest)
        let text = exportText(title: title, bookmarks: bookmarks)
        try? text.write(to: dest, atomically: true, encoding: .utf8)
        return dest
    }

    private static func sanitizeFilename(_ name: String) -> String {
        var result = name
        let illegal = CharacterSet.illegalCharacters
        let control = CharacterSet.controlCharacters
        let special = CharacterSet(charactersIn: "/\\:?%*|\"<>()")
        for scalar in result.unicodeScalars {
            if illegal.contains(scalar) || control.contains(scalar) {
                result = result.replacingOccurrences(of: String(scalar), with: "")
            } else if special.contains(scalar) {
                result = result.replacingOccurrences(of: String(scalar), with: "_")
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func exportText(title: String, bookmarks: [Bookmark]) -> String {
        var lines: [String] = []
        lines.append(title)
        lines.append(NSLocalizedString("share_export_header", comment: ""))
        lines.append("")

        let sorted = bookmarks.sorted(by: { $0.timestamp < $1.timestamp })
        for bookmark in sorted {
            let bmTitle = bookmark.title.isEmpty
                ? NSLocalizedString("untitled_bookmark", comment: "")
                : bookmark.title
            lines.append("[\(bookmark.formattedTimestamp)] \(bmTitle)")
        }

        return lines.joined(separator: "\n")
    }

    private static func presentShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        presenter.present(controller, animated: true)
    }
}
