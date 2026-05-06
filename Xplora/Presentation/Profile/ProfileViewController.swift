//
//  ProfileViewController.swift
//  Xplora
//

import SafariServices
import SnapKit
import StoreKit
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

    private enum Constants {
        static let regularRowPadding: CGFloat = 16
        static let destructiveRowPadding: CGFloat = 15
        static let titleFontSize: CGFloat = 36
        static let sectionAndRowFontSize: CGFloat = 20
        static let rowIconPointSize: CGFloat = 16
        static let rowIconReservedSize = CGSize(width: 18, height: 18)
        static let sectionHeaderTopInset: CGFloat = 14
        static let sectionInterSpacing: CGFloat = 2
    }

    private let viewModel: ProfileViewModelInput & ProfileViewModelOutput

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.contentInsetAdjustmentBehavior = .always
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
        content.textProperties.font = UIFont.systemFont(ofSize: Constants.sectionAndRowFontSize, weight: .regular)
        content.secondaryText = actionItem.value
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: actionItem.style == .destructive ? Constants.destructiveRowPadding : Constants.regularRowPadding,
            leading: 0,
            bottom: actionItem.style == .destructive ? Constants.destructiveRowPadding : Constants.regularRowPadding,
            trailing: 0
        )

        if let iconName = actionItem.iconSystemName {
            content.image = UIImage(systemName: iconName)?
                .applyingSymbolConfiguration(.init(pointSize: Constants.rowIconPointSize, weight: .semibold))
            content.imageProperties.tintColor = color(for: actionItem)
            content.imageToTextPadding = 12
            content.imageProperties.reservedLayoutSize = Constants.rowIconReservedSize
        } else {
            content.image = nil
        }

        cell.contentConfiguration = content
        cell.backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()

        var accessories: [UICellAccessory] = []
        switch actionItem.accessory {
        case .none:
            break
        case .disclosure:
            accessories.append(
                .disclosureIndicator(
                    displayed: .always,
                    options: .init(tintColor: .tertiaryLabel)
                )
            )
        case .toggle(let isOn):
            let themeSwitch = UISwitch()
            themeSwitch.onTintColor = .systemBlue
            themeSwitch.isOn = isOn
            themeSwitch.accessibilityIdentifier = "profile.darkThemeSwitch"
            themeSwitch.tag = indexTag(section: sectionIndex, row: rowIndex)
            themeSwitch.removeTarget(self, action: #selector(self.didChangeDarkThemeSwitch(_:)), for: .valueChanged)
            themeSwitch.addTarget(self, action: #selector(self.didChangeDarkThemeSwitch(_:)), for: .valueChanged)

            let configuration = UICellAccessory.CustomViewConfiguration(
                customView: themeSwitch,
                placement: .trailing(displayed: .always)
            )
            accessories.append(.customView(configuration: configuration))
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

        var content = section == .profileCard
            ? UIListContentConfiguration.cell()
            : UIListContentConfiguration.groupedHeader()
        content.text = title
        content.textProperties.font = section == .profileCard
            ? UIFont.systemFont(ofSize: Constants.titleFontSize, weight: .bold)
            : UIFont.systemFont(ofSize: Constants.sectionAndRowFontSize, weight: .semibold)
        content.textProperties.color = section == .profileCard ? .label : .secondaryLabel
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: section == .profileCard ? 10 : Constants.sectionHeaderTopInset,
            leading: 20,
            bottom: section == .profileCard ? 14 : 10,
            trailing: 20
        )
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
        content.text = section == .data ? L10n.Profile.Data.footnote : nil
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
        title = nil
        navigationItem.largeTitleDisplayMode = .never
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self else { return nil }

            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.backgroundColor = .systemGroupedBackground
            configuration.showsSeparators = true
            configuration.separatorConfiguration.color = .separator
            configuration.separatorConfiguration.topSeparatorVisibility = .hidden
            configuration.headerTopPadding = 0

            if self.sections.indices.contains(sectionIndex) {
                let section = self.sections[sectionIndex].section
                configuration.headerMode = section.headerTitle == nil ? .none : .supplementary
                configuration.footerMode = section == .data ? .supplementary : .none
            } else {
                configuration.headerMode = .none
                configuration.footerMode = .none
            }

            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
        }

        let layoutConfiguration = UICollectionViewCompositionalLayoutConfiguration()
        layoutConfiguration.interSectionSpacing = Constants.sectionInterSpacing
        layout.configuration = layoutConfiguration
        return layout
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

            if kind == UICollectionView.elementKindSectionHeader, sectionType.headerTitle != nil {
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: self.headerRegistration,
                    for: indexPath
                )
            }

            if kind == UICollectionView.elementKindSectionFooter, sectionType == .data {
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
            let viewController = ProfileDetailsViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        case .openLanguageSelection:
            let viewController = LanguageSelectionViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        case .openAboutXplora:
            let viewController = AboutXploraViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        case .openPrivacyPolicy:
            presentPrivacyPolicy()
        case .shareApp:
            presentShareSheet()
        case .rateApp:
            presentRateAppStub()
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

    private func presentRateAppStub() {
        if let windowScene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            return
        }

        let alert = UIAlertController(
            title: L10n.Profile.Rate.title,
            message: L10n.Profile.Rate.fallbackMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
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

    private func color(for item: ProfileActionItem) -> UIColor {
        switch item.style {
        case .destructive:
            return .systemRed
        case .standard:
            switch item.iconTint {
            case .blue:
                return .systemBlue
            case .green:
                return .systemGreen
            case .yellow:
                return .systemYellow
            case .purple:
                return .systemPurple
            case .gray:
                return .secondaryLabel
            case .red:
                return .systemRed
            }
        }
    }

    private func indexTag(section: Int, row: Int) -> Int {
        (section * 1_000) + row
    }

    @objc private func didChangeDarkThemeSwitch(_ sender: UISwitch) {
        let section = sender.tag / 1_000
        let row = sender.tag % 1_000

        guard sections.indices.contains(section) else { return }
        guard sections[section].items.indices.contains(row) else { return }
        guard case .action(let actionItem) = sections[section].items[row], actionItem.action == .darkTheme else { return }

        viewModel.didToggleDarkTheme(sender.isOn)
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
