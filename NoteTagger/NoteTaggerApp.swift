import SwiftUI

@main
struct NoteTaggerApp: App {
    @StateObject private var languageManager = LanguageManager()
    
//    init() {
//        for family in UIFont.familyNames {
//            print("Famiglia: \(family) -> Fonts: \(UIFont.fontNames(forFamilyName: family))")
//        }
//    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.currentLocale)
        }
    }
}
