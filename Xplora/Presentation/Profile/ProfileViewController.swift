//
//  ProfileViewController.swift
//  Xplora
//

import SnapKit
import SafariServices
import UIKit

@MainActor
final class ProfileViewController: UIViewController {
    private enum Links {
        // TODO: Replace with the public GitHub or GitHub Pages privacy policy URL after publishing.
        static let privacyPolicy: URL? = nil
    }

    private enum Item: Hashable {
        case profileCard
        case action(sectionIndex: Int, rowIndex: Int)
    }

    private let viewModel: ProfileViewModelInput & ProfileViewModelOutput

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Int, Item>?
    private var sections: [ProfileSectionModel] = []

    private lazy var profileCardRegistration = UICollectionView.CellRegistration<ProfileHeaderCollectionViewCell, Item> { [weak self] cell, _, _ in
        guard let self else { return }
        guard let profileSection = self.sections.first(where: { $0.section == .profileCard }),
              let firstItem = profileSection.items.first,
              case .profileCard(let cardModel) = firstItem else {
            return
        }
        cell.configure(with: cardModel)
        cell.onTap = { [weak self] in
            self?.didTapProfileCard()
        }
    }

    private lazy var actionCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, _, item in
        guard let self else { return }
        guard case .action(let sectionIndex, let rowIndex) = item else { return }
        guard self.sections.indices.contains(sectionIndex) else { return }
        let sectionModel = self.sections[sectionIndex]
        guard sectionModel.items.indices.contains(rowIndex) else { return }
        guard case .action(let actionItem) = sectionModel.items[rowIndex] else { return }

        var content = actionItem.value == nil
            ? UIListContentConfiguration.cell()
            : UIListContentConfiguration.valueCell()

        content.text = actionItem.title
        content.textProperties.color = actionItem.style == .destructive ? .systemRed : .label
        content.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        content.secondaryText = actionItem.value
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)

        if let iconName = actionItem.iconSystemName {
            let iconImage = UIImage(systemName: iconName)?
                .applyingSymbolConfiguration(.init(pointSize: 22, weight: .regular))
            content.image = iconImage
            content.imageProperties.tintColor = actionItem.style == .destructive ? .systemRed : .secondaryLabel
            content.imageToTextPadding = 12
            content.imageProperties.reservedLayoutSize = CGSize(width: 24, height: 24)
        } else {
            content.image = nil
        }

        cell.contentConfiguration = content
        cell.backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()

        var accessories: [UICellAccessory] = []
        if actionItem.accessory == .disclosure {
            accessories.append(
                .disclosureIndicator(
                    displayed: .always,
                    options: .init(tintColor: .tertiaryLabel)
                )
            )
        }
        cell.accessories = accessories
    }

    private lazy var headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
        elementKind: UICollectionView.elementKindSectionHeader
    ) { [weak self] view, _, indexPath in
        guard let self else { return }
        guard self.sections.indices.contains(indexPath.section) else { return }
        let section = self.sections[indexPath.section].section
        let title = section.headerTitle

        var content = UIListContentConfiguration.groupedHeader()
        content.text = title
        content.textProperties.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        content.textProperties.color = .secondaryLabel
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 8, trailing: 20)
        view.contentConfiguration = content
        view.backgroundConfiguration = .clear()
    }

    private lazy var footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
        elementKind: UICollectionView.elementKindSectionFooter
    ) { [weak self] view, _, indexPath in
        guard let self else { return }
        guard self.sections.indices.contains(indexPath.section) else { return }
        let section = self.sections[indexPath.section].section

        var content = UIListContentConfiguration.groupedFooter()
        content.text = section == .dangerZone ? L10n.Profile.Danger.footnote : nil
        content.textProperties.color = .secondaryLabel
        content.textProperties.font = UIFont.preferredFont(forTextStyle: .footnote)
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 4, trailing: 20)
        view.contentConfiguration = content
        view.backgroundConfiguration = .clear()
    }

    init(viewModel: ProfileViewModelInput & ProfileViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        prepareRegistrations()
        configureDataSource()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewDidLoad()
    }

    private func prepareRegistrations() {
        _ = profileCardRegistration
        _ = actionCellRegistration
        _ = headerRegistration
        _ = footerRegistration
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Profile.title
        navigationItem.largeTitleDisplayMode = .always
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self else { return nil }

            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.backgroundColor = .systemGroupedBackground
            configuration.showsSeparators = true
            configuration.separatorConfiguration.color = .separator
            configuration.separatorConfiguration.topSeparatorVisibility = .hidden

            if self.sections.indices.contains(sectionIndex) {
                let section = self.sections[sectionIndex].section
                configuration.headerMode = section == .profileCard ? .none : .supplementary
                configuration.footerMode = section == .dangerZone ? .supplementary : .none
            } else {
                configuration.headerMode = .none
                configuration.footerMode = .none
            }

            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
        }
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return nil }
            switch item {
            case .profileCard:
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.profileCardRegistration,
                    for: indexPath,
                    item: item
                )
            case .action:
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.actionCellRegistration,
                    for: indexPath,
                    item: item
                )
            }
        }

        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }
            guard self.sections.indices.contains(indexPath.section) else { return nil }
            let sectionType = self.sections[indexPath.section].section

            if kind == UICollectionView.elementKindSectionHeader, sectionType != .profileCard {
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: self.headerRegistration,
                    for: indexPath
                )
            }

            if kind == UICollectionView.elementKindSectionFooter, sectionType == .dangerZone {
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: self.footerRegistration,
                    for: indexPath
                )
            }

            return nil
        }
    }

    private func bindViewModel() {
        viewModel.onSectionsChange = { [weak self] sections in
            self?.applySections(sections)
        }

        viewModel.onRoute = { [weak self] route in
            self?.handle(route: route)
        }
    }

    private func applySections(_ sections: [ProfileSectionModel]) {
        self.sections = sections
        collectionView.setCollectionViewLayout(makeLayout(), animated: false)

        var snapshot = NSDiffableDataSourceSnapshot<Int, Item>()
        for (sectionIndex, sectionModel) in sections.enumerated() {
            snapshot.appendSections([sectionIndex])

            switch sectionModel.section {
            case .profileCard:
                snapshot.appendItems([.profileCard], toSection: sectionIndex)
            default:
                let items: [Item] = sectionModel.items.enumerated().compactMap { rowIndex, item in
                    guard case .action = item else { return nil }
                    return .action(sectionIndex: sectionIndex, rowIndex: rowIndex)
                }
                snapshot.appendItems(items, toSection: sectionIndex)
            }
        }

        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func didTapProfileCard() {
        guard let profileSectionIndex = sections.firstIndex(where: { $0.section == .profileCard }) else { return }
        viewModel.didSelectItem(at: IndexPath(row: 0, section: profileSectionIndex))
    }

    private func handle(route: ProfileRoute) {
        switch route {
        case .openProfileDetails:
            navigationController?.pushViewController(ProfileDetailsViewController(), animated: true)
        case .openLanguageSelection:
            navigationController?.pushViewController(LanguageSelectionViewController(), animated: true)
        case .openAboutXplora:
            navigationController?.pushViewController(AboutXploraViewController(), animated: true)
        case .openPrivacyPolicy:
            presentPrivacyPolicy()
        case .shareApp:
            presentShareSheet()
        case .confirmDeleteData:
            presentDeleteConfirmation()
        }
    }

    private func presentPrivacyPolicy() {
        guard let url = Links.privacyPolicy else {
            presentPrivacyPolicyFallbackAlert()
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true)
    }

    private func presentPrivacyPolicyFallbackAlert() {
        let alert = UIAlertController(
            title: L10n.Profile.Privacy.fallbackTitle,
            message: L10n.Profile.Privacy.fallbackMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func presentShareSheet() {
        let activityController = UIActivityViewController(
            activityItems: [L10n.Profile.Share.text],
            applicationActivities: nil
        )
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }
        present(activityController, animated: true)
    }

    private func presentDeleteConfirmation() {
        let alert = UIAlertController(
            title: L10n.Profile.Delete.confirmationTitle,
            message: L10n.Profile.Delete.confirmationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(
            UIAlertAction(title: L10n.Common.delete, style: .destructive) { [weak self] _ in
                self?.presentDeleteSuccessStub()
            }
        )
        present(alert, animated: true)
    }

    private func presentDeleteSuccessStub() {
        let alert = UIAlertController(
            title: L10n.Profile.Delete.stubTitle,
            message: L10n.Profile.Delete.stubMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

extension ProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.section) else { return }
        let section = sections[indexPath.section]
        guard section.items.indices.contains(indexPath.row) else { return }

        collectionView.deselectItem(at: indexPath, animated: true)

        guard section.section != .profileCard else { return }
        viewModel.didSelectItem(at: indexPath)
    }
}
