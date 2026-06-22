import SwiftUI

struct RecordView: View {
    @EnvironmentObject var recorder: AudioRecorderManager
    @State private var showTagSheet = false
    @State private var tagText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    if recorder.state == .recording {
                        RecordingTimerView(currentTime: recorder.currentTime)
                    } else {
                        Image("pro_microphone")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .foregroundStyle(Color.darkSecondary)
                    }

                    if recorder.state == .recording {
                        VStack(spacing: 24) {
                            Button {
                                tagText = ""
                                showTagSheet = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 40))
                                    Text("button_tag")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(Color.tagOrange.gradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)

                            Button {
                                recorder.stopRecording()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 40))
                                    Text("button_stop")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(Color.stopRed.gradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button {
                            Task {
                                await recorder.startRecording()
                            }
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "record.circle.fill")
                                    .font(.system(size: 60))
                                Text("button_record")
                                    .font(.title2.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .background(Color.recordRed.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 32)
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .alert("tag_alert_title", isPresented: $showTagSheet) {
                TextField("tag_placeholder", text: $tagText)
                Button("tag_save") {
                    recorder.addBookmark(title: tagText)
                }
                Button("tag_cancel", role: .cancel) {}
            } message: {
                Text("tag_alert_message")
            }
            .alert("error_title", isPresented: .init(
                get: { recorder.errorMessage != nil },
                set: { if !$0 { recorder.errorMessage = nil } }
            )) {
                Button("ok", role: .cancel) {}
            } message: {
                if let error = recorder.errorMessage {
                    Text(error)
                }
            }
        }
        .tint(.accentVivid)
    }
}

struct RecordingTimerView: View {
    let currentTime: TimeInterval

    var body: some View {
        VStack(spacing: 8) {
            Text(formattedTime)
                .font(.custom("DigitalDismay", size: 100))
                .foregroundStyle(Color.green)
                .contentTransition(.numericText())

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.recordRed)
                    .frame(width: 12, height: 12)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: currentTime)
                Text("recording_in_progress")
                    .font(.subheadline)
                    .foregroundStyle(Color.darkSecondary)
            }
        }
    }

    private var formattedTime: String {
        let totalSeconds = Int(currentTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview("Timer") {
    RecordingTimerView(currentTime: 252)
        .preferredColorScheme(.dark)
}

#Preview("Record") {
    RecordView()
        .environmentObject(AudioRecorderManager())
        .preferredColorScheme(.dark)
}
