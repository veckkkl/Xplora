//
//  TripPhotoCollageView.swift
//  Xplora

import SnapKit
import UIKit

final class TripPhotoCollageView: UIView {
    enum Mode {
        case note
        case preview
    }

    private enum Section {
        case main
    }

    private enum CollageLayoutCase {
        case one
        case two
        case three
        case four
        case five
        case six
        case seven
        case eight
        case nine
        case tenPreview

        static func make(for count: Int, showOverflowBadge: Bool) -> CollageLayoutCase {
            if showOverflowBadge {
                return .tenPreview
            }

            switch count {
            case 0...1: return .one
            case 2: return .two
            case 3: return .three
            case 4: return .four
            case 5: return .five
            case 6: return .six
            case 7: return .seven
            case 8: return .eight
            default: return .nine
            }
        }
    }

    private struct PhotoItem: Hashable {
        let index: Int
        let url: URL
        let overflowCount: Int?
    }

    private let collectionView: UICollectionView
    private var urls: [URL] = []
    private var mode: Mode = .note
    private var showsRemoveButtons = false
    private var displayedItems: [PhotoItem] = []
    private var dataSource: UICollectionViewDiffableDataSource<Section, PhotoItem>?
    var onPhotoTap: ((Int) -> Void)?
    var onPhotoRemove: ((Int) -> Void)?

    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(coder: coder)
        setupView()
    }

    func configure(urls: [URL], showRemoveButton: Bool = false, mode: Mode = .note) {
        self.urls = urls
        self.showsRemoveButtons = showRemoveButton
        self.mode = mode
        displayedItems = makeDisplayedItems(from: urls, mode: mode)
        collectionView.isHidden = displayedItems.isEmpty
        collectionView.setCollectionViewLayout(makeLayout(for: displayedItems.count, showOverflowBadge: hasOverflowBadge, mode: mode), animated: false)
        applySnapshot()
    }

    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        guard !displayedItems.isEmpty, width > 0 else { return 0 }

        switch mode {
        case .note:
            let columns: CGFloat = 3
            let spacing: CGFloat = 3
            let totalSpacing = spacing * (columns - 1)
            let itemSide = (width - totalSpacing) / columns
            let rows = ceil(CGFloat(displayedItems.count) / columns)
            return rows * itemSide + max(0, rows - 1) * spacing
        case .preview:
            return width * 0.5
        }
    }

    private var hasOverflowBadge: Bool {
        displayedItems.contains(where: { $0.overflowCount != nil })
    }

    private func setupView() {
        clipsToBounds = true
        layer.cornerRadius = 20

        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.contentInset = .zero
        collectionView.register(TripPhotoCell.self, forCellWithReuseIdentifier: TripPhotoCell.reuseIdentifier)
        addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource<Section, PhotoItem>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TripPhotoCell.reuseIdentifier, for: indexPath) as? TripPhotoCell else {
                return UICollectionViewCell()
            }

            let image = self.loadImage(from: item.url)
            cell.configure(
                image: image,
                showRemoveButton: self.showsRemoveButtons,
                overflowCount: item.overflowCount,
                onRemove: { [weak self] in
                    self?.onPhotoRemove?(item.index)
                }
            )
            return cell
        }
    }

    private func makeDisplayedItems(from urls: [URL], mode: Mode) -> [PhotoItem] {
        switch mode {
        case .note:
            return urls.enumerated().map { index, url in
                PhotoItem(index: index, url: url, overflowCount: nil)
            }
        case .preview:
            if urls.count > 9 {
                return Array(urls.prefix(5)).enumerated().map { index, url in
                    let overflowCount = index == 4 ? urls.count - 5 : nil
                    return PhotoItem(index: index, url: url, overflowCount: overflowCount)
                }
            }

            return urls.enumerated().map { index, url in
                PhotoItem(index: index, url: url, overflowCount: nil)
            }
        }
    }

    private func applySnapshot() {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, PhotoItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(displayedItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func makeLayout(for count: Int, showOverflowBadge: Bool, mode: Mode) -> UICollectionViewLayout {
        switch mode {
        case .note:
            return Self.makeNoteLayout()
        case .preview:
            return Self.makePreviewLayout(for: count, showOverflowBadge: showOverflowBadge)
        }
    }

    private static func makeNoteLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = 3

        return UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(1.0 / 3.0)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            return section
        }
    }

    private static func makePreviewLayout(for count: Int, showOverflowBadge: Bool) -> UICollectionViewLayout {
        let spacing: CGFloat = 2
        let layoutCase = CollageLayoutCase.make(for: count, showOverflowBadge: showOverflowBadge)

        return UICollectionViewCompositionalLayout { _, _ in
            let section: NSCollectionLayoutSection

            switch layoutCase {
            case .one:
                section = makeLayoutOne(spacing: spacing)
            case .two:
                section = makeLayoutTwo(spacing: spacing)
            case .three:
                section = makeLayoutThree(spacing: spacing)
            case .four:
                section = makeLayoutFour(spacing: spacing)
            case .five, .tenPreview:
                section = makeLayoutFive(spacing: spacing)
            case .six:
                section = makeLayoutSix(spacing: spacing)
            case .seven:
                section = makeLayoutSeven(spacing: spacing)
            case .eight:
                section = makeLayoutEight(spacing: spacing)
            case .nine:
                section = makeLayoutNine(spacing: spacing)
            }

            section.contentInsets = .zero
            return section
        }
    }
}

extension TripPhotoCollageView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard displayedItems.indices.contains(indexPath.item) else { return }
        onPhotoTap?(displayedItems[indexPath.item].index)
    }
}

private extension TripPhotoCollageView {
    func loadImage(from url: URL) -> UIImage? {
        if url.isFileURL {
            return UIImage(contentsOfFile: url.path)
        }
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    static func fullItem() -> NSCollectionLayoutItem {
        NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )
    }

    static func horizontalGroup(width: CGFloat, height: CGFloat, subitems: [NSCollectionLayoutItem], spacing: CGFloat) -> NSCollectionLayoutGroup {
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(width),
                heightDimension: .fractionalHeight(height)
            ),
            subitems: subitems
        )
        group.interItemSpacing = .fixed(spacing)
        return group
    }

    static func verticalGroup(width: CGFloat, height: CGFloat, subitems: [NSCollectionLayoutItem], spacing: CGFloat) -> NSCollectionLayoutGroup {
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(width),
                heightDimension: .fractionalHeight(height)
            ),
            subitems: subitems
        )
        group.interItemSpacing = .fixed(spacing)
        return group
    }

    static func horizontalGroup(width: CGFloat, height: CGFloat, subitem: NSCollectionLayoutItem, count: Int, spacing: CGFloat) -> NSCollectionLayoutGroup {
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(width),
                heightDimension: .fractionalHeight(height)
            ),
            subitem: subitem,
            count: count
        )
        group.interItemSpacing = .fixed(spacing)
        return group
    }

    static func verticalGroup(width: CGFloat, height: CGFloat, subitem: NSCollectionLayoutItem, count: Int, spacing: CGFloat) -> NSCollectionLayoutGroup {
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(width),
                heightDimension: .fractionalHeight(height)
            ),
            subitem: subitem,
            count: count
        )
        group.interItemSpacing = .fixed(spacing)
        return group
    }

    static func makeSection(group: NSCollectionLayoutGroup) -> NSCollectionLayoutSection {
        NSCollectionLayoutSection(group: group)
    }

    static func makeLayoutOne(spacing: CGFloat) -> NSCollectionLayoutSection {
        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [fullItem()], spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutTwo(spacing: CGFloat) -> NSCollectionLayoutSection {
        let halfItem = fullItem()
        let root = horizontalGroup(width: 1.0, height: 1.0, subitem: halfItem, count: 2, spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutThree(spacing: CGFloat) -> NSCollectionLayoutSection {
        let left = horizontalGroup(width: 0.5, height: 1.0, subitems: [fullItem()], spacing: spacing)
        let rightItem = fullItem()
        let right = horizontalGroup(width: 0.5, height: 1.0, subitem: rightItem, count: 2, spacing: spacing)
        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [left, right], spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutFour(spacing: CGFloat) -> NSCollectionLayoutSection {
        let left = horizontalGroup(width: 0.5, height: 1.0, subitems: [fullItem()], spacing: spacing)

        let stackedItem = fullItem()
        let stackedColumn = verticalGroup(width: 0.5, height: 1.0, subitem: stackedItem, count: 2, spacing: spacing)
        let rightTall = horizontalGroup(width: 0.5, height: 1.0, subitems: [fullItem()], spacing: spacing)
        let right = horizontalGroup(width: 0.5, height: 1.0, subitems: [stackedColumn, rightTall], spacing: spacing)

        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [left, right], spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutFive(spacing: CGFloat) -> NSCollectionLayoutSection {
        let left = horizontalGroup(width: 0.5, height: 1.0, subitems: [fullItem()], spacing: spacing)

        let smallItem = fullItem()
        let topRow = horizontalGroup(width: 1.0, height: 0.5, subitem: smallItem, count: 2, spacing: spacing)
        let bottomRow = horizontalGroup(width: 1.0, height: 0.5, subitem: fullItem(), count: 2, spacing: spacing)
        let right = verticalGroup(width: 0.5, height: 1.0, subitems: [topRow, bottomRow], spacing: spacing)

        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [left, right], spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutSix(spacing: CGFloat) -> NSCollectionLayoutSection {
        let leftTop = horizontalGroup(width: 1.0, height: 2.0 / 3.0, subitems: [fullItem()], spacing: spacing)
        let leftBottom = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let left = verticalGroup(width: 0.5, height: 1.0, subitems: [leftTop, leftBottom], spacing: spacing)

        let rightTop = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitems: [fullItem()], spacing: spacing)
        let rightBottom = horizontalGroup(width: 1.0, height: 2.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let right = verticalGroup(width: 0.5, height: 1.0, subitems: [rightTop, rightBottom], spacing: spacing)

        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [left, right], spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutSeven(spacing: CGFloat) -> NSCollectionLayoutSection {
        let leftTop = horizontalGroup(width: 1.0, height: 2.0 / 3.0, subitems: [fullItem()], spacing: spacing)
        let leftBottom = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let left = verticalGroup(width: 0.5, height: 1.0, subitems: [leftTop, leftBottom], spacing: spacing)

        let rightTop = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let rightBottom = horizontalGroup(width: 1.0, height: 2.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let right = verticalGroup(width: 0.5, height: 1.0, subitems: [rightTop, rightBottom], spacing: spacing)

        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [left, right], spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutEight(spacing: CGFloat) -> NSCollectionLayoutSection {
        let leftTop = horizontalGroup(width: 1.0, height: 2.0 / 3.0, subitems: [fullItem()], spacing: spacing)
        let leftBottom = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let left = verticalGroup(width: 0.5, height: 1.0, subitems: [leftTop, leftBottom], spacing: spacing)

        let rightTop = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let rightBottomLeft = verticalGroup(width: 0.5, height: 1.0, subitem: fullItem(), count: 2, spacing: spacing)
        let rightBottomRight = horizontalGroup(width: 0.5, height: 1.0, subitems: [fullItem()], spacing: spacing)
        let rightBottom = horizontalGroup(width: 1.0, height: 2.0 / 3.0, subitems: [rightBottomLeft, rightBottomRight], spacing: spacing)
        let right = verticalGroup(width: 0.5, height: 1.0, subitems: [rightTop, rightBottom], spacing: spacing)

        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [left, right], spacing: spacing)
        return makeSection(group: root)
    }

    static func makeLayoutNine(spacing: CGFloat) -> NSCollectionLayoutSection {
        let leftTop = horizontalGroup(width: 1.0, height: 2.0 / 3.0, subitems: [fullItem()], spacing: spacing)
        let leftBottom = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let left = verticalGroup(width: 0.5, height: 1.0, subitems: [leftTop, leftBottom], spacing: spacing)

        let rightRow1 = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let rightRow2 = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let rightRow3 = horizontalGroup(width: 1.0, height: 1.0 / 3.0, subitem: fullItem(), count: 2, spacing: spacing)
        let right = verticalGroup(width: 0.5, height: 1.0, subitems: [rightRow1, rightRow2, rightRow3], spacing: spacing)

        let root = horizontalGroup(width: 1.0, height: 1.0, subitems: [left, right], spacing: spacing)
        return makeSection(group: root)
    }
}
