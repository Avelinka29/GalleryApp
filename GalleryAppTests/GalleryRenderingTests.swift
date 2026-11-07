import Foundation
import Testing
import UIKit
@testable import GalleryApp

@MainActor
struct GalleryRenderingTests {
    @Test("Loaded photo creates its first cell without late registration")
    func firstLoadedCell() async throws {
        let url = try #require(URL(string: "https://example.com/test-photo"))
        let photo = Photo(
            id: "loaded-photo",
            description: "Test photo",
            altDescription: nil,
            urls: Photo.ImageURLs(small: url, regular: url),
            user: Photo.Author(name: "Test author", links: Photo.Links(html: url))
        )
        let model = GalleryViewModel(service: LoadedPhotoService(photo: photo))
        await model.loadNextPage()
        let controller = ViewController(viewModel: model, imageLoader: TestImageLoader())
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()

        let stack = try #require(controller.view.subviews.compactMap { $0 as? UIStackView }.first)
        let collection = try #require(stack.arrangedSubviews.compactMap { $0 as? UICollectionView }.first)
        collection.layoutIfNeeded()
        let cell = try #require(collection.cellForItem(at: IndexPath(item: 0, section: 0)) as? PhotoCell)
        #expect(collection.numberOfItems(inSection: 0) == 1)
        #expect(cell.accessibilityIdentifier == photo.id)
    }
}

@MainActor
private struct LoadedPhotoService: PhotoServicing {
    let photo: Photo

    func fetchPhotos(page: Int) async throws -> PhotoPage {
        PhotoPage(photos: [photo], hasMore: false)
    }
}

@MainActor
private struct TestImageLoader: ImageLoading {
    func image(for url: URL) async throws -> UIImage {
        guard let image = UIImage(named: "Sample10") else { throw PhotoServiceError.invalidResponse }
        return image
    }
}
