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
                        Image(systemName: "mic.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
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
                                    Text(String(localized: "button_tag"))
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
                                    Text(String(localized: "button_stop"))
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
                                Text(String(localized: "button_record"))
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
          //  .navigationTitle(String(localized: "record_title"))
            .navigationBarTitleDisplayMode(.large)
            .alert(String(localized: "tag_alert_title"), isPresented: $showTagSheet) {
                TextField(String(localized: "tag_placeholder"), text: $tagText)
                Button(String(localized: "tag_save")) {
                    recorder.addBookmark(title: tagText)
                }
                Button(String(localized: "tag_cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "tag_alert_message"))
            }
            .alert(String(localized: "error_title"), isPresented: .init(
                get: { recorder.errorMessage != nil },
                set: { if !$0 { recorder.errorMessage = nil } }
            )) {
                Button(String(localized: "ok"), role: .cancel) {}
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
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.green)
                .contentTransition(.numericText())

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.recordRed)
                    .frame(width: 12, height: 12)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: currentTime)
                Text(String(localized: "recording_in_progress"))
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

#Preview {
    RecordingTimerView(currentTime: 252)
        .preferredColorScheme(.dark)
}
