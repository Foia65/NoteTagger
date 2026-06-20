import SwiftUI
import Combine
import StoreKit

// MARK: - LanguageManager

/// Manages the app's language preference and provides a `Locale` for SwiftUI.
class LanguageManager: ObservableObject {
    // Saves the language identifier (e.g. "it", "en") to UserDefaults
    @AppStorage("selected_language") var selectedLanguage: String = "en" {
        didSet {
            // Notify views of changes
            objectWillChange.send()
        }
    }

    // Converts the string to a Locale object usable by SwiftUI
    var currentLocale: Locale {
        Locale(identifier: selectedLanguage)
    }
}

// MARK: - SettingsView
//
// App settings view: language, theme, measurement system, runner profile, and legal links.
struct SettingsView: View {
//    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    // Supported languages
    let languages = [
        ("Italiano", "it"),
        ("English", "en")
    ]

    var body: some View {
        List {
            Section(header: HStack { Text("Informazioni e supporto").font(.title3) }.padding(.top, 20)) {

                // 1 - Method basics
                NavigationLink(destination: Segnaposto()) {
                    Label {
                        Text("Le basi del metodo")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                // 2 - Help
                NavigationLink(destination: Segnaposto()) {
                    Label {
                        Text("Guida")
                            .foregroundColor(.primary)

                    } icon: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                // 3 - Support
                Button {
                    if let url = URL(string: "mailto:info.foiasoft@gmail.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label {
                        Text("Contatta il supporto")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                // 4 - App version
                HStack {
                    Label {
                        Text("Versione: ")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "shippingbox")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    Spacer()
                    Text("\(Bundle.main.appVersionDisplay) (\(Bundle.main.appBuild))")
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundColor(.secondary)

                }
            }

             Section(header: Text("Account").font(.title3)) {

                // 1 - Product level
                HStack {
                    Label {
                        Text("Livello Prodotto:")
                    } icon: {
                        Image(systemName: "person.badge.shield.checkmark")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }

                    Spacer()

                    if isPremiumUser {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.footnote)
                                .foregroundColor(.yellow)
                            Text("Premium")
                                .font(.system(.subheadline, design: .rounded, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Base (gratuito)")
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }

                // 2 - View premium offer-
                if !isPremiumUser {
                    NavigationLink(destination: Segnaposto()) {
                        Label {
                            Text("Visualizza l'offerta premium")
                        } icon: {
                            Image(systemName: "crown")
                            .font(.footnote)
                        .foregroundColor(.secondary)}
                    }
                }

                // 3 - restore purchase
                if !isPremiumUser {
                    Button {
                        Task {
  //                          await storeKitManager.restorePurchases()
                        }
                    } label: {
                        Label {
                            Text("Ripristina l'acquisto")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "icloud.and.arrow.down")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                // 4 - Rate this App
                 Button {
                    requestAppReview()

                } label: {
                    Label {
                        Text("Valuta questa App")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "star")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Preferenze").font(.title3)) {


                // 4 - Language
                HStack {
                    Label {
                        Text("Lingua")
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .layoutPriority(1)
                    } icon: {
                        Image(systemName: "globe")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    }
                    Spacer()
                    Picker("", selection: $languageManager.selectedLanguage) {
                        ForEach(languages, id: \.1) { name, code in
                            Text(name).tag(code)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                     .pickerStyle(.navigationLink)
                 }
            }

            Section(header: Text("Privacy e Sicurezza").font(.title3)) {

                NavigationLink(destination: Segnaposto()) {
                    Label {
                        Text("Informativa Privacy")
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                NavigationLink(destination: Segnaposto()) {
                    Label {
                        Text("Termini di utilizzo")
                    } icon: {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

            }

#if DEBUG
            Section(header: Text("Debug").font(.title3)) {

                // to play with premium status
                Toggle(isOn: $isPremiumUser) {
                    Label("Premium User", systemImage: "crown")
                }
                .foregroundStyle(.blue)
            }

#endif

        }
        .font(.system(.subheadline, design: .default, weight: .semibold))
        .environment(\.defaultMinListRowHeight, 28)

    }
}

// Convenience accessors for app version and build information.
extension Bundle {
    var appVersionDisplay: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

func requestAppReview() {
    print("=== Review Request Debug ===")
    print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
    #if DEBUG
    print("Is Debug: true")
    #else
    print("Is Debug: false")
    #endif

    guard let scene = UIApplication.shared.connectedScenes.first(where: {
        $0.activationState == .foregroundActive
    }) as? UIWindowScene else {
        print("No active window scene found")
        return
    }

    print("Scene found: \(scene)")
    print("Requesting review...")
    AppStore.requestReview(in: scene)
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(LanguageManager())
            .environment(\.locale, .init(identifier: "it"))
    }
}
