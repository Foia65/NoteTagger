import SwiftUI
import Combine
import StoreKit

// MARK: - LanguageManager

/// Manages the app's language preference and provides a `Locale` for SwiftUI.
class LanguageManager: ObservableObject {
    @AppStorage("selected_language") var selectedLanguage: String = "en" {
        didSet {
            objectWillChange.send()
        }
    }

    var currentLocale: Locale {
        Locale(identifier: selectedLanguage)
    }
}

// MARK: - SettingsView
//
// App settings view: language, theme, measurement system, runner profile, and legal links.
struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    let languages: [(String, String)] = [
        ("Italiano", "it"),
        ("English", "en")
    ]

    var body: some View {
        List {
            Section(header: HStack { Text("settings_info_support").font(.title3) }.padding(.top, 20)) {

                NavigationLink(destination: Segnaposto()) {
                    Label {
                        Text("settings_help")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                Button {
                    if let url = URL(string: "mailto:info.foiasoft@gmail.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label {
                        Text("settings_contact_support")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                HStack {
                    Label {
                        Text("settings_version")
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

            Section(header: Text("settings_account").font(.title3)) {

                HStack {
                    Label {
                        Text("settings_product_level")
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
                            Text("settings_premium")
                                .font(.system(.subheadline, design: .rounded, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("settings_base_free")
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }

                if !isPremiumUser {
                    NavigationLink(destination: Segnaposto()) {
                        Label {
                            Text("settings_view_premium_offer")
                        } icon: {
                            Image(systemName: "crown")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if !isPremiumUser {
                    Button {
                        Task {
                        }
                    } label: {
                        Label {
                            Text("settings_restore_purchase")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "icloud.and.arrow.down")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button {
                    requestAppReview()
                } label: {
                    Label {
                        Text("settings_rate_app")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "star")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("settings_preferences").font(.title3)) {

                HStack {
                    Label {
                        Text("settings_language")
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
                            Text(LocalizedStringKey(name)).tag(code)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .pickerStyle(.navigationLink)
                }
            }

            Section(header: Text("settings_privacy_security").font(.title3)) {

                NavigationLink(destination: Segnaposto()) {
                    Label {
                        Text("settings_privacy_policy")
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                NavigationLink(destination: Segnaposto()) {
                    Label {
                        Text("settings_terms_of_service")
                    } icon: {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
            }

#if DEBUG
            Section(header: Text("settings_debug").font(.title3)) {

                Toggle(isOn: $isPremiumUser) {
                    Label("settings_premium_user", systemImage: "crown")
                }
                .foregroundStyle(.blue)
            }
#endif

        }
        .font(.system(.subheadline, design: .default, weight: .semibold))
        .environment(\.defaultMinListRowHeight, 28)
    }
}

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
