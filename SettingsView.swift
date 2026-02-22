import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("groqAPIKey") private var groqAPIKey = ""
    @AppStorage("selectedModel") private var selectedModel = "whisper-large-v3"
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @AppStorage("launchOnStartup") private var launchOnStartup = false
    
    let models = ["whisper-large-v3", "whisper-large", "whisper-base"]
    
    @State private var testResult = ""
    @State private var testSuccess = false
    
    var body: some View {
        Form {
            Section(header: Text("Groq API")) {
                SecureField("API Key:", text: $groqAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                HStack {
                    Button("Test API Key") {
                        testAPIKey()
                    }
                    if !testResult.isEmpty {
                        Text(testResult)
                            .foregroundColor(testSuccess ? .green : .red)
                            .font(.caption)
                    }
                }
                
                Picker("Model:", selection: $selectedModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .frame(width: 300)
                
                TextField("Language (e.g. en, ko):", text: $selectedLanguage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 320)
            }
            
            Section(header: Text("System")) {
                Toggle("Launch on system startup", isOn: $launchOnStartup)
                    .onChange(of: launchOnStartup) { old, newValue in
                        toggleLaunchAtStartup(enabled: newValue)
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Instructions:")
                    .font(.headline)
                Text("1. Ensure Microphone & Accessibility permissions are granted.")
                    .fixedSize(horizontal: false, vertical: true)
                Text("2. Press and hold the 'fn' (Globe) key to record. Release to stop.")
                    .fixedSize(horizontal: false, vertical: true)
                Text("3. Wait a moment, and your text will be pasted!")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 16)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }
    
    private func toggleLaunchAtStartup(enabled: Bool) {
        // Use SMAppService for macOS 13+
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to toggle launch at startup: \\(error)")
            }
        }
    }
    
    private func testAPIKey() {
        guard !groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            testSuccess = false
            testResult = "Please enter an API Key first."
            return
        }
        
        testResult = "Testing..."
        testSuccess = false
        let apiKeyToTest = groqAPIKey
        
        Task {
            let groqAPI = GroqAPI()
            do {
                let isValid = try await groqAPI.testAuthentication(apiKey: apiKeyToTest)
                DispatchQueue.main.async {
                    if isValid {
                        testSuccess = true
                        testResult = "API Key is valid!"
                    } else {
                        testSuccess = false
                        testResult = "Invalid API Key."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    testSuccess = false
                    testResult = "Error connecting."
                }
            }
        }
    }
}
