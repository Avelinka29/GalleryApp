struct LocalPhoto: Equatable {
    let id: String
    let imageName: String
    let accessibilityDescription: String

    static let samples: [LocalPhoto] = (10...27).map { number in
        LocalPhoto(
            id: "local-\(number)",
            imageName: "Sample\(number)",
            accessibilityDescription: "Локальная фотография \(number - 9)"
        )
    }
}
