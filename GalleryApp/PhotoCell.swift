import UIKit

final class PhotoCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let retryButton = UIButton(type: .system)
    private let creditButton = UIButton(type: .system)
    private var imageTask: Task<Void, Never>?
    private var photo: Photo?
    private var imageLoader: (any ImageLoading)?
    private var onAttribution: ((URL) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        photo = nil
        imageLoader = nil
        onAttribution = nil
        imageView.image = nil
        imageView.accessibilityLabel = nil
        creditButton.setTitle(nil, for: .normal)
        retryButton.isHidden = true
        spinner.stopAnimating()
    }

    func configure(with photo: Photo, imageLoader: any ImageLoading, onAttribution: @escaping (URL) -> Void) {
        self.photo = photo
        self.imageLoader = imageLoader
        self.onAttribution = onAttribution
        accessibilityIdentifier = photo.id
        imageView.accessibilityLabel = photo.displayDescription
        creditButton.setTitle("\(photo.user.name)\non Unsplash", for: .normal)
        creditButton.accessibilityLabel = "Автор: \(photo.user.name), Unsplash"
        loadImage()
    }

    @objc private func loadImage() {
        guard let photo, let imageLoader else { return }
        imageTask?.cancel()
        imageView.image = nil
        retryButton.isHidden = true
        spinner.startAnimating()
        imageTask = Task { [weak self] in
            do {
                let image = try await imageLoader.image(for: photo.urls.small)
                // A late response must never replace a reused cell's current photo.
                guard !Task.isCancelled, self?.photo?.id == photo.id else { return }
                self?.imageView.image = image
                self?.spinner.stopAnimating()
            } catch {
                guard !Task.isCancelled, self?.photo?.id == photo.id else { return }
                self?.spinner.stopAnimating()
                self?.retryButton.isHidden = false
            }
        }
    }

    @objc private func openAttribution() {
        guard let photo else { return }
        onAttribution?(photo.attributionURL)
    }

    private func configureViews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .image
        creditButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        creditButton.titleLabel?.numberOfLines = 2
        creditButton.titleLabel?.textAlignment = .center
        creditButton.addTarget(self, action: #selector(openAttribution), for: .touchUpInside)
        retryButton.setTitle("Повторить", for: .normal)
        retryButton.accessibilityLabel = "Повторить загрузку фотографии"
        retryButton.addTarget(self, action: #selector(loadImage), for: .touchUpInside)
        retryButton.isHidden = true

        for subview in [imageView, spinner, retryButton, creditButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            creditButton.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            creditButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            creditButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            creditButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            retryButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }
}
