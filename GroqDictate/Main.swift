import SwiftUI
import AppKit

@main
struct PollyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Settings state
    @AppStorage("groqAPIKey") private var groqAPIKey = ""
    @AppStorage("selectedModel") private var selectedModel = "whisper-large-v3"
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @AppStorage("launchOnStartup") private var launchOnStartup = false
    
    // App state
    @State private var isRecording = false
    @State private var transcription: String = ""
    @State private var recordingStartTime: Date? = nil
    
    // Services
    private let audioRecorder = AudioRecorder()
    private let groqAPI = GroqAPI()
    private let pasteManager = PasteManager()
    
    var body: some Scene {
        // Use a custom Label to dynamically fetch the raw PNG from Resources and treat it as a mask
        MenuBarExtra {
            VStack {
                Text("Polly")
                    .font(.headline)
                
                Divider()
                
                Text(isRecording ? "Recording..." : "Ready")
                    .foregroundColor(isRecording ? .red : .primary)
                
                Divider()
                
                Button("Settings...") {
                    appDelegate.openSettings()
                }
                
                Divider()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FnKeyDown"))) { _ in
                if !isRecording { startRecording() }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FnKeyUp"))) { _ in
                if isRecording { stopRecording() }
            }
        } label: {
            let image = NSImage(named: "ParrotTemplate")
            let _ = image?.isTemplate = true
            
            if let img = image {
                Image(nsImage: img)
            } else {
                Image(systemName: isRecording ? "bird.fill" : "bird")
            }
        }
        .menuBarExtraStyle(.menu)
    }
    
    private func startRecording() {
        if groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("Please set your Groq API Key in Settings.")
            return
        }
        isRecording = true
        recordingStartTime = Date()
        OverlayManager.shared.show()
        audioRecorder.startRecording()
    }
    
    private func stopRecording() {
        if !isRecording { return }
        isRecording = false
        OverlayManager.shared.hide()
        audioRecorder.stopRecording()
        
        let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
        if duration < 0.5 {
            print("Recording too short (\\(duration)s), ignoring.")
            return
        }
        
        if let fileURL = audioRecorder.getAudioFileURL() {
            Task {
                do {
                    let text = try await groqAPI.transcribe(audioFileURL: fileURL, apiKey: groqAPIKey, model: selectedModel, language: selectedLanguage)
                    
                    if isHallucination(text) {
                        print("Ignored hallucinated text: \\(text)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.transcription = text
                        pasteManager.paste(text: text)
                    }
                } catch {
                    print("Transcription error: \\(error)")
                    // Handle error (e.g., show notification)
                }
            }
        }
    }
    
    private func isHallucination(_ text: String) -> Bool {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let knownHallucinations = [
            "thank you.", "thank you",
            "thanks.", "thanks",
            "thanks for watching.", "thanks for watching!", "thanks for watching",
            "subtitles by amara.org", "subtitles by amara.org.",
            "amara.org",
            "you"
        ]
        return knownHallucinations.contains(cleaned) || cleaned.isEmpty
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions at launch
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility access not granted. Please enable it in System Settings.")
        }
        
        // Listen for 'fn' key globally
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            if event.keyCode == 63 {
                if event.modifierFlags.contains(.function) {
                    NotificationCenter.default.post(name: NSNotification.Name("FnKeyDown"), object: nil)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("FnKeyUp"), object: nil)
                }
            }
        }
        
        // Listen for 'fn' key while app is active
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            if event.keyCode == 63 {
                if event.modifierFlags.contains(.function) {
                    NotificationCenter.default.post(name: NSNotification.Name("FnKeyDown"), object: nil)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("FnKeyUp"), object: nil)
                }
                return nil
            }
            return event
        }
    }
    
    private var settingsWindow: NSWindow?
    
    func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("Settings")
            window.title = "Settings"
            window.contentView = hostingController.view
            window.isReleasedWhenClosed = false
            self.settingsWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
