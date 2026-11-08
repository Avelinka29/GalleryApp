import Foundation
import Testing
@testable import GalleryApp

@MainActor
struct FavouritesTests {
    @Test("Saving and removing a favourite synchronizes gallery, favourites and details")
    func sharedState() async throws {
        let photo = try makePhoto()
        let repository = FavouritesStub()
        let store = FavouritesStore(repository: repository)
        let gallery = GalleryViewModel(service: EmptyPhotos(), favourites: store)
        let saved = FavouritesViewModel(favourites: store)
        let details = try #require(PhotoDetailsViewModel(photos: [photo], selectedIndex: 0, favourites: store))
        var updates = 0
        gallery.onChange = { updates += 1 }
        await store.load()
        #expect(saved.photos.isEmpty)
        #expect(gallery.canChangeFavourites)
        await gallery.toggleFavourite(photo)
        #expect(details.isFavourite)
        #expect(saved.photos == [photo])
        #expect(repository.photos == [photo])
        #expect(updates > 0)
        #expect(await details.toggleFavourite())
        #expect(!gallery.isFavourite(photo))
        #expect(saved.photos.isEmpty)
    }

    @Test("Failed writes preserve state and can be retried")
    func saveFailure() async throws {
        let photo = try makePhoto()
        let repository = FavouritesStub()
        let store = FavouritesStore(repository: repository)
        await store.load()
        repository.failSave = true
        #expect(await store.toggle(photo) == false)
        #expect(!store.contains(photo))
        #expect(store.errorMessage != nil)
        repository.failSave = false
        #expect(await store.retry())
        repository.failSave = true
        #expect(await store.toggle(photo) == false)
        #expect(store.contains(photo))
        repository.failSave = false
        #expect(await store.retry())
        #expect(store.photos.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test("Read failure does not masquerade as an empty successful load")
    func loadFailure() async throws {
        let repository = FavouritesStub()
        repository.failLoad = true
        let store = FavouritesStore(repository: repository)
        let model = FavouritesViewModel(favourites: store)
        await model.loadNextPage()
        #expect(model.errorMessage != nil)
        #expect(!model.canChangeFavourites)
        #expect(await store.toggle(try makePhoto()) == false)
        repository.failLoad = false
        await model.retry()
        #expect(model.errorMessage == nil)
        #expect(model.canChangeFavourites)
    }

    @Test("Repeated taps during a pending save issue one write", .timeLimit(.minutes(1)))
    func concurrentWrites() async throws {
        let photo = try makePhoto()
        let repository = SuspendedFavourites()
        let store = FavouritesStore(repository: repository)
        await store.load()
        let saving = Task { await store.toggle(photo) }
        await repository.waitForSave()
        #expect(store.isSaving)
        #expect(await store.toggle(photo) == false)
        #expect(repository.writes == 1)
        repository.finish()
        #expect(await saving.value)
        #expect(store.contains(photo))
        #expect(!store.isSaving)
    }

    private func makePhoto() throws -> Photo {
        let url = try #require(URL(string: "https://example.com/photo"))
        return Photo(
            id: "saved-photo", description: nil, altDescription: "Alternative description",
            urls: Photo.ImageURLs(small: url, regular: url),
            user: Photo.Author(name: "Author", links: Photo.Links(html: url))
        )
    }
}

@MainActor
private final class FavouritesStub: FavouritesPersisting {
    var photos: [Photo] = []
    var failSave = false
    var failLoad = false

    func load() async throws -> [Photo] {
        if failLoad { throw CocoaError(.fileReadUnknown) }
        return photos
    }

    func setFavourite(_ photo: Photo, enabled: Bool) async throws {
        if failSave { throw CocoaError(.fileWriteUnknown) }
        photos.removeAll { $0.id == photo.id }
        if enabled { photos.append(photo) }
    }
}

@MainActor
private struct EmptyPhotos: PhotoServicing {
    func fetchPhotos(page: Int) async throws -> PhotoPage {
        PhotoPage(photos: [], hasMore: false)
    }
}

@MainActor
private final class SuspendedFavourites: FavouritesPersisting {
    private var pending: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?
    private(set) var writes = 0

    func load() async throws -> [Photo] { [] }

    func setFavourite(_ photo: Photo, enabled: Bool) async throws {
        writes += 1
        await withCheckedContinuation {
            pending = $0
            started?.resume()
            started = nil
        }
    }

    func waitForSave() async {
        if pending != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func finish() {
        pending?.resume()
        pending = nil
    }
}
