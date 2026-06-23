import AVFoundation
import Combine

enum RecordingState {
    case idle
    case recording
    case paused
}

@MainActor
final class AudioRecorderManager: NSObject, ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var currentTime: TimeInterval = 0
    @Published var currentRecording: Recording?
    @Published var recordings: [Recording] = []
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingSession: AVAudioSession { AVAudioSession.sharedInstance() }

    private let recordingsDirectory: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let recordingsIndexURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("recordings.json")
    }()

    override init() {
        super.init()
        loadRecordings()
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            recordingSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() async {
        let hasPermission = await requestPermission()
        guard hasPermission else {
            errorMessage = String(localized: "error_microphone_permission")
            return
        }

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)

            let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
            let fileURL = recordingsDirectory.appendingPathComponent(fileName)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            let title = localizedAppString("default_recording_title")
            currentRecording = Recording(title: title, fileURL: fileURL)
            state = .recording
            currentTime = 0
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        state = .idle

        guard var recording = currentRecording else { return }
        recording.duration = currentTime

        if recording.duration < 1 {
            try? FileManager.default.removeItem(at: recording.fileURL)
            currentRecording = nil
            currentTime = 0
            return
        }

        recordings.insert(recording, at: 0)
        saveRecordings()
        currentRecording = nil
        currentTime = 0
    }

    func addBookmark(title: String = "") {
        guard state == .recording else { return }
        let bookmark = Bookmark(title: title, timestamp: currentTime)
        currentRecording?.bookmarks.append(bookmark)
    }

    func deleteRecording(_ recording: Recording) {
        try? FileManager.default.removeItem(at: recording.fileURL)
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }

    func deleteBookmark(from recordingID: UUID, bookmarkID: UUID) {
        guard let index = recordings.firstIndex(where: { $0.id == recordingID }) else { return }
        recordings[index].bookmarks.removeAll { $0.id == bookmarkID }
        saveRecordings()
    }

    func updateRecordingTitle(_ recordingID: UUID, newTitle: String) {
        guard let index = recordings.firstIndex(where: { $0.id == recordingID }) else { return }
        recordings[index].title = newTitle
        saveRecordings()
    }

    func updateBookmarkTitle(_ recordingID: UUID, bookmarkID: UUID, newTitle: String) {
        guard let recIndex = recordings.firstIndex(where: { $0.id == recordingID }) else { return }
        guard let bmIndex = recordings[recIndex].bookmarks.firstIndex(where: { $0.id == bookmarkID }) else { return }
        recordings[recIndex].bookmarks[bmIndex].title = newTitle
        saveRecordings()
    }

    func bookmarkURL(for recording: Recording) -> URL {
        recording.fileURL
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let recorder = self.audioRecorder, recorder.isRecording {
                    self.currentTime = recorder.currentTime
                }
            }
        }
    }

    private func loadRecordings() {
        guard let data = try? Data(contentsOf: recordingsIndexURL),
              let decoded = try? JSONDecoder().decode([Recording].self, from: data) else {
            return
        }
        recordings = decoded.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
    }

    private func saveRecordings() {
        guard let data = try? JSONEncoder().encode(recordings) else { return }
        try? data.write(to: recordingsIndexURL)
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ _: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                self.errorMessage = String(localized: "error_recording_failed")
            }
        }
    }
}
