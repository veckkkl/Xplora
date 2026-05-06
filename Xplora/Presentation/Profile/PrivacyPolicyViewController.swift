//
//  PrivacyPolicyViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class PrivacyPolicyViewController: UIViewController {
    private let placeholderLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Profile.Privacy.title

        placeholderLabel.text = L10n.Profile.Privacy.placeholder
        placeholderLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 0

        view.addSubview(placeholderLabel)
    }

    private func setupConstraints() {
        placeholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }
}
