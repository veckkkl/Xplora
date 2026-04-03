//
//  TripPhotoCollageView.swift
//  Xplora

import SnapKit
import UIKit

final class TripPhotoCollageView: UIView {
    enum Section {
        case main
    }

    private struct PhotoItem: Hashable {
        let sourceIndex: Int
        let url: URL
        let overflowCount: Int?
        let removeControlState: Bool
    }

    private let collectionView: UICollectionView
    private var mode: TripPhotoCollageDisplayMode = .noteFull
    private var showsRemoveButtons = false
    private var displayedItems: [PhotoItem] = []
    private var dataSource: UICollectionViewDiffableDataSource<Section, PhotoItem>?
    private var lastLayoutWidth: CGFloat = 0
    private let imageLoader: TripPhotoImageLoading

    var onPhotoTap: ((Int) -> Void)?
    var onPhotoRemove: ((Int) -> Void)?

    override init(frame: CGRect) {
        imageLoader = TripPhotoImageLoader.shared
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        imageLoader = TripPhotoImageLoader.shared
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(coder: coder)
        setupView()
    }

    func configure(urls: [URL], showRemoveButton: Bool = false, mode: TripPhotoCollageDisplayMode = .noteFull) {
        self.showsRemoveButtons = showRemoveButton
        self.mode = mode

        let displayed = TripPhotoCollageLayoutEngine.displayedItems(totalCount: urls.count, mode: mode)
        displayedItems = displayed.compactMap { item in
            guard urls.indices.contains(item.sourceIndex) else { return nil }
            return PhotoItem(
                sourceIndex: item.sourceIndex,
                url: urls[item.sourceIndex],
                overflowCount: item.overflowCount,
                removeControlState: showRemoveButton
            )
        }

        collectionView.isHidden = displayedItems.isEmpty
        let hasOverflowBadge = displayedItems.contains(where: { $0.overflowCount != nil })
        collectionView.setCollectionViewLayout(
            TripPhotoCollageLayoutEngine.makeLayout(
                displayedCount: displayedItems.count,
                mode: mode,
                hasOverflowBadge: hasOverflowBadge
            ),
            animated: false
        )
        applySnapshot()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let currentWidth = collectionView.bounds.width
        guard abs(currentWidth - lastLayoutWidth) > 0.5 else { return }
        lastLayoutWidth = currentWidth
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        let hasOverflowBadge = displayedItems.contains(where: { $0.overflowCount != nil })
        return TripPhotoCollageLayoutEngine.preferredHeight(
            forWidth: width,
            displayedCount: displayedItems.count,
            mode: mode,
            hasOverflowBadge: hasOverflowBadge
        )
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

            let cachedImage = self.imageLoader.cachedImage(for: item.url)
            self.configureCell(cell, item: item, image: cachedImage)

            if cachedImage == nil {
                self.imageLoader.loadImage(from: item.url) { [weak self, weak collectionView, weak cell] image in
                    guard let self, let collectionView, let cell else { return }
                    guard let currentIndexPath = collectionView.indexPath(for: cell),
                          self.displayedItems.indices.contains(currentIndexPath.item) else { return }
                    let currentItem = self.displayedItems[currentIndexPath.item]
                    guard currentItem == item else { return }
                    self.configureCell(cell, item: item, image: image)
                }
            }
            return cell
        }
    }

    private func applySnapshot() {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, PhotoItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(displayedItems, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func configureCell(_ cell: TripPhotoCell, item: PhotoItem, image: UIImage?) {
        cell.configure(
            image: image,
            showRemoveButton: showsRemoveButtons,
            overflowCount: item.overflowCount,
            onRemove: { [weak self] in
                self?.onPhotoRemove?(item.sourceIndex)
            }
        )
    }
}

extension TripPhotoCollageView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard displayedItems.indices.contains(indexPath.item) else { return }
        onPhotoTap?(displayedItems[indexPath.item].sourceIndex)
    }
}
