//
//  ProfileSectionView.swift
//  Xplora
//

import SnapKit
import UIKit

final class ProfileSectionView: UIView {
    private let contentStackView = UIStackView()
    private let sectionTitleLabel = UILabel()
    private let cardContainerView = UIView()
    private let rowsStackView = UIStackView()
    private let footnoteLabel = UILabel()

    private var rowViews: [ProfileRowView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String?,
        rows: [ProfileActionItem],
        footnote: String?,
        onRowTap: @escaping (Int) -> Void
    ) {
        sectionTitleLabel.text = title
        sectionTitleLabel.isHidden = (title?.isEmpty ?? true)

        footnoteLabel.text = footnote
        footnoteLabel.isHidden = (footnote?.isEmpty ?? true)

        rowViews.forEach { rowView in
            rowsStackView.removeArrangedSubview(rowView)
            rowView.removeFromSuperview()
        }
        rowViews.removeAll()

        for (rowIndex, rowModel) in rows.enumerated() {
            let rowView = ProfileRowView()
            rowView.configure(with: rowModel, showsDivider: rowIndex < rows.count - 1)
            rowView.onTap = { onRowTap(rowIndex) }
            rowsStackView.addArrangedSubview(rowView)
            rowViews.append(rowView)
        }
    }

    private func setupUI() {
        backgroundColor = .clear

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 8

        sectionTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        sectionTitleLabel.textColor = .secondaryLabel
        sectionTitleLabel.numberOfLines = 1

        cardContainerView.backgroundColor = .secondarySystemGroupedBackground
        cardContainerView.layer.cornerRadius = 24
        cardContainerView.layer.cornerCurve = .continuous
        cardContainerView.clipsToBounds = true

        rowsStackView.axis = .vertical
        rowsStackView.alignment = .fill
        rowsStackView.spacing = 0

        footnoteLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        footnoteLabel.textColor = .secondaryLabel
        footnoteLabel.numberOfLines = 0

        addSubview(contentStackView)

        contentStackView.addArrangedSubview(sectionTitleLabel)
        contentStackView.addArrangedSubview(cardContainerView)
        contentStackView.addArrangedSubview(footnoteLabel)

        cardContainerView.addSubview(rowsStackView)
    }

    private func setupConstraints() {
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        rowsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
