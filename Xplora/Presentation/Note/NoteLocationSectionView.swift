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

    private let pillControl = UIControl()
    private let iconView = UIImageView()
    private let textStack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let removeButton = UIButton(type: .system)

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
            removeButton.isHidden = !state.hasLocation
            if state.hasLocation {
                titleLabel.text = state.title
                titleLabel.textColor = .label
                subtitleLabel.text = state.subtitle
                subtitleLabel.isHidden = state.subtitle.isEmpty
            } else {
                titleLabel.text = "Add location"
                titleLabel.textColor = .secondaryLabel
                subtitleLabel.text = nil
                subtitleLabel.isHidden = true
            }
        case .view:
            isHidden = !state.hasLocation
            removeButton.isHidden = true
            titleLabel.text = state.title
            titleLabel.textColor = .label
            subtitleLabel.text = state.subtitle
            subtitleLabel.isHidden = state.subtitle.isEmpty
        }
    }

    private func setupLayout() {
        pillControl.backgroundColor = .secondarySystemBackground
        pillControl.layer.cornerRadius = 12
        pillControl.clipsToBounds = true

        iconView.image = UIImage(systemName: "mappin.and.ellipse")
        iconView.tintColor = .secondaryLabel

        textStack.axis = .vertical
        textStack.spacing = 2

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.numberOfLines = 1

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail

        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = UIColor.black.withAlphaComponent(0.55)

        addSubview(pillControl)
        pillControl.addSubview(iconView)
        pillControl.addSubview(textStack)
        pillControl.addSubview(removeButton)

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        pillControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        removeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 18, height: 18))
        }

        textStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.trailing.equalTo(removeButton.snp.leading).offset(-8)
        }
    }

    private func setupActions() {
        pillControl.addTarget(self, action: #selector(didTapPill), for: .touchUpInside)
        removeButton.addTarget(self, action: #selector(didTapRemove), for: .touchUpInside)
    }

    @objc private func didTapPill() {
        switch currentState.mode {
        case .edit:
            onAddTapped?()
        case .view:
            guard currentState.hasLocation else { return }
            onOpenTapped?()
        }
    }

    @objc private func didTapRemove() {
        guard currentState.mode == .edit else { return }
        guard currentState.hasLocation else { return }
        onRemoveTapped?()
    }
}
