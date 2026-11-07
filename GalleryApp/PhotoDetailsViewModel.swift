import Foundation

@MainActor
final class PhotoDetailsViewModel {
    let photos: [Photo]
    private(set) var selectedIndex: Int

    init?(photos: [Photo], selectedIndex: Int) {
        guard photos.indices.contains(selectedIndex) else { return nil }
        self.photos = photos
        self.selectedIndex = selectedIndex
    }

    var title: String { "\(selectedIndex + 1) из \(photos.count)" }

    func photo(at index: Int) -> Photo? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }

    func selectPhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        selectedIndex = index
    }
}
