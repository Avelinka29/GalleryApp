import Foundation

enum APIConfiguration {
    static func accessKey(bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let secrets = try? PropertyListDecoder().decode(Secrets.self, from: data) else {
            return nil
        }
        let key = secrets.unsplashAccessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty || key == "YOUR_ACCESS_KEY" ? nil : key
    }

    private struct Secrets: Decodable {
        let unsplashAccessKey: String
    }
}
