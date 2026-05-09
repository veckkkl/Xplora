// CityInputCell.swift
// Xplora

import SnapKit
import UIKit

final class CityInputCell: UITableViewCell {
    static let reuseIdentifier = "CityInputCell"

    var onTextChanged: ((String) -> Void)?

    let textField = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTextChanged = nil
    }

    func configure(text: String) {
        if textField.text != text { textField.text = text }
    }

    private func setupView() {
        backgroundColor = .secondarySystemGroupedBackground
        contentView.backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .none

        textField.placeholder = L10n.Wishlist.City.optional
        textField.textColor = .label
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.borderStyle = .none
        textField.font = .systemFont(ofSize: 17)
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        contentView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(52)
            make.trailing.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }
    }

    @objc private func textDidChange() {
        onTextChanged?(textField.text ?? "")
    }
}
