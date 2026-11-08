import Foundation
import Testing
@testable import GalleryApp

struct GalleryAppTests {
    @Test("Description falls back from blank text and trims whitespace")
    func descriptionFallback() throws {
        #expect(try photo(description: "  Main  ", alternative: "Alternative").displayDescription == "Main")
        #expect(try photo(description: " \n ", alternative: "  Alternative  ").displayDescription == "Alternative")
        #expect(try photo(description: nil, alternative: "  ").displayDescription == "Без описания")
    }

    private func photo(description: String?, alternative: String?) throws -> Photo {
        let url = try #require(URL(string: "https://example.com/photo"))
        return Photo(
            id: "description-test", description: description, altDescription: alternative,
            urls: Photo.ImageURLs(small: url, regular: url),
            user: Photo.Author(name: "Author", links: Photo.Links(html: url))
        )
    }
}
