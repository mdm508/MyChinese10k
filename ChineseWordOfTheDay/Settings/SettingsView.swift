//
//  SettingsView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/9/25.
//

import SwiftUI
import Persistence
import CoreDataModels

/**
A view that allows users to adjust app settings related to phonetic notation and Chinese writing system.
 It also displays iCloud sync status with a visual indicator.
 - Features:
   - iCloud connection indicator with red/green dot
   - Picker for selecting phonetic notation (Zhuyin or Pinyin)
   - Picker for selecting Chinese character set (Traditional or Simplified)
 User preferences are saved via `UserPreferences`  that supports iCloud synchronization.
*/
struct SettingsView: View {
    // MARK: - Preference State
    @State private var isICloudAvailable: Bool = false
    @State private var phonetic: UserPreferences.Value = .zhuyin
    @State private var textPreference: UserPreferences.Value = .traditional
    @State private var cloudKitStatusMessage: String?
    @State private var notificationTime: Date = Date()
    @State private var remindersEnabled: Bool = false
    @EnvironmentObject private var ws: WordService
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
                    }
                    .onChange(of: self.phonetic) { newPhonetic in
                        self.setPhonetic(with: newPhonetic)
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
                        self.setHanzi(with: newValue)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                // MARK: - Daily Reminder Section
                Section(header: Text("Daily Reminder")) {
                    Toggle("Daily Notifications", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled) { newValue in
                            UserPreferences.saveRemindersEnabled(newValue)
                            if newValue {
                                self.requestNotificationPermission()
                                self.scheduleNotification(at: notificationTime)
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                    if remindersEnabled {
                        DatePicker("Notification Time",
                                   selection: $notificationTime,
                                   displayedComponents: .hourAndMinute)
                            .onChange(of: notificationTime) { newTime in
                                UserPreferences.saveNotificationTime(newTime)
                                self.scheduleNotification(at: newTime)
                            }
                    }
                }
            }
            .navigationTitle("Settings").toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    self.shareButton
                }
            }
            .onAppear {
                self.loadPhonetic()
                self.loadHanzi()
                self.remindersEnabled = UserPreferences.loadRemindersEnabled()
                self.notificationTime = UserPreferences.loadNotificationTime()
                Task {
                    await setCloudKitAvailability()
                }
            }
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
    func loadPhonetic() -> Void {
        self.phonetic = UserPreferences.get(.phoneticNotation)
    }
    func setPhonetic(with newValue: UserPreferences.Value) -> Void {
        UserPreferences.set(newValue, for: .phoneticNotation)
        self.postSettingsDidChangeNotification()
    }
    func loadHanzi() {
        self.textPreference = UserPreferences.get(.chineseWritingSystem)
    }
    func setHanzi(with newValue: UserPreferences.Value) {
        UserPreferences.set(newValue, for: .chineseWritingSystem)
        self.postSettingsDidChangeNotification()
    }
    /**
    Announces (to WordDetail) that the settings have changed.
     Could be avoided if I instantiated the WordService enviorment object but I
     just thought posting and reacting to notificiations is cool.
     */
     func postSettingsDidChangeNotification(){
        NotificationCenter.default.post(name: .settingDidChange, object: nil)
    }
}
extension Notification.Name {
    static let settingDidChange = Notification.Name("settingDidChange")
}
// MARK: - Notification Logic
private extension SettingsView {
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notifications allowed")
            }
        }
    }
    func scheduleNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "Waabl"
        content.body = "Tap button for \(self.ws.currentWord.characters)"
        content.sound = .default
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_word", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling: \(error.localizedDescription)")
            }
        }
    }
}
// MARK: - Sharing Logic
private extension SettingsView {
    func shareWord(word cw: Word) {
        let url = URL(string: "https://apps.apple.com/us/app/waabl/id1671041620")!
        let itemSource = WordShareItemSource(
            word: cw.characters,
            pinyin: cw.phonetic,
            definition: cw.meanings.first?.description ?? "",
            appURL: url
        )
        let activityVC = UIActivityViewController(
            activityItems: [itemSource, ws.currentWord.shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    var shareButton: some View {
        Button(action: {
            shareWord(word: ws.currentWord)
        }) {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.primary)
        }
    }
}
