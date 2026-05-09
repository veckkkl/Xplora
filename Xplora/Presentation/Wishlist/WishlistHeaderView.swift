// WishlistHeaderView.swift
// Xplora

import SnapKit
import UIKit

final class WishlistHeaderView: UIView {
    var onAddTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let addButton = makeGlassButton(systemName: "plus")

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
        backgroundColor = .clear

        titleLabel.font = .systemFont(ofSize: 38, weight: .bold)
        titleLabel.textColor = .label

        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        addSubview(titleLabel)
        addSubview(addButton)

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(addButton.snp.leading).offset(-8)
        }

        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(CGSize(width: 49, height: 49))
        }
    }

    @objc private func addTapped() {
        onAddTap?()
    }
}

private func makeGlassButton(systemName: String) -> UIButton {
    var config: UIButton.Configuration
    if #available(iOS 26, *) {
        config = .glass()
    } else {
        config = .gray()
    }
    config.image = UIImage(systemName: systemName)
    config.baseForegroundColor = .systemBlue
    config.cornerStyle = .capsule
    return UIButton(configuration: config)
}
