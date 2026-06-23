import AVFoundation
import Combine
import SwiftUI

struct PlaybackView: View {
    @EnvironmentObject var recorder: AudioRecorderManager
    @StateObject private var playerManager: AudioPlayerManager
    @State private var editingBookmarkID: UUID?
    @State private var editingBookmarkTitle = ""
    @State private var showRenameBookmarkAlert = false
    @State private var renameBookmark: Bookmark?
    @State private var showAddBookmarkAlert = false
    @State private var newBookmarkTitle = ""
    @Environment(\.dismiss) private var dismiss

    init(recording: Recording) {
        _playerManager = StateObject(wrappedValue: AudioPlayerManager(recording: recording))
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text(playerManager.recording.title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text(playerManager.recording.formattedDate)
                        .font(.caption)
                        .foregroundStyle(Color.darkSecondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)

                PlaybackProgressView(playerManager: playerManager)
                PlaybackControlsView(playerManager: playerManager)

                Divider()
                    .background(Color.darkBorder)
                    .padding(.horizontal)

                BookmarksListView(
                    bookmarks: playerManager.recording.bookmarks,
                    editingBookmarkID: $editingBookmarkID,
                    editingBookmarkTitle: $editingBookmarkTitle,
                    onSeek: { timestamp in playerManager.seek(to: timestamp) },
                    onUpdateTitle: { bookmarkID, newTitle in
                        recorder.updateBookmarkTitle(playerManager.recording.id, bookmarkID: bookmarkID, newTitle: newTitle)
                        playerManager.refreshRecording(from: recorder)
                    },
                    onDelete: { bookmarkID in
                        recorder.deleteBookmark(from: playerManager.recording.id, bookmarkID: bookmarkID)
                        playerManager.refreshRecording(from: recorder)
                    },
                    onRequestRename: { bookmark in
                        renameBookmark = bookmark
                        editingBookmarkTitle = bookmark.title
                        showRenameBookmarkAlert = true
                    },
                    onAddBookmark: {
                        newBookmarkTitle = ""
                        showAddBookmarkAlert = true
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ShareCoordinator.shareRecording(
                        title: playerManager.recording.title,
                        fileURL: playerManager.recording.fileURL,
                        bookmarks: playerManager.recording.bookmarks
                    )
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onDisappear { playerManager.stop() }
        .alert("rename_bookmark_alert_title", isPresented: $showRenameBookmarkAlert) {
            TextField("tag_placeholder", text: $editingBookmarkTitle)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            Button("rename_save") {
                if let bookmark = renameBookmark {
                    recorder.updateBookmarkTitle(playerManager.recording.id, bookmarkID: bookmark.id, newTitle: editingBookmarkTitle)
                    playerManager.refreshRecording(from: recorder)
                }
                renameBookmark = nil
            }
            Button("tag_cancel", role: .cancel) {
                renameBookmark = nil
            }
        } message: {
            Text("rename_bookmark_alert_message")
        }
        .onChange(of: showRenameBookmarkAlert) { _, isPresented in
            if isPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    selectAllTextInAlert()
                }
            }
        }
        .alert("tag_alert_title", isPresented: $showAddBookmarkAlert) {
            TextField("tag_placeholder", text: $newBookmarkTitle)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                Button("tag_save") {
                recorder.addBookmark(to: playerManager.recording.id, title: newBookmarkTitle, timestamp: playerManager.currentTime)
                playerManager.refreshRecording(from: recorder)
            }
            Button("tag_cancel", role: .cancel) {}
        } message: {
            Text("tag_alert_message")
        }
        .onChange(of: showAddBookmarkAlert) { _, isPresented in
            if isPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    selectAllTextInAlert()
                }
            }
        }
        .tint(Color.accentVivid)
    }
}

struct PlaybackProgressView: View {
    @ObservedObject var playerManager: AudioPlayerManager

    var body: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { playerManager.currentTime },
                    set: { playerManager.seek(to: $0) }
                ),
                in: 0...max(playerManager.duration, 1)
            )
            .tint(Color.accentVivid)
            .padding(.horizontal, 24)

            HStack {
                Text(formatTime(playerManager.currentTime))
                Spacer()
                Text(formatTime(playerManager.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(Color.darkSecondary)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PlaybackControlsView: View {
    @ObservedObject var playerManager: AudioPlayerManager

    var body: some View {
        VStack(spacing: 12) {
            Button {
                let currentIndex = AudioPlayerManager.availableRates.firstIndex(of: playerManager.rate) ?? 2
                let nextIndex = (currentIndex + 1) % AudioPlayerManager.availableRates.count
                playerManager.rate = AudioPlayerManager.availableRates[nextIndex]
            } label: {
                Text(rateLabel)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.accentVivid)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.darkCard)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            HStack(spacing: 40) {
                Button {
                    playerManager.seek(to: max(0, playerManager.currentTime - 15))
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title)
                }
                .buttonStyle(.plain)

                Button {
                    playerManager.togglePlayPause()
                } label: {
                    Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                .buttonStyle(.plain)

                Button {
                    playerManager.seek(to: min(playerManager.duration, playerManager.currentTime + 15))
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Color.accentVivid)
        }
        .padding(.vertical, 16)
    }

    private var rateLabel: String {
        if playerManager.rate == 1.0 {
            return "1×"
        }
        return String(format: "%.2g×", playerManager.rate)
    }
}

struct BookmarksListView: View {
    let bookmarks: [Bookmark]
    @Binding var editingBookmarkID: UUID?
    @Binding var editingBookmarkTitle: String
    let onSeek: (TimeInterval) -> Void
    let onUpdateTitle: (UUID, String) -> Void
    let onDelete: (UUID) -> Void
    let onRequestRename: (Bookmark) -> Void
    let onAddBookmark: () -> Void

    var body: some View {
        List {
            Section(
                header: HStack {
                    if !bookmarks.isEmpty {
                        Text("bookmarks_header")
                            .foregroundStyle(Color.darkSecondary)
                    }
                    Spacer()
                    Button {
                        onAddBookmark()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.tagOrange)
                    }
                    .accessibilityLabel(Text("add_bookmark_button"))
                }
            ) {
                if bookmarks.isEmpty {
                    ContentUnavailableView(
                        "empty_bookmarks_title",
                        systemImage: "bookmark",
                        description: Text("empty_bookmarks_description")
                    )
                }
                ForEach(bookmarks.sorted(by: { $0.timestamp < $1.timestamp })) { bookmark in
                    BookmarkRowView(
                        bookmark: bookmark,
                        isEditing: editingBookmarkID == bookmark.id,
                        editingTitle: $editingBookmarkTitle,
                        onTap: { onSeek(bookmark.timestamp) },
                        onStartEdit: {
                            editingBookmarkID = bookmark.id
                            editingBookmarkTitle = bookmark.title
                        },
                        onCommitEdit: {
                            onUpdateTitle(bookmark.id, editingBookmarkTitle)
                            editingBookmarkID = nil
                        }
                    )
                    .listRowBackground(Color.darkSurface)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            onRequestRename(bookmark)
                        } label: {
                            Label("action_rename", systemImage: "pencil")
                        }
                        .tint(.indigo)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDelete(bookmark.id)
                        } label: {
                            Label("action_delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            onRequestRename(bookmark)
                        } label: {
                            Label("action_rename", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete(bookmark.id)
                        } label: {
                            Label("action_delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    let sorted = bookmarks.sorted(by: { $0.timestamp < $1.timestamp })
                    for index in indexSet {
                        onDelete(sorted[index].id)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }
}

struct BookmarkRowView: View {
    let bookmark: Bookmark
    let isEditing: Bool
    @Binding var editingTitle: String
    let onTap: () -> Void
    let onStartEdit: () -> Void
    let onCommitEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("tag_placeholder", text: $editingTitle)
                        .textFieldStyle(.roundedBorder)
                        .colorScheme(.dark)
                        .onSubmit { onCommitEdit() }
                } else {
                    Text(LocalizedStringKey(bookmark.title.isEmpty ? "untitled_bookmark" : bookmark.title))
                        .font(.body)
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            Text(bookmark.formattedTimestamp)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.accentVivid)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing { onTap() }
        }
        .onTapGesture(count: 2) {
            if !isEditing { onStartEdit() }
        }
    }
}

@MainActor
final class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var recording: Recording
    @Published var rate: Float = 1.0 {
        didSet {
            audioPlayer?.rate = rate
        }
    }

    static let availableRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    init(recording: Recording) {
        self.recording = recording
        super.init()
        setupPlayer()
    }

    func setupPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            audioPlayer?.rate = rate
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Failed to setup player: \(error)")
        }
    }

    func togglePlayPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        stopTimer()
    }

    func refreshRecording(from recorder: AudioRecorderManager) {
        if let updated = recorder.recordings.first(where: { $0.id == recording.id }) {
            recording = updated
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ _: AVAudioPlayer, successfully _: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.stopTimer()
        }
    }
}

#Preview {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let recordingsDir = docs.appendingPathComponent("Recordings", isDirectory: true)
    try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

    let sampleURL = recordingsDir.appendingPathComponent("preview.m4a")
    FileManager.default.createFile(atPath: sampleURL.path, contents: Data(count: 1_000_000))

    let recording = Recording(
        title: "Lezione di Fisica",
        fileURL: sampleURL,
        duration: 3724,
        createdAt: Date().addingTimeInterval(-3600),
        bookmarks: [
            Bookmark(title: "Domanda Esame", timestamp: 252),
            Bookmark(title: "Formula importante", timestamp: 1200),
            Bookmark(title: "Esercizio 3", timestamp: 2890)
        ]
    )

    return NavigationStack {
        PlaybackView(recording: recording)
            .environmentObject(AudioRecorderManager())
    }
    .preferredColorScheme(.dark)
}

#Preview("No bookmarks") {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let recordingsDir = docs.appendingPathComponent("Recordings", isDirectory: true)
    try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

    let sampleURL = recordingsDir.appendingPathComponent("preview.m4a")
    FileManager.default.createFile(atPath: sampleURL.path, contents: Data(count: 1_000_000))

    let recording = Recording(
        title: "Lezione di Fisica",
        fileURL: sampleURL,
        duration: 3724,
        createdAt: Date().addingTimeInterval(-3600),
        bookmarks: []
    )

    return NavigationStack {
        PlaybackView(recording: recording)
            .environmentObject(AudioRecorderManager())
    }
    .preferredColorScheme(.dark)}
