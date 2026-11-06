import UIKit

@MainActor
protocol ImageLoading {
    func image(for url: URL) async throws -> UIImage
}

@MainActor
final class ImageLoader: ImageLoading {
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    private var requests: [URL: Task<UIImage, Error>] = [:]

    init(session: URLSession? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 16 * 1_024 * 1_024,
            diskCapacity: 100 * 1_024 * 1_024,
            directory: nil
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.timeoutIntervalForRequest = 30
        self.session = session ?? URLSession(configuration: configuration)
        cache.totalCostLimit = 48 * 1_024 * 1_024
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        if let request = requests[url] { return try await request.value }

        let request = Task<UIImage, Error> { [session] in
            let (data, response) = try await session.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let image = UIImage(data: data),
                  let thumbnail = await image.byPreparingThumbnail(ofSize: CGSize(width: 600, height: 600)) else {
                throw PhotoServiceError.invalidResponse
            }
            return thumbnail
        }
        requests[url] = request
        defer { requests[url] = nil }
        let image = try await request.value
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
        return image
    }
}
