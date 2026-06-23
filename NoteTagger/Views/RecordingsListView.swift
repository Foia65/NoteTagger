import SwiftUI

private enum SortOption: String, CaseIterable, Identifiable {
    case date = "sort_date"
    case title = "sort_title"
    case duration = "sort_duration"
    case size = "sort_size"
    case bookmarks = "sort_bookmarks"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .date: return "calendar"
        case .title: return "textformat.abc"
        case .duration: return "clock"
        case .size: return "doc"
        case .bookmarks: return "bookmark.fill"
        }
    }
}

struct RecordingsListView: View {
    @EnvironmentObject var recorder: AudioRecorderManager
    @State private var editingRecordingID: UUID?
    @State private var editingTitle = ""
    @State private var showRenameAlert = false
    @State private var renameRecording: Recording?
    @AppStorage("recordings_sort_option") private var sortOptionRaw: String = SortOption.date.rawValue
    @AppStorage("recordings_sort_ascending") private var sortAscending = false

    private var sortOption: SortOption { SortOption(rawValue: sortOptionRaw) ?? .date }

    private var sortedRecordings: [Recording] {
        recorder.recordings.sorted { a, b in
            let result: Bool
            switch sortOption {
            case .date:
                result = a.createdAt < b.createdAt
            case .title:
                result = a.title.localizedStandardCompare(b.title) == .orderedAscending
            case .duration:
                result = a.duration < b.duration
            case .size:
                result = a.fileSize < b.fileSize
            case .bookmarks:
                result = a.bookmarks.count < b.bookmarks.count
            }
            return sortAscending ? result : !result
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                Group {
                    if recorder.recordings.isEmpty {
                        ContentUnavailableView(
                            "empty_recordings_title",
                            systemImage: "waveform",
                            description: Text("empty_recordings_description")
                        )
                    } else {
                        VStack {
                            if recorder.recordings.count > 1 {
                                    HStack(spacing: 12) {
                                        Menu {
                                            Picker("sort_by", selection: Binding(get: { SortOption(rawValue: sortOptionRaw) ?? .date }, set: { sortOptionRaw = $0.rawValue })) {
                                                ForEach(SortOption.allCases) { option in
                                                    Label(LocalizedStringKey(option.rawValue), systemImage: option.systemImage).tag(option)
                                                }
                                            }
                                            
                                            Divider()
                                            
                                        } label: {
                                            Label {
                                                // Avoid deprecated Text + Text concatenation — use a small HStack
                                                HStack(spacing: 4) {
                                                    Text("sort_by")
                                                    Text(LocalizedStringKey(sortOption.rawValue))
                                                }
                                            } icon: {
                                                Image(systemName: sortOption.systemImage)
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .id(sortOption) // per risolvere il problema delle label lunghe
                                        
                                        Spacer()
                                        
                                        Button {
                                            withAnimation { sortAscending.toggle() }
                                        } label: {
                                            Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                                        }
                                        .buttonStyle(.bordered)
                                        .accessibilityLabel(Text(sortAscending ? "sort_ascending" : "sort_descending"))
                                    }
                                .listRowBackground(Color.darkSurface)
                                .padding(.horizontal, 16)
                            }
                            
                            List {
                                ForEach(sortedRecordings) { recording in
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
                                            Label("action_share", systemImage: "square.and.arrow.up")
                                        }
                                        .tint(.accentVivid)
                                        
                                        Button {
                                            renameRecording = recording
                                            editingTitle = recording.title
                                            showRenameAlert = true
                                        } label: {
                                            Label("action_rename", systemImage: "pencil")
                                        }
                                        .tint(.indigo)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            recorder.deleteRecording(recording)
                                        } label: {
                                            Label("action_delete", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button {
                                            ShareCoordinator.shareRecording(recording)
                                        } label: {
                                            Label("action_share", systemImage: "square.and.arrow.up")
                                        }
                                        
                                        Button {
                                            renameRecording = recording
                                            editingTitle = recording.title
                                            showRenameAlert = true
                                        } label: {
                                            Label("action_rename", systemImage: "pencil")
                                        }
                                        
                                        Divider()
                                        
                                        Button(role: .destructive) {
                                            recorder.deleteRecording(recording)
                                        } label: {
                                            Label("action_delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: sortedRecordings)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("recordings_title")
                        .font(.headline)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Recording.self) { recording in
                PlaybackView(recording: recording)
                    .environmentObject(recorder)
            }
            .alert("rename_alert_title", isPresented: $showRenameAlert) {
                TextField("recording_name_placeholder", text: $editingTitle)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    Button("rename_save") {
                    if let rec = renameRecording {
                        recorder.updateRecordingTitle(rec.id, newTitle: editingTitle)
                    }
                    renameRecording = nil
                }
                Button("tag_cancel", role: .cancel) {
                    renameRecording = nil
                }
            } message: {
                Text("rename_alert_message")
            }
            .onChange(of: showRenameAlert) { _, isPresented in
                if isPresented {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        selectAllTextInAlert()
                    }
                }
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
                TextField("recording_name_placeholder", text: $editingTitle)
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
    // Build a configured manager inside a closure so the preview block's final expression is the View
    let manager: AudioRecorderManager = {
        let configuredManager = AudioRecorderManager()
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = docs.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        let sampleURL1 = recordingsDir.appendingPathComponent("sample1.m4a")
        let sampleURL2 = recordingsDir.appendingPathComponent("sample2.m4a")
        let sampleURL3 = recordingsDir.appendingPathComponent("sample3.m4a")
        FileManager.default.createFile(atPath: sampleURL1.path, contents: Data(count: 12_400_000))
        FileManager.default.createFile(atPath: sampleURL2.path, contents: Data(count: 5_800_000))
        FileManager.default.createFile(atPath: sampleURL3.path, contents: Data(count: 920_000))

        configuredManager.recordings = [
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

        return configuredManager
    }()

    RecordingsListView()
        .environmentObject(manager)
        .preferredColorScheme(.dark)
}
