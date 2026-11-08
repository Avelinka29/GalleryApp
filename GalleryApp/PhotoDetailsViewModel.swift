import Foundation

@MainActor
final class PhotoDetailsViewModel: FavouritesObserver {
    let favourites: FavouritesStore?
    var onChange: (() -> Void)?
    var errorMessage: String? { favourites?.errorMessage }
    var isFavourite: Bool { favourites?.contains(photos[selectedIndex]) ?? false }
    var canChangeFavourite: Bool {
        guard let favourites else { return false }
        return favourites.isLoaded && !favourites.isLoading && !favourites.isSaving
    }

    func toggleFavourite() async -> Bool {
        await favourites?.toggle(photos[selectedIndex]) ?? false
    }

    func retryFavourite() async -> Bool {
        await favourites?.retry() ?? false
    }

    func favouritesDidChange() {
        onChange?()
    }
    let photos: [Photo]
    private(set) var selectedIndex: Int

    init?(photos: [Photo], selectedIndex: Int, favourites: FavouritesStore? = nil) {
        guard photos.indices.contains(selectedIndex) else { return nil }
        self.photos = photos
        self.selectedIndex = selectedIndex
        self.favourites = favourites
        favourites?.observe(self)
    }

    var title: String { "\(selectedIndex + 1) из \(photos.count)" }

    func photo(at index: Int) -> Photo? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }

    func selectPhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        selectedIndex = index
        onChange?()
    }
}
