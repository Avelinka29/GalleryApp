import UIKit

enum GalleryLayout {
    static func make() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let inset: CGFloat = 16
            let spacing: CGFloat = 12
            let availableWidth = environment.container.effectiveContentSize.width - inset * 2
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
                    heightDimension: .absolute(side + 56)
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
