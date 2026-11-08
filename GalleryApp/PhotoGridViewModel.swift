import Foundation

@MainActor
protocol PhotoGridViewModel: AnyObject {
    var title: String { get }
    var emptyMessage: String { get }
    var photos: [Photo] { get }
    var numberOfPhotos: Int { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var favourites: FavouritesStore? { get }
    var onChange: (() -> Void)? { get set }
    func photo(at index: Int) -> Photo?
    func loadNextPage() async
    func refresh() async
    func retry() async
}

extension PhotoGridViewModel {
    var emptyMessage: String { "Фотографий пока нет" }
    var favouritesErrorMessage: String? { favourites?.errorMessage }

    func retryFavourites() async {
        await favourites?.retry()
    }

    var canChangeFavourites: Bool {
        guard let favourites else { return false }
        return favourites.isLoaded && !favourites.isLoading && !favourites.isSaving
    }

    func isFavourite(_ photo: Photo) -> Bool {
        favourites?.contains(photo) ?? false
    }

    func toggleFavourite(_ photo: Photo) async {
        await favourites?.toggle(photo)
    }
}
