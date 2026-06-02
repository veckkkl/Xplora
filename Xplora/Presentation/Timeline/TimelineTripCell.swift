//
//  TimelineTripCell.swift
//  Xplora
//

import SnapKit
import UIKit

final class TimelineTripCell: UITableViewCell {
    static let reuseIdentifier = "TimelineTripCell"

    private let lineTopView = UIView()
    private let lineBottomView = UIView()
    private let dotView = UIView()
    private let flagLabel = UILabel()
    private let countryLabel = UILabel()
    private let dateLabel = UILabel()
    private let notesLabel = UILabel()
    private let nameRow = UIStackView()
    private var onNotesTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        notesLabel.attributedText = nil
        notesLabel.text = nil
        notesLabel.isHidden = true
        notesLabel.isUserInteractionEnabled = false
        onNotesTap = nil
        lineTopView.isHidden = false
        lineBottomView.isHidden = false
    }

    func configure(
        with item: TripTimelineItem,
        isFirstInSection: Bool,
        isLastInSection: Bool,
        onNotesTap: (() -> Void)? = nil
    ) {
        flagLabel.text = item.flag
        countryLabel.text = item.countryName
        dateLabel.text = item.dateRangeText

        if let notesText = item.notesText {
            notesLabel.attributedText = makeUnderlinedText(notesText)
            notesLabel.isHidden = false
            notesLabel.isUserInteractionEnabled = true
            self.onNotesTap = onNotesTap
        } else {
            notesLabel.attributedText = nil
            notesLabel.text = nil
            notesLabel.isHidden = true
            notesLabel.isUserInteractionEnabled = false
            self.onNotesTap = nil
        }

        lineTopView.isHidden = isFirstInSection
        lineBottomView.isHidden = isLastInSection
    }

    private func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        let lineColor = UIColor.systemBlue.withAlphaComponent(0.45)
        lineTopView.backgroundColor = lineColor
        lineBottomView.backgroundColor = lineColor

        dotView.backgroundColor = .systemBlue
        dotView.layer.cornerRadius = 5
        dotView.layer.cornerCurve = .continuous

        flagLabel.font = UIFont.systemFont(ofSize: 22)
        flagLabel.setContentHuggingPriority(.required, for: .horizontal)
        flagLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        countryLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        countryLabel.textColor = .label
        countryLabel.numberOfLines = 1

        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = .secondaryLabel

        notesLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        notesLabel.textColor = .secondaryLabel
        notesLabel.textAlignment = .right
        notesLabel.isHidden = true
        notesLabel.setContentHuggingPriority(.required, for: .horizontal)
        notesLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        // Enlarge the tap target slightly by isolating the label gesture.
        notesLabel.isUserInteractionEnabled = false
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleNotesTap))
        notesLabel.addGestureRecognizer(tapRecognizer)

        nameRow.axis = .horizontal
        nameRow.spacing = 8
        nameRow.alignment = .center
        nameRow.addArrangedSubview(countryLabel)
        nameRow.addArrangedSubview(flagLabel)

        contentView.addSubview(lineTopView)
        contentView.addSubview(lineBottomView)
        contentView.addSubview(dotView)
        contentView.addSubview(nameRow)
        contentView.addSubview(dateLabel)
        contentView.addSubview(notesLabel)

        let dotX: CGFloat = 28
        let dotSize: CGFloat = 10
        let contentLeading: CGFloat = dotX + dotSize / 2 + 14

        dotView.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.leading).offset(dotX)
            make.centerY.equalTo(nameRow)
            make.size.equalTo(CGSize(width: dotSize, height: dotSize))
        }

        lineTopView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(dotView.snp.centerY)
            make.centerX.equalTo(dotView)
            make.width.equalTo(2)
        }

        lineBottomView.snp.makeConstraints { make in
            make.top.equalTo(dotView.snp.centerY)
            make.bottom.equalToSuperview()
            make.centerX.equalTo(dotView)
            make.width.equalTo(2)
        }

        nameRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(contentView.snp.leading).offset(contentLeading)
            make.trailing.lessThanOrEqualTo(notesLabel.snp.leading).offset(-8)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(nameRow.snp.bottom).offset(4)
            make.leading.equalTo(nameRow)
            make.trailing.lessThanOrEqualTo(notesLabel.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-14)
        }

        // Sit vertically between the country name and the date — visually
        // anchored to the midpoint between the two text baselines.
        notesLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(contentView)
        }
    }

    private func makeUnderlinedText(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 13, weight: .regular)
            ]
        )
    }

    @objc private func handleNotesTap() {
        onNotesTap?()
    }
}
