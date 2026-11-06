import Foundation

@MainActor
final class GalleryViewModel {
    let title = "Галерея"
    private(set) var photos: [Photo] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var hasMore = true
    var onChange: (() -> Void)?

    private let service: any PhotoServicing
    private var nextPage = 1
    private var failedRefresh = false

    init(service: any PhotoServicing) {
        self.service = service
    }

    var numberOfPhotos: Int { photos.count }

    func photo(at index: Int) -> Photo? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }

    func loadNextPage() async {
        guard hasMore, errorMessage == nil else { return }
        await load(refreshing: false)
    }

    func refresh() async {
        await load(refreshing: true)
    }

    func retry() async {
        await load(refreshing: errorMessage == nil || failedRefresh)
    }

    private func load(refreshing: Bool) async {
        // Set this before the first await: repeated scroll callbacks cannot start a second request.
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        onChange?()
        defer {
            isLoading = false
            onChange?()
        }

        let requestedPage = refreshing ? 1 : nextPage
        do {
            let result = try await service.fetchPhotos(page: requestedPage)
            try Task.checkCancellation()
            var updated = refreshing ? [] : photos
            var identifiers = Set(updated.map(\.id))
            for photo in result.photos where identifiers.insert(photo.id).inserted {
                updated.append(photo)
            }
            photos = updated
            nextPage = requestedPage + 1
            hasMore = result.hasMore
            failedRefresh = false
        } catch is CancellationError {
            // Cancellation is not a user-facing failure and does not advance the page.
        } catch let error as URLError where error.code == .cancelled {
            // URLSession uses URLError.cancelled when its task is cancelled.
        } catch {
            failedRefresh = refreshing
            if let serviceError = error as? PhotoServiceError {
                errorMessage = serviceError.localizedDescription
            } else if let networkError = error as? URLError,
                      networkError.code == .notConnectedToInternet {
                errorMessage = "Нет подключения к интернету. Проверьте сеть и повторите."
            } else {
                errorMessage = "Не удалось загрузить фотографии. Попробуйте ещё раз."
            }
        }
    }
}
