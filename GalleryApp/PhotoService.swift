import Foundation

@MainActor
protocol PhotoServicing {
    func fetchPhotos(page: Int) async throws -> PhotoPage
}

enum PhotoServiceError: LocalizedError, Equatable {
    case missingKey
    case invalidResponse
    case unauthorized
    case rateLimited
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Добавьте Unsplash Access Key в локальный Secrets.plist и пересоберите приложение."
        case .invalidResponse:
            return "Не удалось прочитать ответ сервера. Попробуйте ещё раз."
        case .unauthorized:
            return "Unsplash отклонил ключ доступа. Проверьте Access Key и пересоберите приложение."
        case .rateLimited:
            return "Лимит запросов Unsplash исчерпан. Попробуйте позже."
        case .server:
            return "Unsplash временно недоступен. Попробуйте ещё раз."
        }
    }
}

@MainActor
final class UnsplashPhotoService: PhotoServicing {
    private let accessKey: String?
    private let session: URLSession
    static let pageSize = 30

    init(accessKey: String?, session: URLSession = .shared) {
        self.accessKey = accessKey
        self.session = session
    }

    func fetchPhotos(page: Int) async throws -> PhotoPage {
        guard let accessKey, !accessKey.isEmpty else { throw PhotoServiceError.missingKey }
        var components = URLComponents(string: "https://api.unsplash.com/photos")
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(Self.pageSize))
        ]
        guard let url = components?.url else { throw PhotoServiceError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.timeoutInterval = 30
        // Always revalidate the feed; image responses have their own URLCache.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw PhotoServiceError.invalidResponse }
        switch response.statusCode {
        case 200: break
        case 401: throw PhotoServiceError.unauthorized
        case 403 where response.value(forHTTPHeaderField: "X-Ratelimit-Remaining") == "0":
            throw PhotoServiceError.rateLimited
        case 429: throw PhotoServiceError.rateLimited
        default: throw PhotoServiceError.server(response.statusCode)
        }
        guard let photos = try? JSONDecoder().decode([Photo].self, from: data) else {
            throw PhotoServiceError.invalidResponse
        }
        let link = response.value(forHTTPHeaderField: "Link")
        let hasMore = link.map { $0.contains("rel=\"next\"") } ?? (photos.count == Self.pageSize)
        return PhotoPage(photos: photos, hasMore: hasMore && !photos.isEmpty)
    }
}
