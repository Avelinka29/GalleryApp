final class GalleryViewModel {
    let title = "Галерея"
    private let photos: [LocalPhoto]

    init(photos: [LocalPhoto]) {
        self.photos = photos
    }

    var numberOfPhotos: Int {
        photos.count
    }

    func photo(at index: Int) -> LocalPhoto? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }
}
