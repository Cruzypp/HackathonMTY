import SwiftUI

struct VoiceChatView: View {
    @ObservedObject var vm: VoiceChatViewModel

    @State private var isAutoScroll = true

    var body: some View {
        VStack(spacing: 16) {
            // Toggle de Voice Mode
            HStack {
                Text("Accesibilidad asistida (Voice Mode)")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { vm.isVoiceModeOn },
                    set: { vm.toggleVoiceMode($0) }
                ))
                .labelsHidden()
            }
            .padding(.horizontal)

            Text(vm.isUserRecording ? "Escuchando…" : "Toca el micrófono para hablar")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Transcripción en vivo
            Text(vm.liveTranscript.isEmpty ? "—" : vm.liveTranscript)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)

            // Controles de voz
            HStack(spacing: 20) {
                Button {
                    if vm.isUserRecording { vm.stopListeningAndSend() }
                    else { vm.startListening() }
                } label: {
                    Image(systemName: vm.isUserRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 56))
                }

                Button {
                    vm.stopAll()
                } label: {
                    Image(systemName: "speaker.slash.circle.fill")
                        .font(.system(size: 40))
                }
            }

            // ====== HISTORIAL (mismo ChatViewModel) ======
            VStack(alignment: .leading, spacing: 8) {
                Text("Conversación")
                    .font(.subheadline).foregroundStyle(.secondary)
                Divider().opacity(0.2)
            }
            .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.chatVM.messages) { m in
                            HStack {
                                if !m.isFromUser { Spacer().frame(width: 0) }
                                Text(m.text)
                                    .padding(10)
                                    .background(m.isFromUser ? Color.blue : Color.gray.opacity(0.25))
                                    .foregroundStyle(m.isFromUser ? .white : .primary)
                                    .cornerRadius(12)
                                    .frame(maxWidth: .infinity, alignment: m.isFromUser ? .trailing : .leading)
                                    .id(m.id)
                                if m.isFromUser { Spacer().frame(width: 0) }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: vm.chatVM.messages.count) {
                    if isAutoScroll, let id = vm.chatVM.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .navigationTitle("FinBot (Voice)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Control de velocidad de TTS
                Menu {
                    Button("Velocidad 1.00x") { vm.tts.updateVoice(playbackRate: 1.0) }
                    Button("Velocidad 1.10x") { vm.tts.updateVoice(playbackRate: 1.10) }
                    Button("Velocidad 1.20x") { vm.tts.updateVoice(playbackRate: 1.20) }
                    Button("Velocidad 1.30x") { vm.tts.updateVoice(playbackRate: 1.30) }
                } label: {
                    Image(systemName: "speedometer")
                }
            }
        }
    }
}