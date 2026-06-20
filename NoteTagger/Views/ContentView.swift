import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = AudioRecorderManager()
    @State private var selectedTab = 0
    @StateObject private var languageManager = LanguageManager()
    
    var body: some View {
        NavigationStack {
            
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
                
                SettingsView()
                    .environmentObject(languageManager)
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Impostazioni")
                    }
                    .tag(2)
            }
        }
        .tint(.accentVivid)
        .environment(\.locale, languageManager.currentLocale)
    }
}

#Preview {
    ContentView()
}
