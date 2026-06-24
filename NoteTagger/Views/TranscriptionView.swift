import SwiftUI

struct TranscriptionView: View {
    let transcription: String?
    let isTranscribing: Bool
    let error: String?
    let onTranscribe: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.darkBorder)
                .padding(.horizontal)

            VStack(spacing: 12) {
                if let transcription, !transcription.isEmpty {
                    if isExpanded {
                        HStack {
                            Text("transcription_header")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.darkSecondary)
                            Spacer()
                            Button {
                                isExpanded = false
                            } label: {
                                Image(systemName: "chevron.up")
                                    .foregroundStyle(Color.darkSecondary)
                            }
                        }
                        .padding(.horizontal, 24)

                        ScrollView {
                            Text(transcription)
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                        }
                        .frame(maxHeight: 200)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                            Text("transcription_complete")
                                .font(.subheadline)
                                .foregroundStyle(Color.darkSecondary)
                            Spacer()
                            Button {
                                isExpanded = true
                            } label: {
                                Text("transcription_show_button")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.accentVivid)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                } else if isTranscribing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(Color.accentVivid)
                        Text("transcription_in_progress")
                            .font(.caption)
                            .foregroundStyle(Color.darkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    Button(action: onTranscribe) {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                            Text("transcription_button")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.accentVivid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.darkCard)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

#Preview("Empty") {
    TranscriptionView(
        transcription: nil,
        isTranscribing: false,
        error: nil,
        onTranscribe: {}
    )
    .frame(maxWidth: .infinity)
    .frame(height: 120)
    .background(Color.darkBackground)
    .preferredColorScheme(.dark)
}

#Preview("Transcribing") {
    TranscriptionView(
        transcription: nil,
        isTranscribing: true,
        error: nil,
        onTranscribe: {}
    )
    .frame(maxWidth: .infinity)
    .frame(height: 120)
    .background(Color.darkBackground)
    .preferredColorScheme(.dark)
}

#Preview("Completed") {
    TranscriptionView(
        transcription: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        isTranscribing: false,
        error: nil,
        onTranscribe: {}
    )
    .frame(maxWidth: .infinity)
    .frame(height: 120)
    .background(Color.darkBackground)
    .preferredColorScheme(.dark)
}

#Preview("Expanded") {
    TranscriptionView(
        transcription: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
        isTranscribing: false,
        error: nil,
        onTranscribe: {}
    )
    .frame(maxWidth: .infinity)
    .frame(height: 250)
    .background(Color.darkBackground)
    .preferredColorScheme(.dark)
}

#Preview("Error") {
    TranscriptionView(
        transcription: nil,
        isTranscribing: false,
        error: "Transcription failed. Please try again.",
        onTranscribe: {}
    )
    .frame(maxWidth: .infinity)
    .frame(height: 120)
    .background(Color.darkBackground)
    .preferredColorScheme(.dark)
}
