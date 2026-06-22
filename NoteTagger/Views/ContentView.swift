import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = AudioRecorderManager()
    @State private var selectedTab = 0
    @StateObject private var languageManager = LanguageManager()

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

            NavigationStack {
                RecordingsListView()
                    .environmentObject(recorder)
            }
            .tabItem {
                Label { Text("tab_recordings") } icon: { Image(systemName: "list.bullet") }
            }
            .tag(1)

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
//        .environment(\.locale, .init(identifier: "it"))
}
