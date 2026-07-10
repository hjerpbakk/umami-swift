import Foundation
import os

protocol EventUploader {
    func send(_ payloads: [UmamiPayload], to baseURL: URL, userAgent: String,
              completion: @escaping (Bool) -> Void)
}

struct NetworkUploader: EventUploader {
    let session: URLSession
    private let log = Logger(subsystem: "com.hjerpbakk.umami", category: "uploader")

    func send(_ payloads: [UmamiPayload], to baseURL: URL, userAgent: String,
              completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/batch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        do {
            request.httpBody = try JSONEncoder().encode(payloads)
        } catch {
            log.debug("encode failed: \(String(describing: error), privacy: .public)")
            completion(false)
            return
        }
        let task = session.dataTask(with: request) { _, response, error in
            if let error {
                self.log.debug("send failed: \(String(describing: error), privacy: .public)")
                completion(false)
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            completion((200...299).contains(code))
        }
        task.resume()
    }
}
