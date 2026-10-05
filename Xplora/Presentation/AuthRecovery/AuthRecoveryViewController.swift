//
//  AuthRecoveryViewController.swift
//  Xplora
//

import SnapKit
import UIKit

/// Shown at launch when the stored local user exists but can't be read.
@MainActor
final class AuthRecoveryViewController: UIViewController {
    private let viewModel: AuthRecoveryViewModelInput & AuthRecoveryViewModelOutput

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    init(viewModel: AuthRecoveryViewModelInput & AuthRecoveryViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        iconView.image = UIImage(systemName: "exclamationmark.triangle")?
            .applyingSymbolConfiguration(.init(pointSize: 44, weight: .regular))
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = L10n.Auth.Recovery.title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.text = L10n.Auth.Recovery.message
        messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var retryConfig = UIButton.Configuration.filled()
        retryConfig.title = L10n.Common.retry
        retryConfig.cornerStyle = .large
        retryButton.configuration = retryConfig
        retryButton.addAction(UIAction { [weak self] _ in self?.viewModel.didTapRetry() }, for: .touchUpInside)

        var resetConfig = UIButton.Configuration.plain()
        resetConfig.title = L10n.Auth.Recovery.reset
        resetConfig.baseForegroundColor = .systemRed
        resetButton.configuration = resetConfig
        resetButton.addAction(UIAction { [weak self] _ in self?.presentResetConfirmation() }, for: .touchUpInside)

        activityIndicator.hidesWhenStopped = true

        let textStack = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = 12
        textStack.alignment = .center

        let buttonStack = UIStackView(arrangedSubviews: [retryButton, resetButton, activityIndicator])
        buttonStack.axis = .vertical
        buttonStack.spacing = 8

        view.addSubview(textStack)
        view.addSubview(buttonStack)

        textStack.snp.makeConstraints { make in
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
        }
        buttonStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }
        retryButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }

    private func bind() {
        viewModel.onRetryFailed = { [weak self] message in
            self?.presentAlert(title: nil, message: message)
        }
        viewModel.onResetInProgress = { [weak self] inProgress in
            guard let self else { return }
            retryButton.isEnabled = !inProgress
            resetButton.isEnabled = !inProgress
            if inProgress {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
        viewModel.onResetFailed = { [weak self] message in
            self?.presentAlert(title: L10n.Profile.Delete.errorTitle, message: message)
        }
    }

    private func presentResetConfirmation() {
        let alert = UIAlertController(
            title: L10n.Profile.Delete.confirmationTitle,
            message: L10n.Profile.Delete.confirmationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Profile.Delete.confirmAction, style: .destructive) { [weak self] _ in
            self?.viewModel.didConfirmReset()
        })
        present(alert, animated: true)
    }

    private func presentAlert(title: String?, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}
