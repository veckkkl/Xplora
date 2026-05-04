//
//  ProfileViewController.swift
//  Xplora
//

import SnapKit
import UIKit

@MainActor
final class ProfileViewController: UIViewController {
    private let viewModel: ProfileViewModelInput & ProfileViewModelOutput

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let verticalStackView = UIStackView()
    private let screenTitleLabel = UILabel()
    private let profileHeaderView = ProfileHeaderView()

    private var sections: [ProfileSectionModel] = []
    private var sectionViews: [ProfileSectionView] = []

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
        setupLayout()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never

        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true

        contentView.backgroundColor = .clear

        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.spacing = 0

        screenTitleLabel.text = L10n.Profile.title
        screenTitleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        screenTitleLabel.textColor = .label
        screenTitleLabel.numberOfLines = 1

        profileHeaderView.addTarget(self, action: #selector(didTapProfileCard), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(verticalStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        verticalStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.equalToSuperview().offset(-28)
        }

        verticalStackView.addArrangedSubview(screenTitleLabel)
        verticalStackView.addArrangedSubview(profileHeaderView)

        profileHeaderView.snp.makeConstraints { make in
            make.height.equalTo(96)
        }

        verticalStackView.setCustomSpacing(20, after: screenTitleLabel)
    }

    private func bindViewModel() {
        viewModel.onSectionsChange = { [weak self] sections in
            self?.applySections(sections)
        }

        viewModel.onStubAction = { [weak self] message in
            self?.showStubAlert(message: message)
        }
    }

    private func applySections(_ sections: [ProfileSectionModel]) {
        self.sections = sections

        if let profileSection = sections.first(where: { $0.section == .profileCard }),
           let profileItem = profileSection.items.first,
           case .profileCard(let cardModel) = profileItem {
            profileHeaderView.configure(with: cardModel)
        }

        sectionViews.forEach { sectionView in
            verticalStackView.removeArrangedSubview(sectionView)
            sectionView.removeFromSuperview()
        }
        sectionViews.removeAll()

        var previousView: UIView = profileHeaderView

        for (sectionIndex, sectionModel) in sections.enumerated() where sectionModel.section != .profileCard {
            let rows = sectionModel.items.compactMap { item -> ProfileActionItem? in
                guard case .action(let row) = item else { return nil }
                return row
            }
            guard !rows.isEmpty else { continue }

            let sectionView = ProfileSectionView()
            sectionView.configure(
                title: sectionModel.section.headerTitle,
                rows: rows,
                footnote: footnote(for: sectionModel.section),
                onRowTap: { [weak self] rowIndex in
                    self?.viewModel.didSelectItem(at: IndexPath(row: rowIndex, section: sectionIndex))
                }
            )

            verticalStackView.setCustomSpacing(spacingBeforeSection(sectionModel.section, previousView: previousView), after: previousView)
            verticalStackView.addArrangedSubview(sectionView)

            sectionViews.append(sectionView)
            previousView = sectionView
        }
    }

    private func spacingBeforeSection(_ section: ProfileSection, previousView: UIView) -> CGFloat {
        if previousView === profileHeaderView {
            return 28
        }
        if section == .dangerZone {
            return 32
        }
        return 30
    }

    private func footnote(for section: ProfileSection) -> String? {
        switch section {
        case .dangerZone:
            return L10n.Profile.Danger.footnote
        default:
            return nil
        }
    }

    private func showStubAlert(message: String) {
        let alert = UIAlertController(
            title: L10n.Profile.Stub.title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    @objc private func didTapProfileCard() {
        guard let profileSectionIndex = sections.firstIndex(where: { $0.section == .profileCard }) else { return }
        viewModel.didSelectItem(at: IndexPath(row: 0, section: profileSectionIndex))
    }
}
