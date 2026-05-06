//
//  ProfileHeaderCollectionViewCell.swift
//  Xplora
//

import SnapKit
import UIKit

final class ProfileHeaderCollectionViewCell: UICollectionViewCell {
    private let headerView = ProfileHeaderView()

    var onTap: (() -> Void)? {
        didSet {
            headerView.removeTarget(self, action: #selector(handleTap), for: .touchUpInside)
            if onTap != nil {
                headerView.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
    }

    func configure(with item: ProfileCardItem) {
        headerView.configure(with: item)
    }

    private func setupUI() {
        backgroundConfiguration = .clear()
        contentView.addSubview(headerView)
    }

    private func setupConstraints() {
        headerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(96)
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
