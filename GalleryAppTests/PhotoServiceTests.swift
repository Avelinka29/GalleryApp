import Foundation
import Testing
import UIKit
@testable import GalleryApp

@Suite(.serialized)
@MainActor
struct PhotoServiceTests {
    @Test("List Photos sends page, per_page and header authentication")
    func listPhotosRequest() async throws {
        let json = """
        [{
            "id": "one", "description": null, "alt_description": "A mountain",
            "urls": {"small": "https://images.unsplash.com/small", "regular": "https://images.unsplash.com/regular"},
            "user": {"name": "Example", "links": {"html": "https://unsplash.com/@example"}}
        }]
        """
        StubURLProtocol.configure(
            status: 200,
            headers: ["Link": "<https://api.unsplash.com/photos?page=4>; rel=\"next\""],
            data: Data(json.utf8)
        )
        let service = UnsplashPhotoService(accessKey: "test-key", session: session())
        let page = try await service.fetchPhotos(page: 3)
        let request = try #require(StubURLProtocol.lastRequest)
        let url = try #require(request.url)
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(url.host == "api.unsplash.com")
        #expect(url.path == "/photos")
        #expect(query?.contains(URLQueryItem(name: "page", value: "3")) == true)
        #expect(query?.contains(URLQueryItem(name: "per_page", value: "30")) == true)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Client-ID test-key")
        #expect(!url.absoluteString.contains("test-key"))
        #expect(page.photos.first?.displayDescription == "A mountain")
        #expect(page.hasMore)
    }

    @Test("Rate-limit response becomes a specific recoverable error")
    func rateLimit() async {
        StubURLProtocol.configure(status: 403, headers: ["X-Ratelimit-Remaining": "0"], data: Data())
        let service = UnsplashPhotoService(accessKey: "test-key", session: session())
        do {
            _ = try await service.fetchPhotos(page: 1)
            Issue.record("Expected a rate-limit error")
        } catch {
            #expect(error as? PhotoServiceError == .rateLimited)
        }
    }

    @Test("Missing key fails before any network request")
    func missingKey() async {
        StubURLProtocol.configure(status: 200, headers: [:], data: Data("[]".utf8))
        let service = UnsplashPhotoService(accessKey: nil, session: session())
        do {
            _ = try await service.fetchPhotos(page: 1)
            Issue.record("Expected missing-key error")
        } catch {
            #expect(error as? PhotoServiceError == .missingKey)
        }
        #expect(StubURLProtocol.requestCount == 0)
    }

    @Test("Concurrent image requests and memory cache share one download")
    func imageCache() async throws {
        let source = try #require(UIImage(named: "Sample10", in: Bundle.main, compatibleWith: nil))
        let data = try #require(source.jpegData(compressionQuality: 0.8))
        StubURLProtocol.configure(status: 200, headers: ["Content-Type": "image/jpeg"], data: data)
        let loader = ImageLoader(session: session())
        let url = try #require(URL(string: "https://images.unsplash.com/test-image"))
        async let first = loader.image(for: url)
        async let second = loader.image(for: url)
        let (firstImage, secondImage) = try await (first, second)
        let cached = try await loader.image(for: url)
        #expect(firstImage === secondImage)
        #expect(cached === firstImage)
        #expect(StubURLProtocol.requestCount == 1)
        #expect(firstImage.size.width <= 600)
        #expect(firstImage.size.height <= 600)
    }

    private func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var status = 200
    nonisolated(unsafe) private static var headers: [String: String] = [:]
    nonisolated(unsafe) private static var data = Data()
    nonisolated(unsafe) private static var requests: [URLRequest] = []

    static var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return requests.last
    }

    static var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return requests.count
    }

    static func configure(status: Int, headers: [String: String], data: Data) {
        lock.lock()
        defer { lock.unlock() }
        self.status = status
        self.headers = headers
        self.data = data
        requests = []
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.requests.append(request)
        let status = Self.status
        let headers = Self.headers
        let data = Self.data
        Self.lock.unlock()
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url, statusCode: status, httpVersion: nil, headerFields: headers
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
