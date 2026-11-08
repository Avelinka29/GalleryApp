import UIKit

// UIKit controllers belong to the View layer of MVVM.
final class ViewController: UIViewController {
    private let viewModel: any PhotoGridViewModel
    private let imageLoader: any ImageLoading
    var onOpenAttribution: ((URL) -> Void)?
    var onSelectPhoto: (([Photo], Int) -> Void)?
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: GalleryLayout.make())
    private let refreshControl = UIRefreshControl()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let footer = UIStackView()
    private var renderedPhotos: [Photo] = []
    private typealias PhotoRegistration = UICollectionView.CellRegistration<PhotoCell, Photo>
    private lazy var cellRegistration = PhotoRegistration { [weak self] cell, _, photo in
        guard let self else { return }
        cell.configureFavourite(
            selected: viewModel.isFavourite(photo),
            enabled: viewModel.canChangeFavourites
        ) { [weak self] in
            guard let self else { return }
            Task { await self.viewModel.toggleFavourite(photo) }
        }
        cell.configure(with: photo, imageLoader: imageLoader) { [weak self] url in
            self?.onOpenAttribution?(url)
        }
    }

    init(viewModel: any PhotoGridViewModel, imageLoader: any ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        viewModel = GalleryViewModel(service: UnsplashPhotoService(accessKey: APIConfiguration.accessKey()))
        imageLoader = ImageLoader()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        view.backgroundColor = .systemBackground
        configureViews()
        viewModel.onChange = { [weak self] in self?.render() }
        render()
        Task { await viewModel.loadNextPage() }
    }

    private func configureViews() {
        // UIKit requires registration before the first cell-provider callback.
        _ = cellRegistration
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "galleryGrid"
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        retryButton.setTitle("Повторить", for: .normal)
        retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        footer.axis = .vertical
        footer.alignment = .center
        footer.spacing = 4
        for item in [spinner, statusLabel, retryButton] { footer.addArrangedSubview(item) }
        let stack = UIStackView(arrangedSubviews: [collectionView, footer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: footer.widthAnchor, constant: -32)
        ])
    }

    private var displayedError: String? {
        viewModel.errorMessage ?? viewModel.favouritesErrorMessage
    }

    private func render() {
        let photos = viewModel.photos
        if renderedPhotos != photos {
            let previousCount = renderedPhotos.count
            let isAppend = !renderedPhotos.isEmpty
                && photos.starts(with: renderedPhotos)
                && photos.count > previousCount
            renderedPhotos = photos
            if isAppend {
                collectionView.insertItems(at: (previousCount..<photos.count).map { IndexPath(item: $0, section: 0) })
            } else {
                collectionView.reloadData()
            }
        }
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell,
                  let photo = viewModel.photo(at: indexPath.item) else { continue }
            cell.updateFavourite(selected: viewModel.isFavourite(photo), enabled: viewModel.canChangeFavourites)
        }
        if !viewModel.isLoading { refreshControl.endRefreshing() }
        renderEmptyState()
        footer.isHidden = viewModel.photos.isEmpty
        spinner.isHidden = !viewModel.isLoading
        if viewModel.isLoading { spinner.startAnimating() } else { spinner.stopAnimating() }
        statusLabel.text = displayedError
        statusLabel.isHidden = displayedError == nil
        retryButton.isHidden = displayedError == nil
        if !viewModel.isLoading && displayedError == nil {
            footer.isHidden = true
        }
    }

    private func renderEmptyState() {
        guard viewModel.photos.isEmpty else {
            contentUnavailableConfiguration = nil
            return
        }
        if viewModel.isLoading {
            var configuration = UIContentUnavailableConfiguration.loading()
            configuration.text = "Загружаем фотографии…"
            contentUnavailableConfiguration = configuration
        } else {
            var configuration = UIContentUnavailableConfiguration.empty()
            let symbol = displayedError == nil ? "photo.on.rectangle" : "wifi.exclamationmark"
            configuration.image = UIImage(systemName: symbol)
            configuration.text = displayedError == nil ? viewModel.emptyMessage : "Не удалось загрузить"
            configuration.secondaryText = displayedError
            configuration.button.title = "Повторить"
            configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in self?.retry() }
            contentUnavailableConfiguration = configuration
        }
    }

    @objc private func refresh() {
        Task {
            await viewModel.refresh()
            refreshControl.endRefreshing()
        }
    }

    @objc private func retry() {
        Task {
            if viewModel.favouritesErrorMessage != nil {
                await viewModel.retryFavourites()
            } else {
                await viewModel.retry()
            }
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard viewModel.photo(at: indexPath.item) != nil else { return }
        onSelectPhoto?(viewModel.photos, indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfPhotos
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        collectionView.dequeueConfiguredReusableCell(
            using: cellRegistration,
            for: indexPath,
            item: viewModel.photo(at: indexPath.item)
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard indexPath.item >= viewModel.numberOfPhotos - 6 else { return }
        Task { await viewModel.loadNextPage() }
    }
}
