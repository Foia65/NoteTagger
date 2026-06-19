import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = AudioRecorderManager()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView()
                .environmentObject(recorder)
                .tabItem {
                    Label(String(localized: "tab_record"), systemImage: "mic.circle.fill")
                }
                .tag(0)

            RecordingsListView()
                .environmentObject(recorder)
                .tabItem {
                    Label(String(localized: "tab_recordings"), systemImage: "list.bullet")
                }
                .tag(1)
        }
        .tint(.accentVivid)
    }
}

#Preview {
    ContentView()
}
