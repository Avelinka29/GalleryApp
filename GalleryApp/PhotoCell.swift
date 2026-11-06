import UIKit

final class PhotoCell: UICollectionViewCell {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureImageView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        accessibilityLabel = nil
    }

    func configure(with photo: LocalPhoto) {
        imageView.image = UIImage(named: photo.imageName) ?? UIImage(systemName: "photo")
        accessibilityLabel = photo.accessibilityDescription
        accessibilityIdentifier = photo.id
    }

    private func configureImageView() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        isAccessibilityElement = true
        accessibilityTraits = .image

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
