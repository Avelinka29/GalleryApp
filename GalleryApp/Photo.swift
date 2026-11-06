import Foundation

struct Photo: Decodable, Equatable, Sendable {
    let id: String
    let description: String?
    let altDescription: String?
    let urls: ImageURLs
    let user: Author

    struct ImageURLs: Decodable, Equatable, Sendable {
        let small: URL
        let regular: URL
    }

    struct Author: Decodable, Equatable, Sendable {
        let name: String
        let links: Links
    }

    struct Links: Decodable, Equatable, Sendable {
        let html: URL
    }

    enum CodingKeys: String, CodingKey {
        case id, description, urls, user
        case altDescription = "alt_description"
    }

    var displayDescription: String {
        for text in [description, altDescription].compactMap({ $0 }) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return "Без описания"
    }

    var attributionURL: URL {
        var components = URLComponents(url: user.links.html, resolvingAgainstBaseURL: false)
        var items = components?.queryItems ?? []
        items.removeAll { $0.name == "utm_source" || $0.name == "utm_medium" }
        items += [
            URLQueryItem(name: "utm_source", value: "gallery_app"),
            URLQueryItem(name: "utm_medium", value: "referral")
        ]
        components?.queryItems = items
        return components?.url ?? user.links.html
    }
}

struct PhotoPage: Sendable {
    let photos: [Photo]
    let hasMore: Bool
}
