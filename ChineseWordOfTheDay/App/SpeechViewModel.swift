//
//  File.swift
//  ChineseWordOfTheDay
//
//  Created by wonderland on 5/2/23.
//

import Foundation
import AVFoundation

@MainActor
class SpeechViewModel: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    override init() {
        super.init()
        self.synthesizer.delegate = self
        setupAudioSession()
    }
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("🔊 Audio Session Error: \(error)")
        }
    }
    func speak(_ text: String, _ languageCode: LanguageCode) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode.rawValue)
        utterance.preUtteranceDelay = 0.05
        synthesizer.speak(utterance)
    }
}
// MARK: - AVSpeechSynthesizerDelegate
extension SpeechViewModel: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
extension SpeechViewModel {
    enum LanguageCode: String {
        case english = "en-US"
        case chineseTaiwan = "zh-TW"
    }
}
