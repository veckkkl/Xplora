// WishlistViewController.swift
// Xplora

import SnapKit
import UIKit

@MainActor
final class WishlistViewController: UIViewController {
    private let viewModel: WishlistViewModelInput & WishlistViewModelOutput

    private let headerView = WishlistHeaderView()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, WishlistCountry>!
    private let emptyLabel = UILabel()

    init(viewModel: WishlistViewModelInput & WishlistViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupHeader()
        setupCollectionView()
        setupDataSource()
        setupEmptyLabel()
        bind()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Nav bar

    private func setupNavBar() {
        title = nil
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Header (standalone, always visible)

    private func setupHeader() {
        view.backgroundColor = .systemBackground
        headerView.configure(title: L10n.Wishlist.title)
        headerView.onAddTap = { [weak self] in self?.viewModel.didTapAdd() }

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
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
        config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self,
                  let country = dataSource.itemIdentifier(for: indexPath) else { return nil }
            let delete = UIContextualAction(style: .destructive, title: L10n.Common.delete) { [weak self] _, _, done in
                guard let self else { done(false); return }
                // Remove from snapshot immediately so ViewModel's async reload doesn't fight UIKit's swipe animation
                var snap = dataSource.snapshot()
                snap.deleteItems([country])
                dataSource.apply(snap, animatingDifferences: true)
                done(true)
                viewModel.didDelete(id: country.id)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        }

        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.contentInsetAdjustmentBehavior = .automatic

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Data source

    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WishlistCountryCell, WishlistCountry> {
            [weak self] cell, _, country in
            cell.configure(with: country)
            cell.onToggle = { self?.viewModel.didToggle(id: country.id) }
        }

        dataSource = UICollectionViewDiffableDataSource<Int, WishlistCountry>(
            collectionView: collectionView
        ) { collectionView, indexPath, country in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration, for: indexPath, item: country
            )
        }
    }

    // MARK: - Empty label

    private func setupEmptyLabel() {
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        emptyLabel.text = "\(L10n.Wishlist.Empty.title)\n\(L10n.Wishlist.Empty.subtitle)"
        emptyLabel.isHidden = true

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(collectionView)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
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
        var snapshot = NSDiffableDataSourceSnapshot<Int, WishlistCountry>()
        snapshot.appendSections([0])
        snapshot.appendItems(state.items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)

        // Never hide collectionView — header lives outside it now
        emptyLabel.isHidden = !state.isEmpty
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
        let vc = AddWishlistCountryViewController()
        vc.onSelect = { [weak self] country in self?.viewModel.didSelect(country: country) }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
