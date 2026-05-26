//
//  StatisticsCardView.swift
//  Xplora
//

import UIKit

final class StatisticsCardView: UIView {

    // MARK: - Shared labels

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 26, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()

    // MARK: - Single-value layout

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 42, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    // MARK: - Total-card layout

    private let leftValueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 36, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private let leftCaptionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()

    private let rightValueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 36, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private let rightCaptionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()

    private let circularProgressView = CircularProgressView()

    private lazy var totalValuesStack: UIStackView = {
        let left = makeColumn(value: leftValueLabel, caption: leftCaptionLabel)
        let right = makeColumn(value: rightValueLabel, caption: rightCaptionLabel)
        let sv = UIStackView(arrangedSubviews: [left, circularProgressView, right])
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .center
        return sv
    }()

    // MARK: - Root stack

    private lazy var rootStack: UIStackView = {
        let header = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        header.axis = .vertical
        header.spacing = 2

        let sv = UIStackView(arrangedSubviews: [header, valueLabel, totalValuesStack])
        sv.axis = .vertical
        sv.spacing = 4
        sv.setCustomSpacing(16, after: header)
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Configure

    func configure(with data: StatisticsTotalCardViewData) {
        titleLabel.text = data.title
        subtitleLabel.text = data.subtitle
        leftValueLabel.text = data.leftValue
        leftCaptionLabel.text = data.leftCaption
        rightValueLabel.text = data.rightValue
        rightCaptionLabel.text = data.rightCaption
        circularProgressView.configure(progress: data.progress)
        valueLabel.isHidden = true
        totalValuesStack.isHidden = false
    }

    func configure(with data: StatisticsSingleValueCardViewData) {
        titleLabel.text = data.title
        subtitleLabel.text = data.subtitle
        valueLabel.text = data.value
        valueLabel.isHidden = false
        totalValuesStack.isHidden = true
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 22
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    private func makeColumn(value: UILabel, caption: UILabel) -> UIStackView {
        let sv = UIStackView(arrangedSubviews: [value, caption])
        sv.axis = .vertical
        sv.alignment = .center
        sv.spacing = 4
        return sv
    }
}
