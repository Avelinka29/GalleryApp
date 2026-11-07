import Foundation
import Testing
@testable import GalleryApp

@MainActor
struct PhotoDetailsTests {
    @Test("Details preserve selection and stop at the edges of the loaded snapshot")
    func selectionAndBoundaries() throws {
        let photos = try [photo(id: "first"), photo(id: "second")]
        let model = try #require(PhotoDetailsViewModel(photos: photos, selectedIndex: 1))
        #expect(model.title == "2 из 2")
        #expect(model.photo(at: model.selectedIndex)?.id == "second")
        #expect(model.photo(at: -1) == nil)
        #expect(model.photo(at: 2) == nil)
        model.selectPhoto(at: 0)
        #expect(model.title == "1 из 2")
        model.selectPhoto(at: -1)
        model.selectPhoto(at: 2)
        #expect(model.selectedIndex == 0)
        #expect(model.photos == photos)
    }

    @Test("An empty list or stale selection cannot open a details screen")
    func invalidInitialSelection() throws {
        let photos = [try photo(id: "one")]
        #expect(PhotoDetailsViewModel(photos: [], selectedIndex: 0) == nil)
        #expect(PhotoDetailsViewModel(photos: photos, selectedIndex: -1) == nil)
        #expect(PhotoDetailsViewModel(photos: photos, selectedIndex: 1) == nil)
    }

    private func photo(id: String) throws -> Photo {
        let url = try #require(URL(string: "https://example.com/photo"))
        return Photo(
            id: id,
            description: nil,
            altDescription: nil,
            urls: Photo.ImageURLs(small: url, regular: url),
            user: Photo.Author(name: "Author", links: Photo.Links(html: url))
        )
    }
}
