//
//  TripPhotoCollageView.swift
//  Xplora

import SnapKit
import UIKit

final class TripPhotoCollageView: UIView {
    enum Section {
        case main
    }

    private enum CollageItem: Hashable {
        case photo(PhotoItem)
        case add(enabled: Bool)
    }

    private struct PhotoItem: Hashable {
        // The URL acts as the photo's stable identity, so a tile that just
        // shifts position (e.g. after removing a sibling) keeps its hash and
        // the diffable data source can animate it as a move instead of a
        // delete+insert. The other fields participate in the hash so cells
        // are reconfigured when their visual state actually changes.
        let url: URL
        let overflowCount: Int?
        let removeControlState: Bool
    }

    private let collectionView: UICollectionView
    private var mode: TripPhotoCollageDisplayMode = .noteFull
    private var showsRemoveButtons = false
    private var displayedItems: [CollageItem] = []
    private var dataSource: UICollectionViewDiffableDataSource<Section, CollageItem>?
    private var lastLayoutWidth: CGFloat = 0
    private var lastURLs: [URL] = []
    private let imageLoader: TripPhotoImageLoading

    var onPhotoTap: ((Int) -> Void)?
    var onPhotoRemove: ((Int) -> Void)?
    var onAddPhoto: (() -> Void)?

    override init(frame: CGRect) {
        imageLoader = TripPhotoImageLoader.shared
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(frame: frame)
        setupAdaptiveLayout()
        setupView()
    }

    required init?(coder: NSCoder) {
        imageLoader = TripPhotoImageLoader.shared
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        super.init(coder: coder)
        setupAdaptiveLayout()
        setupView()
    }

    private func setupAdaptiveLayout() {
        // One layout, queried lazily — invalidating it on configure swaps the
        // collage case (e.g. `.five` → `.four` after delete) without ever
        // letting the data source and layout disagree about item count.
        let layout = TripPhotoCollageLayoutEngine.makeAdaptiveLayout { [weak self] in
            guard let self else {
                return TripPhotoCollageLayoutEngine.AdaptiveLayoutSpec(
                    displayedCount: 0,
                    mode: .noteFull,
                    hasOverflowBadge: false
                )
            }
            let hasOverflowBadge = self.displayedItems.contains { item in
                if case let .photo(p) = item, p.overflowCount != nil { return true }
                return false
            }
            return TripPhotoCollageLayoutEngine.AdaptiveLayoutSpec(
                displayedCount: self.displayedItems.count,
                mode: self.mode,
                hasOverflowBadge: hasOverflowBadge
            )
        }
        collectionView.collectionViewLayout = layout
    }

    func configure(
        urls: [URL],
        showRemoveButton: Bool = false,
        showAddPlaceholder: Bool = false,
        addPlaceholderEnabled: Bool = true,
        mode: TripPhotoCollageDisplayMode = .noteFull
    ) {
        self.showsRemoveButtons = showRemoveButton
        self.mode = mode
        self.lastURLs = urls

        let displayed = TripPhotoCollageLayoutEngine.displayedItems(totalCount: urls.count, mode: mode)
        var items: [CollageItem] = displayed.compactMap { item in
            guard urls.indices.contains(item.sourceIndex) else { return nil }
            return .photo(
                PhotoItem(
                    url: urls[item.sourceIndex],
                    overflowCount: item.overflowCount,
                    removeControlState: showRemoveButton
                )
            )
        }
   
        if showAddPlaceholder {
            items.append(.add(enabled: addPlaceholderEnabled))
        }
        displayedItems = items

        collectionView.isHidden = displayedItems.isEmpty
        // Mark the adaptive layout dirty BEFORE applying the snapshot.
        // Invalidate is a flag — the layout's section closure won't actually
        // recompute until UIKit's next layout pass, which happens inside
        // dataSource.apply(). That pass reads the freshly-updated
        // displayedItems and animates cells straight into their new frames,
        // instead of running the diff against a stale (e.g. 5-frame) layout
        // and snapping to the new (4-frame) one once the animation ends.
        collectionView.collectionViewLayout.invalidateLayout()
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
        let hasOverflowBadge = displayedItems.contains { item in
            if case let .photo(photo) = item, photo.overflowCount != nil { return true }
            return false
        }
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
        collectionView.register(TripAddPhotoCell.self, forCellWithReuseIdentifier: TripAddPhotoCell.reuseIdentifier)

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource<Section, CollageItem>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .photo(let photo):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: TripPhotoCell.reuseIdentifier,
                    for: indexPath
                ) as? TripPhotoCell else {
                    return UICollectionViewCell()
                }
                let cachedImage = self.imageLoader.cachedImage(for: photo.url)
                self.configureCell(cell, item: photo, image: cachedImage)
                if cachedImage == nil {
                    self.imageLoader.loadImage(from: photo.url) { [weak self, weak collectionView, weak cell] image in
                        guard let self, let collectionView, let cell else { return }
                        guard let currentIndexPath = collectionView.indexPath(for: cell),
                              self.displayedItems.indices.contains(currentIndexPath.item),
                              case let .photo(currentPhoto) = self.displayedItems[currentIndexPath.item],
                              currentPhoto == photo else { return }
                        self.configureCell(cell, item: photo, image: image)
                    }
                }
                return cell

            case .add(let enabled):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: TripAddPhotoCell.reuseIdentifier,
                    for: indexPath
                ) as? TripAddPhotoCell else {
                    return UICollectionViewCell()
                }
                cell.configure(isEnabled: enabled) { [weak self] in
                    self?.onAddPhoto?()
                }
                return cell
            }
        }
    }

    private func applySnapshot() {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, CollageItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(displayedItems, toSection: .main)
        // First snapshot is applied without animation to avoid flashing the
        // empty state in; subsequent diffs (add / remove) animate.
        let isInitial = dataSource.snapshot().numberOfItems == 0
        dataSource.apply(snapshot, animatingDifferences: !isInitial)
    }

    private func configureCell(_ cell: TripPhotoCell, item: PhotoItem, image: UIImage?) {
        cell.configure(
            image: image,
            showRemoveButton: showsRemoveButtons,
            overflowCount: item.overflowCount,
            // Look the index up by URL on every tap so a tile that's been
            // reordered between configures still reports the correct
            // position to the host. Without this the closure would capture
            // a stale sourceIndex when the diffable data source animates a
            // move (since the cell isn't reconfigured for an unchanged
            // identity).
            onRemove: { [weak self, url = item.url] in
                guard let self else { return }
                if let index = self.lastURLs.firstIndex(of: url) {
                    self.onPhotoRemove?(index)
                }
            }
        )
    }
}

extension TripPhotoCollageView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard displayedItems.indices.contains(indexPath.item) else { return }
        switch displayedItems[indexPath.item] {
        case .photo(let photo):
            if let index = lastURLs.firstIndex(of: photo.url) {
                onPhotoTap?(index)
            }
        case .add:
            break
        }
    }
}
