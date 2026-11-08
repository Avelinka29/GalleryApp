import Foundation
import Testing
@testable import GalleryApp

@MainActor
struct GalleryPaginationTests {
    @Test("Failed page preserves photos and retry requests the same page")
    func failedPageRetry() async throws {
        let first = try photo(id: "first")
        let second = try photo(id: "second")
        let service = StubPhotoService(results: [
            .success(PhotoPage(photos: [first], hasMore: true)),
            .failure(URLError(.notConnectedToInternet)),
            .success(PhotoPage(photos: [first, second], hasMore: false))
        ])
        let model = GalleryViewModel(service: service)

        await model.loadNextPage()
        await model.loadNextPage()
        #expect(model.photos == [first])
        #expect(model.errorMessage != nil)
        // Scrolling while an error is visible must not repeatedly hit the API.
        await model.loadNextPage()
        #expect(service.requestedPages == [1, 2])

        await model.retry()
        #expect(model.photos == [first, second])
        #expect(model.errorMessage == nil)
        #expect(!model.hasMore)
        await model.loadNextPage()
        #expect(service.requestedPages == [1, 2, 2])
    }

    @Test("Overlapping load calls issue only one request", .timeLimit(.minutes(1)))
    func overlappingRequests() async throws {
        let service = SuspendedPhotoService()
        let model = GalleryViewModel(service: service)
        let loading = Task { await model.loadNextPage() }
        await service.waitUntilRequested()

        #expect(model.isLoading)
        await model.loadNextPage()
        await model.refresh()
        #expect(service.requestedPages == [1])

        service.finish(PhotoPage(photos: [try photo(id: "one")], hasMore: false))
        await loading.value
        #expect(!model.isLoading)
        #expect(model.numberOfPhotos == 1)
    }

    @Test("Refresh failure retains content and retry restarts at page one")
    func refreshRetry() async throws {
        let old = try photo(id: "old")
        let replacement = try photo(id: "replacement")
        let service = StubPhotoService(results: [
            .success(PhotoPage(photos: [old], hasMore: false)),
            .failure(URLError(.timedOut)),
            .success(PhotoPage(photos: [replacement], hasMore: false))
        ])
        let model = GalleryViewModel(service: service)
        await model.loadNextPage()
        await model.refresh()
        #expect(model.photos == [old])
        await model.retry()
        #expect(model.photos == [replacement])
        #expect(service.requestedPages == [1, 1, 1])
    }

    @Test("Empty feed stops pagination and manual retry reloads page one")
    func emptyPage() async {
        let service = StubPhotoService(results: [
            .success(PhotoPage(photos: [], hasMore: false)),
            .success(PhotoPage(photos: [], hasMore: false))
        ])
        let model = GalleryViewModel(service: service)
        await model.loadNextPage()
        await model.loadNextPage()
        #expect(model.numberOfPhotos == 0)
        #expect(!model.hasMore)
        #expect(model.errorMessage == nil)
        #expect(service.requestedPages == [1])
        await model.retry()
        #expect(service.requestedPages == [1, 1])
    }

    @Test("Missing descriptions decode and use a readable fallback")
    func missingDescription() throws {
        let image = try photo(id: "without-description")
        #expect(image.displayDescription == "Без описания")
        let query = URLComponents(url: image.attributionURL, resolvingAgainstBaseURL: false)?.queryItems
        #expect(query?.contains(URLQueryItem(name: "utm_source", value: "gallery_app")) == true)
    }

    @Test("A cancelled request discards its late response and retries the same page")
    func cancelledResponse() async throws {
        let service = SuspendedPhotoService()
        let model = GalleryViewModel(service: service)
        let loading = Task { await model.loadNextPage() }
        await service.waitUntilRequested()
        loading.cancel()
        service.finish(PhotoPage(photos: [try photo(id: "discarded")], hasMore: true))
        await loading.value
        #expect(model.photos.isEmpty)
        #expect(model.errorMessage == nil)
        #expect(!model.isLoading)
        let retry = Task { await model.loadNextPage() }
        await service.waitUntilRequested()
        #expect(service.requestedPages == [1, 1])
        service.finish(PhotoPage(photos: [try photo(id: "accepted")], hasMore: false))
        await retry.value
        #expect(model.photos.map(\.id) == ["accepted"])
    }

    private func photo(id: String) throws -> Photo {
        let json = """
        {
            "id": "\(id)", "description": null, "alt_description": null,
            "urls": {"small": "https://images.unsplash.com/small", "regular": "https://images.unsplash.com/regular"},
            "user": {"name": "Example", "links": {"html": "https://unsplash.com/@example"}}
        }
        """
        return try JSONDecoder().decode(Photo.self, from: Data(json.utf8))
    }
}

@MainActor
private final class StubPhotoService: PhotoServicing {
    private var results: [Result<PhotoPage, Error>]
    private(set) var requestedPages: [Int] = []

    init(results: [Result<PhotoPage, Error>]) {
        self.results = results
    }

    func fetchPhotos(page: Int) async throws -> PhotoPage {
        requestedPages.append(page)
        guard !results.isEmpty else { throw PhotoServiceError.invalidResponse }
        return try results.removeFirst().get()
    }
}

@MainActor
private final class SuspendedPhotoService: PhotoServicing {
    private(set) var requestedPages: [Int] = []
    private var response: CheckedContinuation<PhotoPage, Error>?
    private var start: CheckedContinuation<Void, Never>?

    func fetchPhotos(page: Int) async throws -> PhotoPage {
        requestedPages.append(page)
        return try await withCheckedThrowingContinuation { continuation in
            response = continuation
            start?.resume()
            start = nil
        }
    }

    func waitUntilRequested() async {
        guard response == nil else { return }
        await withCheckedContinuation { start = $0 }
    }

    func finish(_ page: PhotoPage) {
        response?.resume(returning: page)
        response = nil
    }
}
