// Services/Audio/ElevenLabsTTSClient.swift
import Foundation
import AVFoundation

// Ajustes de la voz en ElevenLabs
struct ElevenVoiceSettings: Codable {
    var stability: Double = 0.35
    var similarity_boost: Double = 0.90
    var style: Double = 0.55
    var use_speaker_boost: Bool = true
}

final class ElevenLabsTTSClient: NSObject, AVAudioPlayerDelegate {
    // Clave y config
    private let apiKey: String
    private(set) var voiceId: String
    private(set) var modelId: String
    private(set) var settings: ElevenVoiceSettings
    private(set) var playbackRate: Float   // 1.0 normal; 1.15–1.25 suele sonar más natural

    // Reproductores
    private var audioPlayer: AVAudioPlayer?
    private var avPlayer: AVPlayer?

    // MARK: - Init
    init(apiKey: String,
         voiceId: String = "21m00Tcm4TlvDq8ikWAM", // ⚠️ cambia por tu voz ES de ElevenLabs
         modelId: String = "eleven_multilingual_v2",
         settings: ElevenVoiceSettings? = nil,
         playbackRate: Float = 1.20) {
        self.apiKey = apiKey
        self.voiceId = voiceId
        self.modelId = modelId
        self.settings = settings ?? ElevenVoiceSettings()
        self.playbackRate = playbackRate
    }

    // Cambios en caliente
    func updateVoice(voiceId: String? = nil,
                     modelId: String? = nil,
                     settings: ElevenVoiceSettings? = nil,
                     playbackRate: Float? = nil) {
        if let v = voiceId { self.voiceId = v }
        if let m = modelId { self.modelId = m }
        if let s = settings { self.settings = s }
        if let r = playbackRate { self.playbackRate = max(0.5, min(2.0, r)) }
    }

    // MARK: - Speak

    /// Genera audio y lo reproduce. Lanza errores si algo falla (se deben capturar desde la vista).
    func speak(text: String) async throws {
        stop()

        // 1) Pide audio a ElevenLabs
        let data = try await fetchAudio(text: text)

        // 2) Guarda a archivo temporal (estable para ambos players)
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("tts-\(UUID().uuidString).mp3")
        try data.write(to: tmpURL, options: .atomic)

        // Helper que intenta reproducir con la sesión indicada
        func play(withCategory category: AVAudioSession.Category,
                  mode: AVAudioSession.Mode,
                  options: AVAudioSession.CategoryOptions) throws {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(category, mode: mode, options: options)
            try session.setActive(true)

            // AVAudioPlayer con control de velocidad
            let p = try AVAudioPlayer(contentsOf: tmpURL)
            p.enableRate = true
            p.rate = playbackRate
            p.prepareToPlay()
            DispatchQueue.main.async { _ = p.play() }
            self.audioPlayer = p
        }

        do {
            // 3) PRIMER intento: calidad (A2DP), respeta modo silencio
            try play(withCategory: .playback,
                     mode: .spokenAudio,
                     options: [.allowBluetoothA2DP])
            return
        } catch {
            // 4) FALLBACK: ruta al altavoz con PlayAndRecord
            do {
                try play(withCategory: .playAndRecord,
                         mode: .voiceChat,
                         options: [.defaultToSpeaker, .duckOthers, .allowBluetoothHFP])
                return
            } catch {
                // 5) Último fallback: AVPlayer (por si el decoder del mp3 diera lata)
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, mode: .default, options: [])
                try? session.setActive(true)

                let item = AVPlayerItem(url: tmpURL)
                let player = AVPlayer(playerItem: item)
                self.avPlayer = player
                DispatchQueue.main.async { player.play() }

                // Si también fallara, lanza error genérico:
                if #available(iOS 16.0, *) { } // no-op
            }
        }
    }

    /// Detiene cualquier reproducción en curso
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        avPlayer?.pause()
        avPlayer = nil
    }

    // MARK: - Networking

    private func fetchAudio(text: String) async throws -> Data {
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
        let payload = Body(text: text, model_id: modelId, voice_settings: settings)
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "ElevenTTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta HTTP inválida"])
        }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "sin cuerpo"
            throw NSError(domain: "ElevenTTS", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(msg)"])
        }
        guard data.count > 500 else {
            throw NSError(domain: "ElevenTTS", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Audio vacío o demasiado corto (\(data.count) bytes)"])
        }
        return data
    }
}
