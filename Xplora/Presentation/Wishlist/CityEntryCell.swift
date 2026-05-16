// CityEntryCell.swift
// Xplora

import SnapKit
import UIKit

final class CityEntryCell: UITableViewCell {
    static let reuseIdentifier = "CityEntryCell"

    var onCityTextChanged: ((String) -> Void)?
    var onCitySelected: ((CatalogCity) -> Void)?

    private let containerView = UIView()
    private let inputWrapper = UIView()
    private let locationIcon = UIImageView()
    private let cityTextField = UITextField()
    private let chipsStackView = UIStackView()

    // Dynamic bottom constraints — mutually exclusive
    private var inputToContainerBottom: NSLayoutConstraint!
    private var chipsTopToInputBottom: NSLayoutConstraint!
    private var chipsBottomToContainer: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onCityTextChanged = nil
        onCitySelected = nil
        clearChips()
    }

    // MARK: - Configuration

    func configure(cityText: String, selectedCity: CatalogCity?, cities: [CatalogCity]) {
        if cityTextField.text != cityText { cityTextField.text = cityText }
        rebuildChips(cities: cities, selected: selectedCity)
    }

    func updateChipSelection(_ selected: CatalogCity?) {
        for rowStack in chipsStackView.arrangedSubviews.compactMap({ $0 as? UIStackView }) {
            for chip in rowStack.arrangedSubviews.compactMap({ $0 as? CitySuggestionChipView }) {
                guard let city = chip.city else { continue }
                chip.configure(city: city, isSelected: city == selected)
            }
        }
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.18).cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.04
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        inputWrapper.backgroundColor = .systemBackground
        inputWrapper.layer.cornerRadius = 16
        inputWrapper.layer.borderWidth = 1
        inputWrapper.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.35).cgColor
        containerView.addSubview(inputWrapper)
        inputWrapper.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.height.equalTo(52)
        }

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        locationIcon.image = UIImage(systemName: "mappin.circle.fill", withConfiguration: iconConfig)
        locationIcon.tintColor = .systemBlue
        locationIcon.contentMode = .scaleAspectFit
        inputWrapper.addSubview(locationIcon)
        locationIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 22, height: 22))
        }

        cityTextField.placeholder = L10n.Wishlist.City.optional
        cityTextField.font = .systemFont(ofSize: 16)
        cityTextField.textColor = .label
        cityTextField.clearButtonMode = .whileEditing
        cityTextField.returnKeyType = .done
        cityTextField.borderStyle = .none
        cityTextField.delegate = self
        cityTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        inputWrapper.addSubview(cityTextField)
        cityTextField.snp.makeConstraints { make in
            make.leading.equalTo(locationIcon.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

        chipsStackView.axis = .vertical
        chipsStackView.spacing = 10
        chipsStackView.distribution = .fill
        containerView.addSubview(chipsStackView)
        chipsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }

        // Dynamic constraints (mutually exclusive)
        inputToContainerBottom = inputWrapper.bottomAnchor.constraint(
            equalTo: containerView.bottomAnchor, constant: -14
        )
        chipsTopToInputBottom = chipsStackView.topAnchor.constraint(
            equalTo: inputWrapper.bottomAnchor, constant: 14
        )
        chipsBottomToContainer = chipsStackView.bottomAnchor.constraint(
            equalTo: containerView.bottomAnchor, constant: -14
        )
        inputToContainerBottom.isActive = true
    }

    // MARK: - Chips

    private func rebuildChips(cities: [CatalogCity], selected: CatalogCity?) {
        clearChips()
        guard !cities.isEmpty else {
            chipsTopToInputBottom.isActive = false
            chipsBottomToContainer.isActive = false
            inputToContainerBottom.isActive = true
            return
        }
        inputToContainerBottom.isActive = false
        chipsTopToInputBottom.isActive = true
        chipsBottomToContainer.isActive = true

        for chunk in cities.chunked(into: 2) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually

            for city in chunk {
                let chip = CitySuggestionChipView()
                chip.configure(city: city, isSelected: city == selected)
                chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(chip)
            }
            if chunk.count == 1 {
                rowStack.addArrangedSubview(UIView())   // spacer for odd row
            }
            chipsStackView.addArrangedSubview(rowStack)
        }
    }

    private func clearChips() {
        chipsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - Actions

    @objc private func chipTapped(_ sender: CitySuggestionChipView) {
        guard let city = sender.city else { return }
        cityTextField.text = city.displayName
        onCitySelected?(city)
    }

    @objc private func textDidChange() {
        onCityTextChanged?(cityTextField.text ?? "")
    }
}

// MARK: - UITextFieldDelegate

extension CityEntryCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Array+Chunked

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
