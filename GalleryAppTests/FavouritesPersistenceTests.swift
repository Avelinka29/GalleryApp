import Foundation
import Testing
@testable import GalleryApp

@MainActor
struct FavouritesPersistenceTests {
    @Test("SQLite favourites survive a new repository, avoid duplicates and persist deletion")
    func persistence() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Test.sqlite")
        let url = try #require(URL(string: "https://example.com/photo"))
        let photo = Photo(
            id: "persisted", description: "Description", altDescription: nil,
            urls: Photo.ImageURLs(small: url, regular: url),
            user: Photo.Author(name: "Author", links: Photo.Links(html: url))
        )
        try await saveTwice(photo, to: storeURL)
        let reopened = FavouritesRepository(storeURL: storeURL)
        #expect(try await reopened.load() == [photo])
        try await reopened.setFavourite(photo, enabled: false)
        let afterDeletion = FavouritesRepository(storeURL: storeURL)
        #expect(try await afterDeletion.load().isEmpty)
    }

    private func saveTwice(_ photo: Photo, to url: URL) async throws {
        let repository = FavouritesRepository(storeURL: url)
        #expect(try await repository.load().isEmpty)
        try await repository.setFavourite(photo, enabled: true)
        try await repository.setFavourite(photo, enabled: true)
    }
}
