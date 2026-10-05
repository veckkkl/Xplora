//
//  ErrorStateView.swift
//  Xplora
//

import SnapKit
import UIKit

/// Centered "couldn't load" message with an optional Retry button.
/// Shown instead of a list so a failed load never looks like an empty one.
final class ErrorStateView: UIView {
    var onRetry: (() -> Void)?

    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var retryConfig = UIButton.Configuration.borderedTinted()
        retryConfig.title = L10n.Common.retry
        retryConfig.cornerStyle = .large
        retryButton.configuration = retryConfig
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String, showsRetry: Bool = true) {
        messageLabel.text = message
        retryButton.isHidden = !showsRetry
    }
}
