//
//  NoteLocationSectionView.swift
//  Xplora
//

import SnapKit
import UIKit

final class NoteLocationSectionView: UIView {
    enum Mode {
        case view
        case edit
    }

    struct State {
        let mode: Mode
        let hasLocation: Bool
        let title: String
        let subtitle: String
    }

    var onAddTapped: (() -> Void)?
    var onOpenTapped: (() -> Void)?
    var onRemoveTapped: (() -> Void)?

    private let cardControl = UIControl()
    private let iconView = UIImageView()
    private let textStack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let removeHitButton = NoteCircularRemoveButton(iconSize: 22)

    private var currentState = State(mode: .view, hasLocation: false, title: "", subtitle: "")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ state: State) {
        currentState = state

        switch state.mode {
        case .edit:
            isHidden = false
            removeHitButton.isHidden = !state.hasLocation

            if state.hasLocation {
                titleLabel.text = state.title
                titleLabel.textColor = .label
                subtitleLabel.text = state.subtitle
                subtitleLabel.isHidden = state.subtitle.isEmpty
            } else {
                titleLabel.text = L10n.Notes.Location.Section.add
                titleLabel.textColor = .secondaryLabel
                subtitleLabel.text = nil
                subtitleLabel.isHidden = true
            }
        case .view:
            isHidden = !state.hasLocation
            removeHitButton.isHidden = true
            titleLabel.text = state.title
            titleLabel.textColor = .label
            subtitleLabel.text = state.subtitle
            subtitleLabel.isHidden = state.subtitle.isEmpty
        }
    }

    private func setupLayout() {
        cardControl.backgroundColor = .secondarySystemBackground
        cardControl.layer.cornerRadius = 12
        cardControl.layer.cornerCurve = .continuous
        cardControl.clipsToBounds = true

        iconView.image = UIImage(systemName: "mappin.and.ellipse")
        iconView.tintColor = .secondaryLabel

        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.numberOfLines = 1
        titleLabel.isUserInteractionEnabled = false

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.isUserInteractionEnabled = false

        addSubview(cardControl)
        cardControl.addSubview(iconView)
        cardControl.addSubview(textStack)

        addSubview(removeHitButton)

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        cardControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        // 44×44 hit area aligned to the trailing edge; the visible 22pt glyph
        // sits ~10pt off the chip edge so it lines up with the photo cross.
        removeHitButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        removeHitButton.placeIcon(insetFromTop: nil, insetFromTrailing: 10)

        textStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            // Leave room for the visible glyph (22pt) plus its 10pt inset.
            make.trailing.equalToSuperview().offset(-40)
        }
    }

    private func setupActions() {
        cardControl.addTarget(self, action: #selector(didTapCard), for: .touchUpInside)
        removeHitButton.addTarget(self, action: #selector(didTapRemove), for: .touchUpInside)
    }

    @objc private func didTapCard() {
        switch currentState.mode {
        case .edit:
            onAddTapped?()
        case .view:
            guard currentState.hasLocation else { return }
            onOpenTapped?()
        }
    }

    @objc private func didTapRemove() {
        guard currentState.mode == .edit, currentState.hasLocation else { return }
        onRemoveTapped?()
    }
}
