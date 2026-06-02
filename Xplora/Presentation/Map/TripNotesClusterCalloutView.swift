//
//  TripNotesClusterCalloutView.swift
//  Xplora
//

import SnapKit
import UIKit

/// Horizontal, paged carousel of notes shown inside the MapKit callout of a
/// cluster (or a same-coordinate marker). Each card reuses
/// `TripNoteCalloutContentView` via `TripNoteCalloutCarouselCell`, so the
/// look matches the single-note callout. A page control underneath gives
/// the user a sense of how many notes are in the cluster.
final class TripNotesClusterCalloutView: UIView {
    /// Called with the noteId of the card the user tapped.
    var onSelectNote: ((String) -> Void)?

    private let previews: [TripNoteClusterPreview]
    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private var cachedPreferredHeight: CGFloat?

    private static let cardWidth: CGFloat = 240
    private static let pageControlHeight: CGFloat = 16
    private static let spacingBetweenCardAndDots: CGFloat = 4

    init(previews: [TripNoteClusterPreview]) {
        self.previews = previews

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: Self.cardWidth, height: 1) // height adjusted after layout

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TripNoteCalloutCarouselCell.self,
            forCellWithReuseIdentifier: TripNoteCalloutCarouselCell.reuseIdentifier
        )

        pageControl.numberOfPages = previews.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .label
        pageControl.pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.25)
        pageControl.isUserInteractionEnabled = false
        pageControl.hidesForSinglePage = true

        addSubview(collectionView)
        addSubview(pageControl)

        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.width.equalTo(Self.cardWidth)
        }

        pageControl.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(Self.spacingBetweenCardAndDots)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Self.pageControlHeight)
            make.bottom.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // The flow layout needs the actual collection height to give cards
        // their final size; once bounds settle we recompute and invalidate.
        let collectionHeight = collectionView.bounds.height
        if collectionHeight > 0,
           let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           flow.itemSize.height != collectionHeight {
            flow.itemSize = CGSize(width: Self.cardWidth, height: collectionHeight)
            flow.invalidateLayout()
        }
    }

    /// Height of the tallest card so the host (MapKit callout) can pin our
    /// intrinsic size. We render each preview inside a temp host with the
    /// real card width — `TripNoteCalloutContentView` only computes the
    /// collage height once `bounds.width > 0`, so measuring an orphan view
    /// via `systemLayoutSizeFitting` alone would miss the photo block and
    /// the carousel would collapse to a text-less strip.
    func preferredHeight(forWidth width: CGFloat) -> CGFloat {
        if let cached = cachedPreferredHeight {
            return cached
        }
        let host = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 4_000))
        let probe = TripNoteCalloutContentView()
        host.addSubview(probe)
        probe.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            probe.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            probe.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            probe.topAnchor.constraint(equalTo: host.topAnchor)
        ])

        var maxHeight: CGFloat = 0
        for preview in previews {
            probe.configure(with: preview.preview)
            host.setNeedsLayout()
            host.layoutIfNeeded()
            // Second pass: layoutSubviews inside TripNoteCalloutContentView
            // now sees the real bounds.width and recomputes the collage
            // height — the first systemLayoutSizeFitting reading would
            // otherwise miss the photo block entirely.
            host.setNeedsLayout()
            host.layoutIfNeeded()
            let fitting = probe.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            maxHeight = max(maxHeight, fitting.height)
        }
        let total = maxHeight + Self.spacingBetweenCardAndDots + Self.pageControlHeight
        cachedPreferredHeight = total
        return total
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.cardWidth, height: preferredHeight(forWidth: Self.cardWidth))
    }
}

extension TripNotesClusterCalloutView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        previews.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TripNoteCalloutCarouselCell.reuseIdentifier,
            for: indexPath
        ) as? TripNoteCalloutCarouselCell else {
            return UICollectionViewCell()
        }
        let preview = previews[indexPath.item]
        cell.configure(with: preview.preview) { [weak self] in
            self?.onSelectNote?(preview.noteId)
        }
        return cell
    }
}

extension TripNotesClusterCalloutView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0 else { return }
        let page = Int((scrollView.contentOffset.x + width / 2) / width)
        if pageControl.currentPage != page {
            pageControl.currentPage = page
        }
    }
}
