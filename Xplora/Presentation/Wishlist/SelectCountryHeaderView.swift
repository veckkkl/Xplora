// SelectCountryHeaderView.swift
// Xplora

import SnapKit
import UIKit

final class SelectCountryHeaderView: UIView {
    var onDismiss: (() -> Void)?
    var onAddCurrentLocation: (() -> Void)?

    private let titleLabel = UILabel()
    private let dismissButton = makeCircularButton(systemName: "xmark")
    private let optionsButton = makeCircularButton(systemName: "ellipsis")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    private func setupView() {
        backgroundColor = .systemBackground
        isOpaque = true

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label

        let locationAction = UIAction(
            title: L10n.Wishlist.Select.addCurrentLocation,
            image: UIImage(systemName: "location.fill")
        ) { [weak self] _ in
            self?.onAddCurrentLocation?()
        }
        optionsButton.menu = UIMenu(children: [locationAction])
        optionsButton.showsMenuAsPrimaryAction = true

        dismissButton.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)

        addSubview(optionsButton)
        addSubview(titleLabel)
        addSubview(dismissButton)

        optionsButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 49, height: 49))
        }

        dismissButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 49, height: 49))
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(optionsButton.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualTo(dismissButton.snp.leading).offset(-4)
        }

        snp.makeConstraints { make in
            make.height.equalTo(72)
        }
    }

    @objc private func didTapDismiss() {
        onDismiss?()
    }
}

private func makeCircularButton(systemName: String) -> UIButton {
    var config: UIButton.Configuration
    if #available(iOS 26, *) {
        config = .glass()
    } else {
        config = .gray()
    }
    config.image = UIImage(systemName: systemName)
    config.baseForegroundColor = .label
    config.cornerStyle = .capsule
    return UIButton(configuration: config)
}
