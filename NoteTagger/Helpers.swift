import Foundation
#if canImport(UIKit)
import UIKit

func selectAllTextInAlert() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else { return }
    if let textField = findTextField(in: window) {
        textField.selectAll(nil)
    }
}

private func findTextField(in view: UIView) -> UITextField? {
    if let textField = view as? UITextField { return textField }
    for subview in view.subviews {
        if let found = findTextField(in: subview) { return found }
    }
    return nil
}
#endif

func localizedAppString(_ key: String, comment: String = "") -> String {
    let selectedLanguage = UserDefaults.standard.string(forKey: "selected_language") ?? "en"
    guard let path = Bundle.main.path(forResource: selectedLanguage, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        return NSLocalizedString(key, comment: comment)
    }
    return bundle.localizedString(forKey: key, value: nil, table: nil)
}
