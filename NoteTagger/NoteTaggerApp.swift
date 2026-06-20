import SwiftUI

@main
struct NoteTaggerApp: App {
    @StateObject private var languageManager = LanguageManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.currentLocale)
        }
    }
}
