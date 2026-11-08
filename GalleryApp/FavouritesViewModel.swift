import Foundation

@MainActor
final class FavouritesViewModel: PhotoGridViewModel, FavouritesObserver {
    let title = "Избранное"
    let emptyMessage = "В избранном пока пусто. Нажмите сердечко у фотографии."
    let favourites: FavouritesStore?
    var onChange: (() -> Void)?
    var photos: [Photo] { favourites?.photos ?? [] }
    var numberOfPhotos: Int { photos.count }
    var isLoading: Bool { favourites?.isLoading ?? false }
    var errorMessage: String? { favourites?.errorMessage }

    init(favourites: FavouritesStore) {
        self.favourites = favourites
        favourites.observe(self)
    }

    func photo(at index: Int) -> Photo? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }

    func loadNextPage() async {
        guard favourites?.isLoaded == false, favourites?.errorMessage == nil else { return }
        await favourites?.load()
    }

    func refresh() async {
        await favourites?.load()
    }

    func retry() async {
        await favourites?.retry()
    }

    func favouritesDidChange() {
        onChange?()
    }
}
