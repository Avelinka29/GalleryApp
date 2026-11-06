import UIKit

// In UIKit, UIViewController belongs to the View layer of MVVM.
final class ViewController: UIViewController {
    private let viewModel: GalleryViewModel
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeLayout()
    )
    private let cellRegistration = UICollectionView.CellRegistration<PhotoCell, LocalPhoto> { cell, _, photo in
        cell.configure(with: photo)
    }

    init(viewModel: GalleryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // Only the retained, inactive Main.storyboard uses this initializer.
        viewModel = GalleryViewModel(photos: [])
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        view.backgroundColor = .systemBackground
        configureCollectionView()
    }

    private func configureCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.accessibilityIdentifier = "galleryGrid"
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let inset: CGFloat = 16
            let spacing: CGFloat = 12
            let availableWidth = environment.container.effectiveContentSize.width - inset * 2
            // Use the actual container width, so rotation and iPad windows also work.
            let columns = max(2, Int((availableWidth + spacing) / (150 + spacing)))
            let side = max(1, (availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns))
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(side),
                    heightDimension: .fractionalHeight(1)
                )
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(side)
                ),
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: inset, leading: inset, bottom: inset, trailing: inset
            )
            return section
        }
    }
}

extension ViewController: UICollectionViewDataSource {
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
}
