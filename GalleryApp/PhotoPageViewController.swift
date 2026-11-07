import UIKit

final class PhotoPageViewController: UIViewController {
    let index: Int
    private let photo: Photo
    private let imageLoader: any ImageLoading
    private let imageView = UIImageView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let retryButton = UIButton(type: .system)
    private var imageTask: Task<Void, Never>?
    var onOpenAttribution: ((URL) -> Void)?

    init(photo: Photo, index: Int, imageLoader: any ImageLoading) {
        self.photo = photo
        self.index = index
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if imageView.image == nil { loadImage() }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageTask?.cancel()
        imageTask = nil
    }

    private func configureViews() {
        view.backgroundColor = .systemBackground
        let scrollView = UIScrollView()
        let descriptionLabel = UILabel()
        descriptionLabel.text = photo.displayDescription
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.accessibilityIdentifier = "photoDescription"
        let creditButton = UIButton(type: .system)
        creditButton.setTitle("\(photo.user.name) · Unsplash ↗", for: .normal)
        creditButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        creditButton.titleLabel?.adjustsFontForContentSizeCategory = true
        creditButton.titleLabel?.numberOfLines = 0
        creditButton.accessibilityHint = "Открывает страницу автора в браузере"
        creditButton.addTarget(self, action: #selector(openAttribution), for: .touchUpInside)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = photo.displayDescription
        imageView.accessibilityIdentifier = "detailImage"
        retryButton.setTitle("Не удалось загрузить. Повторить", for: .normal)
        retryButton.titleLabel?.numberOfLines = 0
        retryButton.addTarget(self, action: #selector(loadImage), for: .touchUpInside)
        retryButton.isHidden = true
        let imageContainer = UIView()
        for item in [imageView, spinner, retryButton] {
            item.translatesAutoresizingMaskIntoConstraints = false
            imageContainer.addSubview(item)
        }
        let stack = UIStackView(arrangedSubviews: [imageContainer, descriptionLabel, creditButton])
        stack.axis = .vertical
        stack.spacing = 16
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        configureLayout(scrollView: scrollView, stack: stack, imageContainer: imageContainer)
    }

    private func configureLayout(scrollView: UIScrollView, stack: UIStackView, imageContainer: UIView) {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
            imageContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.65),
            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            retryButton.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            retryButton.widthAnchor.constraint(lessThanOrEqualTo: imageContainer.widthAnchor, constant: -16)
        ])
    }

    @objc private func loadImage() {
        imageTask?.cancel()
        retryButton.isHidden = true
        spinner.startAnimating()
        let url = photo.urls.regular
        imageTask = Task { [weak self, imageLoader] in
            do {
                let image = try await imageLoader.image(for: url)
                guard !Task.isCancelled, let self else { return }
                imageView.image = image
                spinner.stopAnimating()
            } catch {
                guard !Task.isCancelled, let self else { return }
                spinner.stopAnimating()
                retryButton.isHidden = false
            }
        }
    }

    @objc private func openAttribution() {
        onOpenAttribution?(photo.attributionURL)
    }
}
