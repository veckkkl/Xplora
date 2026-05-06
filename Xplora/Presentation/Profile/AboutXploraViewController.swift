//
//  AboutXploraViewController.swift
//  Xplora
//

import SnapKit
import SafariServices
import UIKit

private struct AboutCardModel {
    let iconSystemName: String
    let title: String
    let description: String
}

final class AboutXploraViewController: UIViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 22
        static let topInset: CGFloat = 28
        static let bottomInset: CGFloat = 24

        static let heroIconSize: CGFloat = 80
        static let heroIconCornerRadius: CGFloat = 20

        static let cardsSpacing: CGFloat = 14
    }

    private enum Links {
        static let github = URL(string: "https://github.com/veckkkl/Xplora")!
        static let readme = URL(string: "https://github.com/veckkkl/Xplora/blob/main/Xplora/README.md")!
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let verticalStackView = UIStackView()

    private let heroStackView = UIStackView()
    private let heroIconContainerView = UIView()
    private let heroIconImageView = UIImageView()
    private let appTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let versionBuildLabel = UILabel()

    private let aboutCardView = AboutInfoCardView()
    private let featuresCardView = AboutInfoCardView()
    private let technologiesCardView = AboutInfoCardView()
    private let developerResourcesCardView = DeveloperResourcesCardView()

    private let footerLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupHierarchy()
        setupConstraints()
        configureContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // iOS 26 tab bar appearance can leave a bottom glass layer during pushes.
        // Keep tab bar explicitly hidden on this child settings screen.
        tabBarController?.tabBar.isHidden = true
        additionalSafeAreaInsets.bottom = 0
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            tabBarController?.tabBar.isHidden = false
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Profile.About.title
        navigationItem.largeTitleDisplayMode = .never

        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.contentInset.bottom = Constants.bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = Constants.bottomInset

        contentView.backgroundColor = .clear

        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.spacing = 0

        heroStackView.axis = .vertical
        heroStackView.alignment = .center
        heroStackView.spacing = 0

        heroIconContainerView.backgroundColor = .secondarySystemBackground
        heroIconContainerView.layer.cornerRadius = Constants.heroIconCornerRadius
        heroIconContainerView.layer.cornerCurve = .continuous
        heroIconContainerView.clipsToBounds = true

        heroIconImageView.image = UIImage(systemName: "airplane")
        heroIconImageView.tintColor = .systemBlue
        heroIconImageView.contentMode = .scaleAspectFit
        heroIconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 34, weight: .semibold)

        appTitleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        appTitleLabel.textColor = .label
        appTitleLabel.textAlignment = .center

        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        versionBuildLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        versionBuildLabel.textColor = .secondaryLabel
        versionBuildLabel.textAlignment = .center
        versionBuildLabel.numberOfLines = 1

        footerLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        footerLabel.textColor = .secondaryLabel
        footerLabel.textAlignment = .center
        footerLabel.numberOfLines = 0
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(verticalStackView)

        verticalStackView.addArrangedSubview(heroStackView)
        verticalStackView.addArrangedSubview(aboutCardView)
        verticalStackView.addArrangedSubview(featuresCardView)
        verticalStackView.addArrangedSubview(technologiesCardView)
        verticalStackView.addArrangedSubview(developerResourcesCardView)
        verticalStackView.addArrangedSubview(footerLabel)

        heroStackView.addArrangedSubview(heroIconContainerView)
        heroStackView.addArrangedSubview(appTitleLabel)
        heroStackView.addArrangedSubview(subtitleLabel)
        heroStackView.addArrangedSubview(versionBuildLabel)

        heroIconContainerView.addSubview(heroIconImageView)

        heroStackView.setCustomSpacing(16, after: heroIconContainerView)
        heroStackView.setCustomSpacing(8, after: appTitleLabel)
        heroStackView.setCustomSpacing(8, after: subtitleLabel)

        verticalStackView.setCustomSpacing(28, after: heroStackView)
        verticalStackView.setCustomSpacing(Constants.cardsSpacing, after: aboutCardView)
        verticalStackView.setCustomSpacing(Constants.cardsSpacing, after: featuresCardView)
        verticalStackView.setCustomSpacing(Constants.cardsSpacing, after: technologiesCardView)
        verticalStackView.setCustomSpacing(24, after: developerResourcesCardView)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        verticalStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.topInset)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            make.bottom.equalToSuperview().offset(-Constants.bottomInset)
        }

        heroIconContainerView.snp.makeConstraints { make in
            make.size.equalTo(Constants.heroIconSize)
        }

        heroIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func configureContent() {
        appTitleLabel.text = "Xplora"
        subtitleLabel.text = L10n.Profile.About.subtitle
        versionBuildLabel.text = L10n.Profile.About.versionBuild(appVersion, appBuild)
        footerLabel.text = L10n.Profile.About.footer

        aboutCardView.configure(
            with: .init(
                iconSystemName: "sparkles",
                title: L10n.Profile.About.Card.aboutTitle,
                description: L10n.Profile.About.Card.aboutText
            )
        )

        featuresCardView.configure(
            with: .init(
                iconSystemName: "map",
                title: L10n.Profile.About.Card.featuresTitle,
                description: L10n.Profile.About.Card.featuresText
            )
        )

        technologiesCardView.configure(
            with: .init(
                iconSystemName: "hammer.fill",
                title: L10n.Profile.About.Card.technologiesTitle,
                description: L10n.Profile.About.Card.technologiesText
            )
        )

        developerResourcesCardView.configure(
            title: L10n.Profile.About.developerResourcesTitle,
            githubTitle: L10n.Profile.About.githubRepository,
            readmeTitle: L10n.Profile.About.readmeGuide
        )
        developerResourcesCardView.onGitHubTap = { [weak self] in
            self?.openLink(Links.github)
        }
        developerResourcesCardView.onReadmeTap = { [weak self] in
            self?.openLink(Links.readme)
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private func openLink(_ url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true)
    }
}

private final class AboutInfoCardView: UIView {
    private enum Constants {
        static let cornerRadius: CGFloat = 24
        static let insets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        static let contentSpacing: CGFloat = 16
        static let iconContainerSize: CGFloat = 36
        static let iconContainerCornerRadius: CGFloat = 9
    }

    private let rootStackView = UIStackView()
    private let headerStackView = UIStackView()
    private let iconContainerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: AboutCardModel) {
        iconImageView.image = UIImage(systemName: model.iconSystemName)
        titleLabel.text = model.title
        descriptionLabel.text = model.description
    }

    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = Constants.cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true

        rootStackView.axis = .vertical
        rootStackView.alignment = .fill
        rootStackView.spacing = Constants.contentSpacing

        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = 12

        iconContainerView.backgroundColor = .systemBlue
        iconContainerView.layer.cornerRadius = Constants.iconContainerCornerRadius
        iconContainerView.layer.cornerCurve = .continuous
        iconContainerView.clipsToBounds = true

        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        descriptionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
    }

    private func setupHierarchy() {
        addSubview(rootStackView)

        rootStackView.addArrangedSubview(headerStackView)
        rootStackView.addArrangedSubview(descriptionLabel)

        headerStackView.addArrangedSubview(iconContainerView)
        headerStackView.addArrangedSubview(titleLabel)

        iconContainerView.addSubview(iconImageView)
    }

    private func setupConstraints() {
        rootStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Constants.insets)
        }

        iconContainerView.snp.makeConstraints { make in
            make.size.equalTo(Constants.iconContainerSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

private final class DeveloperResourcesCardView: UIView {
    var onGitHubTap: (() -> Void)?
    var onReadmeTap: (() -> Void)?

    private enum Constants {
        static let cornerRadius: CGFloat = 24
        static let headerInsets = UIEdgeInsets(top: 18, left: 20, bottom: 10, right: 20)
        static let rowsHorizontalInset: CGFloat = 20
        static let rowHeight: CGFloat = 50
    }

    private let titleLabel = UILabel()
    private let githubRow = DeveloperLinkRowView()
    private let readmeRow = DeveloperLinkRowView()
    private let dividerView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, githubTitle: String, readmeTitle: String) {
        titleLabel.text = title
        githubRow.configure(iconSystemName: "chevron.left.forwardslash.chevron.right", title: githubTitle)
        readmeRow.configure(iconSystemName: "doc.text", title: readmeTitle)
    }

    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = Constants.cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        dividerView.backgroundColor = .separator

        githubRow.onTap = { [weak self] in
            self?.onGitHubTap?()
        }
        readmeRow.onTap = { [weak self] in
            self?.onReadmeTap?()
        }
    }

    private func setupHierarchy() {
        addSubview(titleLabel)
        addSubview(githubRow)
        addSubview(dividerView)
        addSubview(readmeRow)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.headerInsets.top)
            make.leading.equalToSuperview().offset(Constants.headerInsets.left)
            make.trailing.equalToSuperview().offset(-Constants.headerInsets.right)
        }

        githubRow.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.headerInsets.bottom)
            make.leading.trailing.equalToSuperview().inset(Constants.rowsHorizontalInset)
            make.height.equalTo(Constants.rowHeight)
        }

        dividerView.snp.makeConstraints { make in
            make.top.equalTo(githubRow.snp.bottom)
            make.leading.equalToSuperview().offset(Constants.rowsHorizontalInset + 36)
            make.trailing.equalToSuperview().offset(-Constants.rowsHorizontalInset)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        readmeRow.snp.makeConstraints { make in
            make.top.equalTo(dividerView.snp.bottom)
            make.leading.trailing.equalTo(githubRow)
            make.height.equalTo(Constants.rowHeight)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
}

private final class DeveloperLinkRowView: UIControl {
    var onTap: (() -> Void)?

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let chevronImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupHierarchy()
        setupConstraints()
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(iconSystemName: String, title: String) {
        iconImageView.image = UIImage(systemName: iconSystemName)
        titleLabel.text = title
    }

    private func setupUI() {
        backgroundColor = .clear

        iconImageView.tintColor = .secondaryLabel
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
    }

    private func setupHierarchy() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(chevronImageView)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 22, height: 22))
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-12)
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
        }
    }

    @objc private func didTap() {
        onTap?()
    }
}
