// VoiceChatViewModel.swift
import Foundation
import Combine

@MainActor
final class VoiceChatViewModel: ObservableObject {
    @Published var isVoiceModeOn: Bool = false
    @Published var liveTranscript: String = ""
    @Published var isBotSpeaking: Bool = false
    @Published var isUserRecording: Bool = false

    let chatVM: ChatViewModel
    let speech = SpeechRecognizer()
    let tts: ElevenLabsTTSClient

    init(chatVM: ChatViewModel, elevenApiKey: String) {
        self.chatVM = chatVM
        self.tts = ElevenLabsTTSClient(apiKey: elevenApiKey)
    }

    func toggleVoiceMode(_ on: Bool) {
        isVoiceModeOn = on
        if on { Task { try? await speech.requestAuth() } }
        else { stopAll() }
    }

    func startListening() {
        guard !isBotSpeaking else { return }   // evita eco/feedback
        tts.stop()                              // barge-in
        try? speech.start()
        isUserRecording = true
        // Observa transcript con Combine (o en onReceive desde la View)
    }

    func stopListeningAndSend() {
        speech.stop()
        isUserRecording = false
        let text = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        liveTranscript = text
        if !text.isEmpty {
            Task { await send(text) }
        }
    }

    private func send(_ text: String) async {
        await chatVM.sendMessage(text) // esto ya hace streaming de Gemini en tu VM
        // Espera un pequeño “debounce” para que termine de llegar el texto (simple)
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Toma el último mensaje del bot
        if let last = chatVM.messages.last, !last.isFromUser {
            isBotSpeaking = true
            defer { isBotSpeaking = false }
            try? await tts.speak(text: last.text)
        }
    }

    func stopAll() {
        speech.stop()
        tts.stop()
        isUserRecording = false
        isBotSpeaking = false
    }
}
