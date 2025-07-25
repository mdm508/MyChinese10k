//
//  SettingsView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/9/25.
//

import SwiftUI
import Persistence

/// A view that allows users to adjust app settings related to phonetic notation and Chinese writing system.
/// It also displays iCloud sync status with a visual indicator.
///
/// - Features:
///   - iCloud connection indicator with red/green dot
///   - Picker for selecting phonetic notation (Zhuyin or Pinyin)
///   - Picker for selecting Chinese character set (Traditional or Simplified)
///
/// User preferences are saved via `UserPreferences`  that supports iCloud synchronization.
struct SettingsView: View {
    // MARK: - Preference State
    @State private var isICloudAvailable: Bool = false
    @State private var phonetic: UserPreferences.Value = .zhuyin
    @State private var textPreference: UserPreferences.Value = .traditional
    @State private var cloudKitStatusMessage: String?
}
extension SettingsView {
    // MARK: - Preference View
    var body: some View {
            Form {
                // MARK: - iCloud Issue Section
                Section(header: Text("iCloud Status").font(.headline)) {
                    HStack {
                        Circle()
                            .fill(self.isICloudAvailable ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(self.isICloudAvailable ? "iCloud Connected" : "iCloud Not Connected")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                // MARK: - Preferred Pronunciation Section
                Section(header: Text("Phonetic Notation")) {
                    Picker("", selection: $phonetic) {
                        Text("Zhuyin").tag(UserPreferences.Value.zhuyin)
                        Text("Pinyin").tag(UserPreferences.Value.pinyin)
                    }.onChange(of: self.phonetic) {newPhonetic in
                        Task{ await self.setPhonetic(with: newPhonetic)}
                    }.onAppear(){
                        Task { await self.loadPhonetic()}
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                // MARK: - Preferred Text Section
                Section(header: Text("Character Set")) {
                    Picker("", selection: $textPreference) {
                        Text("Traditional").tag(UserPreferences.Value.traditional)
                        Text("Simplified").tag(UserPreferences.Value.simplified)
                    }
                    .onChange(of: self.textPreference) { newValue in
                        Task { await self.setHanzi(with: newValue) }
                    }
                    .onAppear {
                        Task { await self.loadHanzi() }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: {Task {await setCloudKitAvailability()}})
        }
    }

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
// MARK: - View Helper Functions
extension SettingsView {
    func setCloudKitAvailability() async {
        // fetch the status
        let status = (try? await Cloud.ck.accountStatus()) ?? .couldNotDetermine
        switch status {
        case .available:
            self.isICloudAvailable = true
            self.cloudKitStatusMessage = "CloudKit is connected. Data will Sync between devices"
        case .noAccount:
            self.isICloudAvailable = false
            self.cloudKitStatusMessage = "CloudKit is not connected. Please sign in to iCloud on your device."
        case .restricted:
            self.isICloudAvailable = false
            self.cloudKitStatusMessage = "CloudKit access is restricted. Please check your iCloud settings."
        default:
            self.isICloudAvailable = false
            self.cloudKitStatusMessage = "CloudKit is not connected. Please sign in to iCloud on your device."
        }
    }
}
// MARK: - Loading Settings
extension SettingsView {
    func loadPhonetic() async -> Void {
        self.phonetic = await UserPreferences.get(.phoneticNotation)
    }
    func setPhonetic(with newValue: UserPreferences.Value) async -> Void {
        await UserPreferences.set(newValue, for: .phoneticNotation)
    }
    func loadHanzi() async {
        self.textPreference = await UserPreferences.get(.chineseWritingSystem)
    }
    func setHanzi(with newValue: UserPreferences.Value) async {
        await UserPreferences.set(newValue, for: .chineseWritingSystem)
    }
}
