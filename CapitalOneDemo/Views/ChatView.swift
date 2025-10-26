// ChatView.swift
import SwiftUI
import AVFoundation

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var ledger: LedgerViewModel

    // Voz y accesibilidad
    @StateObject private var speech = SpeechRecognizer()
    @State private var isRecording = false
    @State private var liveTranscript: String = ""
    @State private var voiceModeOn = false
    @State private var hasRequestedSpeechAuth = false

    // TTS y manejo de errores
    @State private var tts: ElevenLabsTTSClient? = nil
    @State private var showMissingKeyAlert = false
    @State private var errorMessage: String? = nil

    // Text input normal
    @State private var textInput: String = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SwiftFinColor.bgPrimary, SwiftFinColor.surface.opacity(0.3)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // --- Mensajes ---
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { m in
                                MessageBubble(message: m)
                                    .id(m.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }.padding()
                    }
                    .onChange(of: viewModel.messages.count) {
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                // --- Indicador de "escribiendo..." ---
                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView().tint(SwiftFinColor.accentBlue)
                        Text("FinBot is typing…")
                            .foregroundStyle(SwiftFinColor.textSecondary)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(SwiftFinColor.surface.opacity(0.5))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // --- Parte inferior: alterna entre TextField y micrófono ---
                if voiceModeOn {
                    // ======= MODO VOZ =======
                    VStack(spacing: 10) {
                        Text(isRecording ? "Escuchando…" : "Toca el micrófono para hablar")
                            .font(.caption)
                            .foregroundStyle(Color.white)

                        if isRecording && !liveTranscript.isEmpty {
                            Text(liveTranscript)
                                .font(.footnote)
                                .foregroundStyle(SwiftFinColor.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(SwiftFinColor.surface.opacity(0.6))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .transition(.opacity)
                        }

                        Button(action: micTapped) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.red, Color(red: 0.7, green: 0, blue: 0)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .red.opacity(isRecording ? 0.6 : 0.25),
                                            radius: 12, y: 6)

                                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                    .foregroundStyle(.white)
                                    .font(.system(size: isRecording ? 26 : 30, weight: .bold))
                            }
                            .accessibilityLabel(isRecording ? "Detener grabación" : "Iniciar grabación")
                        }
                        .padding(.bottom, 10)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            SwiftFinColor.bgPrimary.opacity(0.98)
                            LinearGradient(colors: [.white.opacity(0.03), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        }.ignoresSafeArea(edges: .bottom)
                    )
                } else {
                    // ======= MODO TEXTO =======
                    HStack(spacing: 12) {
                        TextField("", text: $textInput, prompt:
                                    Text("Ask FinBot...")
                            .foregroundStyle(.white), axis: .vertical // 1. Placeholder blanco
                        )
                            .lineLimit(3)
                            .padding(12)
                            .tint(SwiftFinColor.accentBlue)
                            .foregroundStyle(.white) // 2. Texto de entrada (tipeado) blanco
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(SwiftFinColor.surface.opacity(0.8))
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient(
                                            colors: [.white.opacity(0.05), .clear],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.2), SwiftFinColor.divider],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ), lineWidth: 1
                                    )
                            )

                        Button(action: sendTextMessage) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: textInput.isEmpty ?
                                                [SwiftFinColor.surfaceAlt, SwiftFinColor.surface] :
                                                [SwiftFinColor.accentBlue, Color(hex: "#00559A")],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)

                                if !textInput.isEmpty {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.white.opacity(0.2), .clear],
                                            startPoint: .top, endPoint: .bottom
                                        ))
                                        .frame(width: 44, height: 44)
                                }

                                Image(systemName: "arrow.up")
                                    .font(.title3).fontWeight(.semibold)
                                    .foregroundStyle(textInput.isEmpty ? SwiftFinColor.textSecondary : .white)
                            }
                            .shadow(color: textInput.isEmpty ? .clear : SwiftFinColor.accentBlue.opacity(0.4),
                                    radius: 8, y: 4)
                        }
                        .disabled(textInput.isEmpty || viewModel.isLoading)
                        .scaleEffect(textInput.isEmpty || viewModel.isLoading ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7),
                                   value: textInput.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            SwiftFinColor.bgPrimary.opacity(0.98)
                            LinearGradient(colors: [.white.opacity(0.03), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        }.ignoresSafeArea(edges: .bottom)
                    )
                }
            }
        }
        .navigationTitle("FinBot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        if !voiceModeOn {
                            if !hasRequestedSpeechAuth {
                                try? await speech.requestAuth()
                                hasRequestedSpeechAuth = true
                            }
                        } else {
                            speech.stop()
                            isRecording = false
                        }
                        withAnimation { voiceModeOn.toggle() }
                    }
                } label: {
                    Image(systemName: voiceModeOn ? "keyboard" : "ear.badge.waveform")
                        .accessibilityLabel(voiceModeOn ? "Cambiar a teclado" : "Activar modo voz")
                }
            }
        }
        .onAppear {
            if tts == nil, let key = elevenAPIKey() {
                let client = ElevenLabsTTSClient(apiKey: key)
                client.updateVoice(playbackRate: 1.2)
                tts = client
            }
            viewModel.setContext( ledger.financialSummary )
        }
        .onReceive(speech.$transcript) { live in
            self.liveTranscript = live
        }
        .alert("Falta ELEVEN_API_KEY", isPresented: $showMissingKeyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Agrega ELEVEN_API_KEY en Config/GenerativeAIInfo.plist para que FinBot hable.")
        }
        .alert("Error al reproducir la voz", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Desconocido")
        }
    }

    // MARK: - Acciones

    private func sendTextMessage() {
        let messageText = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        textInput = ""
        Task {
            await viewModel.sendMessage(messageText)
            await speakLastBotMessage()
        }
    }

    private func micTapped() {
        if isRecording {
            // detener y mandar
            speech.stop()
            withAnimation { isRecording = false }
            let text = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            liveTranscript = ""
            guard !text.isEmpty else { return }

            Task {
                await viewModel.sendMessage(text)
                await speakLastBotMessage()
            }
        } else {
            // empezar a escuchar
            Task {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat,
                        options: [.defaultToSpeaker, .duckOthers, .allowBluetoothHFP])
                    try AVAudioSession.sharedInstance().setActive(true)
                    try speech.start()
                    withAnimation { isRecording = true }
                } catch {
                    isRecording = false
                    print("Speech start error:", error)
                }
            }
        }
    }

    @MainActor
    private func speakLastBotMessage() async {
        try? await Task.sleep(nanoseconds: 250_000_000)
        guard let last = viewModel.messages.last, !last.isFromUser else { return }
        guard let tts = tts else { showMissingKeyAlert = true; return }
        speech.stop(); isRecording = false

        do {
            try await tts.speak(text: last.text)
        } catch {
            errorMessage = error.localizedDescription
            print("TTS error:", error)
        }
    }

    // MARK: - Helpers

    private func elevenAPIKey() -> String? {
        guard
            let path = Bundle.main.path(forResource: "GenerativeAIInfo", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let key = dict["ELEVEN_API_KEY"] as? String
        else { return nil }
        return key
    }
}

#Preview {
    NavigationView { ChatView() }
}
