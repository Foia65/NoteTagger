import SwiftUI

struct RecordingsListView: View {
    @EnvironmentObject var recorder: AudioRecorderManager
    @State private var editingRecordingID: UUID?
    @State private var editingTitle = ""
    @State private var showRenameAlert = false
    @State private var renameRecording: Recording?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                Group {
                    if recorder.recordings.isEmpty {
                        ContentUnavailableView(
                            String(localized: "empty_recordings_title"),
                            systemImage: "waveform",
                            description: Text(String(localized: "empty_recordings_description"))
                        )
                    } else {
                        List {
                            ForEach(recorder.recordings) { recording in
                                NavigationLink(value: recording) {
                                    RecordingRowView(
                                        recording: recording,
                                        isEditing: editingRecordingID == recording.id,
                                        editingTitle: $editingTitle,
                                        onStartEdit: {
                                            editingRecordingID = recording.id
                                            editingTitle = recording.title
                                        },
                                        onCommitEdit: {
                                            recorder.updateRecordingTitle(recording.id, newTitle: editingTitle)
                                            editingRecordingID = nil
                                        }
                                    )
                                }
                                .listRowBackground(Color.darkSurface)
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        ShareCoordinator.shareRecording(recording)
                                    } label: {
                                        Label(String(localized: "action_share"), systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.accentVivid)

                                    Button {
                                        renameRecording = recording
                                        editingTitle = recording.title
                                        showRenameAlert = true
                                    } label: {
                                        Label(String(localized: "action_rename"), systemImage: "pencil")
                                    }
                                    .tint(.indigo)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        recorder.deleteRecording(recording)
                                    } label: {
                                        Label(String(localized: "action_delete"), systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        ShareCoordinator.shareRecording(recording)
                                    } label: {
                                        Label(String(localized: "action_share"), systemImage: "square.and.arrow.up")
                                    }

                                    Button {
                                        renameRecording = recording
                                        editingTitle = recording.title
                                        showRenameAlert = true
                                    } label: {
                                        Label(String(localized: "action_rename"), systemImage: "pencil")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        recorder.deleteRecording(recording)
                                    } label: {
                                        Label(String(localized: "action_delete"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(String(localized: "recordings_title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Recording.self) { recording in
                PlaybackView(recording: recording)
                    .environmentObject(recorder)
            }
            .alert(String(localized: "rename_alert_title"), isPresented: $showRenameAlert) {
                TextField(String(localized: "recording_name_placeholder"), text: $editingTitle)
                Button(String(localized: "rename_save")) {
                    if let rec = renameRecording {
                        recorder.updateRecordingTitle(rec.id, newTitle: editingTitle)
                    }
                    renameRecording = nil
                }
                Button(String(localized: "tag_cancel"), role: .cancel) {
                    renameRecording = nil
                }
            } message: {
                Text(String(localized: "rename_alert_message"))
            }
        }
        .tint(.accentVivid)
    }
}

struct RecordingRowView: View {
    let recording: Recording
    let isEditing: Bool
    @Binding var editingTitle: String
    let onStartEdit: () -> Void
    let onCommitEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditing {
                TextField(String(localized: "recording_name_placeholder"), text: $editingTitle)
                    .textFieldStyle(.roundedBorder)
                    .colorScheme(.dark)
                    .onSubmit {
                        onCommitEdit()
                    }
            } else {
                Text(recording.title)
                    .font(.headline)
                    .foregroundStyle(.teal)
                    .onTapGesture(count: 2) {
                        onStartEdit()
                    }
            }

            HStack {
                Label(recording.formattedDuration, systemImage: "clock")
                Text("•")
                    .foregroundStyle(Color.darkTertiary)
                Label(recording.formattedFileSize, systemImage: "doc")
                Spacer()
                if !recording.bookmarks.isEmpty {
                    Label("\(recording.bookmarks.count)", systemImage: "bookmark.fill")
                        .foregroundStyle(Color.tagOrange)
                }
            }
            .font(.caption)
            .foregroundStyle(Color.darkSecondary)

            HStack {
                Label(recording.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.darkTertiary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let manager = AudioRecorderManager()
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let recordingsDir = docs.appendingPathComponent("Recordings", isDirectory: true)
    try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

    let sampleURL1 = recordingsDir.appendingPathComponent("sample1.m4a")
    let sampleURL2 = recordingsDir.appendingPathComponent("sample2.m4a")
    let sampleURL3 = recordingsDir.appendingPathComponent("sample3.m4a")
    FileManager.default.createFile(atPath: sampleURL1.path, contents: Data(count: 12_400_000))
    FileManager.default.createFile(atPath: sampleURL2.path, contents: Data(count: 5_800_000))
    FileManager.default.createFile(atPath: sampleURL3.path, contents: Data(count: 920_000))

    manager.recordings = [
        Recording(
            title: "Lezione di Fisica",
            fileURL: sampleURL1,
            duration: 3724,
            createdAt: Date().addingTimeInterval(-3600),
            bookmarks: [
                Bookmark(title: "Domanda Esame", timestamp: 252),
                Bookmark(title: "Formula importante", timestamp: 1200),
                Bookmark(title: "Esercizio 3", timestamp: 2890)
            ]
        ),
        Recording(
            title: "Riunione di progetto",
            fileURL: sampleURL2,
            duration: 1800,
            createdAt: Date().addingTimeInterval(-86400),
            bookmarks: [
                Bookmark(title: "Deadline Q3", timestamp: 420),
                Bookmark(title: "Budget approvato", timestamp: 1350)
            ]
        ),
        Recording(
            title: "Pensieri vari",
            fileURL: sampleURL3,
            duration: 305,
            createdAt: Date().addingTimeInterval(-172800),
            bookmarks: []
        )
    ]

    return RecordingsListView()
        .environmentObject(manager)
        .preferredColorScheme(.dark)
}
