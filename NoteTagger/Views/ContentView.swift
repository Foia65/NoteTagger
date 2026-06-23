import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = AudioRecorderManager()
    @State private var selectedTab = 0
    @StateObject private var languageManager = LanguageManager()
    @State private var recordingsNavigationPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                RecordView()
                    .environmentObject(recorder)
            }
            .tabItem {
                Label { Text("tab_record") } icon: { Image(systemName: "mic.circle.fill") }
            }
            .tag(0)

            NavigationStack(path: $recordingsNavigationPath) {
                RecordingsListView()
                    .environmentObject(recorder)
            }
            .tabItem {
                Label { Text("tab_recordings") } icon: { Image(systemName: "list.bullet") }
            }
            .tag(1)
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 1 && !recordingsNavigationPath.isEmpty {
                    recordingsNavigationPath = NavigationPath()
                }
            }

            NavigationStack {
                SettingsView()
                    .environmentObject(languageManager)
            }
            .tabItem {
                Label { Text("tab_settings") } icon: { Image(systemName: "gearshape") }
            }
            .tag(2)
        }
        .tint(.accentVivid)
        .environment(\.locale, languageManager.currentLocale)
    }
}
#Preview {
    ContentView()
}
