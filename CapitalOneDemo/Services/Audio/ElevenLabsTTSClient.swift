import Foundation
import AVFoundation

struct ElevenVoiceSettings: Codable {
    var stability: Double = 0.35
    var similarity_boost: Double = 0.9
    var style: Double = 0.55
    var use_speaker_boost: Bool = true
}

final class ElevenLabsTTSClient: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private let apiKey: String

    // Configurables en caliente
    private(set) var voiceId: String
    private(set) var modelId: String
    private(set) var settings: ElevenVoiceSettings
    private(set) var playbackRate: Float

    init(apiKey: String,
         voiceId: String = "21m00Tcm4TlvDq8ikWAM", // <-- CAMBIA por tu voz ES
         modelId: String = "eleven_multilingual_v2",
         settings: ElevenVoiceSettings = ElevenVoiceSettings(),
         playbackRate: Float = 1.15) {
        self.apiKey = apiKey
        self.voiceId = voiceId
        self.modelId = modelId
        self.settings = settings
        self.playbackRate = playbackRate
    }

    func updateVoice(voiceId: String? = nil,
                     modelId: String? = nil,
                     settings: ElevenVoiceSettings? = nil,
                     playbackRate: Float? = nil) {
        if let v = voiceId { self.voiceId = v }
        if let m = modelId { self.modelId = m }
        if let s = settings { self.settings = s }
        if let r = playbackRate { self.playbackRate = max(0.5, min(2.0, r)) }
    }

    func speak(text: String) async throws {
        stop()

        // Para reproducir con mejor calidad (A2DP) al HABLAR el bot:
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetoothA2DP, .defaultToSpeaker])
        try session.setActive(true)

        var req = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        struct Body: Codable {
            let text: String
            let model_id: String
            let voice_settings: ElevenVoiceSettings
        }
        let body = Body(text: text, model_id: modelId, voice_settings: settings)
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "TTS", code: 2, userInfo: [NSLocalizedDescriptionKey: "ElevenLabs TTS HTTP error"])
        }

        let p = try AVAudioPlayer(data: data)
        p.delegate = self
        p.prepareToPlay()
        p.enableRate = true
        p.rate = playbackRate // ← velocidad (1.00 normal; 1.15–1.25 suena más natural)
        self.player = p
        p.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}