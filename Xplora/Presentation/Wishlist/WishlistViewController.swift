// WishlistViewController.swift
// Xplora

import SnapKit
import UIKit

@MainActor
final class WishlistViewController: UIViewController {
    private enum Item: Hashable {
        case header
        case empty
        case country(WishlistCountry)
    }

    private let viewModel: WishlistViewModelInput & WishlistViewModelOutput
    private let getCatalogPlacesUseCase: GetCatalogPlacesUseCase
    private let getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Item>!

    init(
        viewModel: WishlistViewModelInput & WishlistViewModelOutput,
        getCatalogPlacesUseCase: GetCatalogPlacesUseCase,
        getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase
    ) {
        self.viewModel = viewModel
        self.getCatalogPlacesUseCase = getCatalogPlacesUseCase
        self.getCitiesForPlaceUseCase = getCitiesForPlaceUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupCollectionView()
        setupDataSource()
        bind()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTransparentNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreDefaultNavigationBarBackground()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTopInsetForScrollingScreenTitle()
    }

    // MARK: - Nav bar

    private func setupNavBar() {
        title = nil
        navigationItem.largeTitleDisplayMode = .never

        // Title-less, large-title-less bar. The big screen title is part of the
        // scrollable content (header cell); only the native system "+" lives
        // here, fixed top-right. The bar is made fully transparent in
        // `viewWillAppear` so its iOS 26 glass backdrop doesn't gray the title.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.didTapAdd()
            }
        )

        view.backgroundColor = .systemBackground
    }

    // MARK: - Collection view

    private func setupCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.backgroundColor = .systemBackground
        var separatorConfig = UIListSeparatorConfiguration(listAppearance: .plain)
        separatorConfig.topSeparatorVisibility = .hidden
        // leading 58 = checkbox(20) + checkboxWidth(26) + gap(12) — aligns with flag leading edge
        separatorConfig.bottomSeparatorInsets = NSDirectionalEdgeInsets(
            top: 0, leading: 58, bottom: 0, trailing: 0
        )
        config.separatorConfiguration = separatorConfig
        // Header and empty rows never show separators.
        config.itemSeparatorHandler = { [weak self] indexPath, proposed in
            guard let self else { return proposed }
            var resolved = proposed
            if case .country = self.dataSource.itemIdentifier(for: indexPath) {
                return resolved
            }
            resolved.topSeparatorVisibility = .hidden
            resolved.bottomSeparatorVisibility = .hidden
            return resolved
        }
        config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self,
                  case .country(let country) = dataSource.itemIdentifier(for: indexPath) else { return nil }
            let delete = UIContextualAction(style: .destructive, title: L10n.Common.delete) { [weak self] _, _, done in
                guard let self else { done(false); return }
                // Remove from snapshot immediately so ViewModel's async reload doesn't fight UIKit's swipe animation
                var snap = dataSource.snapshot()
                snap.deleteItems([.country(country)])
                dataSource.apply(snap, animatingDifferences: true)
                done(true)
                viewModel.didDelete(id: country.id)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        }

        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.delegate = self

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Data source

    private func setupDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<WishlistHeaderCell, Item> { cell, _, _ in
            cell.configure(title: L10n.Wishlist.title)
        }

        let emptyRegistration = UICollectionView.CellRegistration<WishlistEmptyCell, Item> { cell, _, _ in
            cell.configure(text: "\(L10n.Wishlist.Empty.title)\n\(L10n.Wishlist.Empty.subtitle)")
        }

        let countryRegistration = UICollectionView.CellRegistration<WishlistCountryCell, Item> {
            [weak self] cell, _, item in
            guard case .country(let country) = item else { return }
            cell.configure(with: country)
            cell.onToggle = { self?.viewModel.didToggle(id: country.id) }
        }

        dataSource = UICollectionViewDiffableDataSource<Int, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .header:
                return collectionView.dequeueConfiguredReusableCell(
                    using: headerRegistration, for: indexPath, item: item
                )
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(
                    using: emptyRegistration, for: indexPath, item: item
                )
            case .country:
                return collectionView.dequeueConfiguredReusableCell(
                    using: countryRegistration, for: indexPath, item: item
                )
            }
        }
    }

    // MARK: - Binding

    private func bind() {
        viewModel.onStateChange = { [weak self] state in self?.apply(state) }
        viewModel.onDuplicateError = { [weak self] in self?.showDuplicateAlert() }
        viewModel.onShowAddCountry = { [weak self] in self?.showAddCountry() }
        viewModel.onNeedsConfirmation = { [weak self] confirmation, country in
            self?.showConfirmationAlert(confirmation, country: country)
        }
    }

    private func apply(_ state: WishlistViewState) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        snapshot.appendSections([0])
        snapshot.appendItems([.header], toSection: 0)
        if state.isEmpty {
            snapshot.appendItems([.empty], toSection: 0)
        } else {
            snapshot.appendItems(state.items.map { .country($0) }, toSection: 0)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Actions

    private func showDuplicateAlert() {
        let alert = UIAlertController(
            title: L10n.Wishlist.Duplicate.title,
            message: L10n.Wishlist.Duplicate.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func showConfirmationAlert(_ confirmation: WishlistAddConfirmation, country: WishlistCountry) {
        let countryName = CountryLocalizer.name(for: country.code, fallback: country.name)

        let title: String
        let message: String
        let confirmTitle: String

        switch confirmation {
        case .countryAlreadyExistsWithoutCity:
            let cityName = country.displayCityNote ?? ""
            title = L10n.Wishlist.Confirm.CountryOnlyExists.title
            message = L10n.Wishlist.Confirm.CountryOnlyExists.message(countryName, cityName)
            confirmTitle = L10n.Wishlist.Confirm.addPlace
        case .countryAlreadyHasCities:
            title = L10n.Wishlist.Confirm.CountryHasCities.title
            message = L10n.Wishlist.Confirm.CountryHasCities.message(countryName, countryName)
            confirmTitle = L10n.Wishlist.Confirm.addCountry
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Wishlist.Confirm.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { [weak self] _ in
            self?.viewModel.didConfirmAdd(country: country)
        })
        present(alert, animated: true)
    }

    private func showAddCountry() {
        let addCountryViewModel = AddWishlistCountryViewModel(
            getCatalogPlacesUseCase: getCatalogPlacesUseCase,
            getCitiesForPlaceUseCase: getCitiesForPlaceUseCase
        )
        let vc = AddWishlistCountryViewController(viewModel: addCountryViewModel)
        // Presentation lifecycle (dismiss) is the parent's concern; the
        // child view model just reports the selection.
        addCountryViewModel.onSelect = { [weak self, weak vc] country in
            vc?.dismiss(animated: true) {
                self?.viewModel.didSelect(country: country)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension WishlistViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if case .country = dataSource.itemIdentifier(for: indexPath) { return true }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if case .country = dataSource.itemIdentifier(for: indexPath) { return true }
        return false
    }
}

// MARK: - Cells

private final class WishlistHeaderCell: UICollectionViewCell {
    private var headerView: ScreenHeaderView?

    func configure(title: String) {
        guard headerView == nil else { return }
        let header = ScreenHeaderView(title: title)
        contentView.addSubview(header)
        header.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerView = header
    }
}

private final class WishlistEmptyCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16, weight: .regular)
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.bottom.equalToSuperview().offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String) {
        label.text = text
    }
}
