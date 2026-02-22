import Foundation

class GroqAPI {
    let endpoint = "https://api.groq.com/openai/v1/audio/transcriptions"
    
    func transcribe(audioFileURL: URL, apiKey: String, model: String, language: String) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Model parameter
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(model)\r\n".data(using: .utf8)!)
        
        // Language parameter
        if !language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // File parameter
        let fileData = try Data(contentsOf: audioFileURL)
        let fileName = audioFileURL.lastPathComponent
        let mimeType = "audio/m4a"
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        
        // Output format
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        data.append("json\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            print("API Error (\(httpResponse.statusCode)): \(errorString)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(TranscriptionResponse.self, from: responseData)
        
        return result.text
    }
    
    func testAuthentication(apiKey: String) async throws -> Bool {
        guard let url = URL(string: "https://api.groq.com/openai/v1/models") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        
        return false
    }
}

struct TranscriptionResponse: Codable {
    let text: String
}
