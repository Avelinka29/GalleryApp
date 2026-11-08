import Foundation

@MainActor
protocol FavouritesObserver: AnyObject {
    func favouritesDidChange()
}

@MainActor
final class FavouritesStore {
    private(set) var photos: [Photo] = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var isLoaded = false
    private(set) var errorMessage: String?
    private let repository: any FavouritesPersisting
    private var observers: [WeakObserver] = []
    private var failedPhoto: Photo?

    init(repository: any FavouritesPersisting) {
        self.repository = repository
    }

    func observe(_ observer: any FavouritesObserver) {
        observers.removeAll { $0.value == nil || $0.value === observer }
        observers.append(WeakObserver(value: observer))
    }

    func contains(_ photo: Photo) -> Bool {
        photos.contains { $0.id == photo.id }
    }

    func load() async {
        guard !isLoading, !isSaving else { return }
        failedPhoto = nil
        isLoading = true
        errorMessage = nil
        notify()
        defer {
            isLoading = false
            notify()
        }
        do {
            photos = try await repository.load()
            isLoaded = true
        } catch {
            errorMessage = "Не удалось прочитать избранное. Попробуйте ещё раз."
        }
    }

    @discardableResult
    func toggle(_ photo: Photo) async -> Bool {
        guard isLoaded, !isLoading, !isSaving else { return false }
        failedPhoto = nil
        let enabled = !contains(photo)
        isSaving = true
        errorMessage = nil
        notify()
        defer {
            isSaving = false
            notify()
        }
        do {
            try await repository.setFavourite(photo, enabled: enabled)
            // Publish only after a successful save; a failed save leaves every screen unchanged.
            photos.removeAll { $0.id == photo.id }
            if enabled { photos.insert(photo, at: 0) }
            return true
        } catch {
            failedPhoto = photo
            errorMessage = "Не удалось сохранить избранное. Попробуйте ещё раз."
            return false
        }
    }

    @discardableResult
    func retry() async -> Bool {
        if let failedPhoto {
            return await toggle(failedPhoto)
        }
        await load()
        return isLoaded && errorMessage == nil
    }

    private func notify() {
        observers.removeAll { $0.value == nil }
        observers.forEach { $0.value?.favouritesDidChange() }
    }

    private final class WeakObserver {
        weak var value: (any FavouritesObserver)?

        init(value: any FavouritesObserver) {
            self.value = value
        }
    }
}
