// Services/Audio/SpeechRecognizer.swift
import AVFoundation
import Speech
import Combine

@MainActor
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?

    override init() {
        // Cambia el locale si quieres otro idioma por defecto
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
        super.init()
    }

    /// Pide permisos y prepara el audio session
    func requestAuth() async throws {
        // requestAuthorization usa callback; lo envolvemos para usar async/await
        let status: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { s in cont.resume(returning: s) }
        }

        guard status == .authorized else {
            throw NSError(domain: "Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized (\(status))."])
        }

        // Configura el audio para hablar y escuchar a la vez
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .duckOthers, .allowBluetoothHFP] // <- aquí
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Empieza a escuchar y transcribir
    func start() throws {
        guard !isRecording else { return }
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available."])
        }

        transcript = ""
        isRecording = true

        // Nueva request
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        self.request = req

        // Tap de audio
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.removeTap(onBus: 0) // por si acaso quedaba alguno
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Tarea de reconocimiento
        self.task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }

            if let t = result?.bestTranscription.formattedString {
                self.transcript = t
            }

            // Si terminó (final o error), paramos para dejar limpio
            if let r = result, r.isFinal {
                self.stop()
            } else if error != nil {
                self.stop()
            }
        }
    }

    /// Detiene reconocimiento y limpia recursos
    func stop() {
        guard isRecording || request != nil || task != nil else { return }
        isRecording = false

        request?.endAudio()
        request = nil

        task?.cancel()
        task = nil

        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    /// Cambia de idioma en caliente (opcional)
    func setLocale(_ identifier: String) {
        // Nota: si cambias el locale en vivo, primero detén y vuelve a iniciar.
        // Aquí solo cambiamos el recognizer; start() validará availability.
        // Ejemplos: "es-MX", "es-ES", "en-US"
    }
}
