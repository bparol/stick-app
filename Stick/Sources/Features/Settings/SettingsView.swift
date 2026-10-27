import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Interests") {
                Text("Choose what you want to make time for.")
            }
            Section("Daily reminder") {
                Text("Reminder preferences are coming next.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
    }
}
