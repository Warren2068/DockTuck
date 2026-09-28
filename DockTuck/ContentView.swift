import SwiftUI
import ServiceManagement

struct ContentView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var isClickToMinimizeEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "ClickToMinimizeEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "ClickToMinimizeEnabled")
            return true
        }
        return UserDefaults.standard.bool(forKey: "ClickToMinimizeEnabled")
    }()

    @State private var launchAtLogin: Bool = {
        if UserDefaults.standard.object(forKey: "LaunchAtLoginEnabled") == nil { return false }
        return UserDefaults.standard.bool(forKey: "LaunchAtLoginEnabled")
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DockTuck")
                .font(.headline)
                .padding(.top, 4)

            Divider()

            Toggle("Enable DockTuck", isOn: $isClickToMinimizeEnabled)
                .onChange(of: isClickToMinimizeEnabled) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "ClickToMinimizeEnabled")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ClickToHideStateChanged"),
                        object: newValue
                    )
                }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "LaunchAtLoginEnabled")
                    do {
                        if newValue {
                            if SMAppService.mainApp.status != .enabled {
                                try SMAppService.mainApp.register()
                            }
                        } else {
                            if SMAppService.mainApp.status == .enabled {
                                try SMAppService.mainApp.unregister()
                            }
                        }
                    } catch {
                        // Roll the toggle back on failure
                        launchAtLogin = !newValue
                        UserDefaults.standard.set(!newValue, forKey: "LaunchAtLoginEnabled")
                    }
                }

            Divider()

            Text("If the app doesn't work, enable Accessibility and Automation permissions from the menu-bar menu.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 280)
    }
}
