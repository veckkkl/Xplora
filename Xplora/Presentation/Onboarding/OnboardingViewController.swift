//
//  OnboardingViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class OnboardingViewController: UIViewController {

    private enum Constants {
        static let horizontalInset: CGFloat = 24
        static let logoTopOffset: CGFloat = 40
        static let logoSize: CGFloat = 64
        static let logoToTitleSpacing: CGFloat = 12
        static let titleToSubtitleSpacing: CGFloat = 6
        static let subtitleToFormSpacing: CGFloat = 28
        static let formSpacing: CGFloat = 12
        static let fieldHeight: CGFloat = 50
        static let worldCitizenRowHeight: CGFloat = 56
        static let buttonHeight: CGFloat = 50
        static let errorSpacing: CGFloat = 6
        static let formToButtonSpacing: CGFloat = 24
        static let cardCornerRadius: CGFloat = 14
        static let cardHPad: CGFloat = 16
        static let separatorHeight: CGFloat = 0.5
    }

    private let viewModel: OnboardingViewModelInput & OnboardingViewModelOutput

    // MARK: - UI: header

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "globe.europe.africa.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = .init(pointSize: 36, weight: .semibold)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Xplora"
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Track everywhere you've been.\nTell us a bit about yourself."
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    // MARK: - UI: name field

    private let nameFieldCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = Constants.cardCornerRadius
        v.layer.cornerCurve = .continuous
        return v
    }()

    private let nameField: UITextField = {
        let f = UITextField()
        f.placeholder = "Your name"
        f.autocorrectionType = .no
        f.autocapitalizationType = .words
        f.returnKeyType = .continue
        f.clearButtonMode = .whileEditing
        f.font = .systemFont(ofSize: 17)
        return f
    }()

    private let nameErrorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.alpha = 0
        return l
    }()

    // MARK: - UI: country card

    private let countryCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = Constants.cardCornerRadius
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        return v
    }()

    private let countryRow: UIView = UIView()

    private let countryIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "globe.americas")
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = .init(pointSize: 18)
        return iv
    }()

    private let countryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = .placeholderText
        return l
    }()

    private let countryChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = .init(pointSize: 12, weight: .semibold)
        return iv
    }()

    private let cardSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        return v
    }()

    private let worldCitizenRow: UIView = UIView()

    private let worldCitizenTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = .label
        return l
    }()

    private let worldCitizenSubtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }()

    private let worldCitizenSwitch = UISwitch()

    private let countryErrorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.alpha = 0
        return l
    }()

    // MARK: - UI: button

    private let continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Get Started"
        config.cornerStyle = .large
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        let b = UIButton(configuration: config)
        b.isEnabled = false
        return b
    }()

    // MARK: - Init

    init(viewModel: OnboardingViewModelInput & OnboardingViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupHierarchy()
        setupConstraints()
        bindActions()
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        countryLabel.text = L10n.Onboarding.Country.placeholder
        worldCitizenTitleLabel.text = L10n.Onboarding.WorldCitizen.title
        worldCitizenSubtitleLabel.text = L10n.Onboarding.WorldCitizen.subtitle
    }

    private func setupHierarchy() {
        [logoImageView, titleLabel, subtitleLabel,
         nameFieldCard, nameErrorLabel,
         countryCard, countryErrorLabel,
         continueButton].forEach { view.addSubview($0) }

        nameFieldCard.addSubview(nameField)

        [countryRow, cardSeparator, worldCitizenRow].forEach { countryCard.addSubview($0) }

        [countryIconView, countryLabel, countryChevron].forEach { countryRow.addSubview($0) }

        [worldCitizenTitleLabel, worldCitizenSubtitleLabel, worldCitizenSwitch].forEach {
            worldCitizenRow.addSubview($0)
        }
    }

    private func setupConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.logoTopOffset)
            make.size.equalTo(Constants.logoSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(Constants.logoToTitleSpacing)
            make.centerX.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.titleToSubtitleSpacing)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        // Name card
        nameFieldCard.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Constants.subtitleToFormSpacing)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            make.height.equalTo(Constants.fieldHeight)
        }
        nameField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.cardHPad)
            make.top.bottom.equalToSuperview().inset(4)
        }
        nameErrorLabel.snp.makeConstraints { make in
            make.top.equalTo(nameFieldCard.snp.bottom).offset(Constants.errorSpacing)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        // Country card
        countryCard.snp.makeConstraints { make in
            make.top.equalTo(nameErrorLabel.snp.bottom).offset(Constants.formSpacing)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        countryRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.fieldHeight)
        }
        countryIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Constants.cardHPad)
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
        }
        countryLabel.snp.makeConstraints { make in
            make.leading.equalTo(countryIconView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(countryChevron.snp.leading).offset(-8)
        }
        countryChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Constants.cardHPad)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        cardSeparator.snp.makeConstraints { make in
            make.top.equalTo(countryRow.snp.bottom)
            make.leading.equalToSuperview().inset(Constants.cardHPad)
            make.trailing.equalToSuperview()
            make.height.equalTo(Constants.separatorHeight)
        }

        worldCitizenRow.snp.makeConstraints { make in
            make.top.equalTo(cardSeparator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Constants.worldCitizenRowHeight)
        }
        worldCitizenTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Constants.cardHPad)
            make.bottom.equalTo(worldCitizenRow.snp.centerY).offset(-1)
            make.trailing.lessThanOrEqualTo(worldCitizenSwitch.snp.leading).offset(-8)
        }
        worldCitizenSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Constants.cardHPad)
            make.top.equalTo(worldCitizenRow.snp.centerY).offset(1)
            make.trailing.lessThanOrEqualTo(worldCitizenSwitch.snp.leading).offset(-8)
        }
        worldCitizenSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Constants.cardHPad)
            make.centerY.equalToSuperview()
        }

        countryErrorLabel.snp.makeConstraints { make in
            make.top.equalTo(countryCard.snp.bottom).offset(Constants.errorSpacing)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        continueButton.snp.makeConstraints { make in
            make.top.equalTo(countryErrorLabel.snp.bottom).offset(Constants.formToButtonSpacing)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            make.height.equalTo(Constants.buttonHeight)
        }
    }

    private func bindActions() {
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        nameField.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(countryRowTapped))
        countryRow.addGestureRecognizer(tap)
        countryRow.isUserInteractionEnabled = true

        worldCitizenSwitch.addTarget(self, action: #selector(worldCitizenToggled), for: .valueChanged)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        viewModel.onContinueEnabled = { [weak self] enabled in
            self?.continueButton.isEnabled = enabled
        }
        viewModel.onNameError = { [weak self] msg in
            self?.showError(msg, in: self?.nameErrorLabel)
        }
        viewModel.onCountrySelectionChanged = { [weak self] selection in
            self?.applyCountrySelection(selection)
        }
        viewModel.onCountryError = { [weak self] msg in
            self?.showError(msg, in: self?.countryErrorLabel)
        }
    }

    // MARK: - Private

    private func showError(_ message: String?, in label: UILabel?) {
        guard let label else { return }
        if let message, !message.isEmpty {
            label.text = message
            UIView.animate(withDuration: 0.2) { label.alpha = 1 }
        } else {
            UIView.animate(withDuration: 0.2) { label.alpha = 0 }
        }
    }

    private func applyCountrySelection(_ selection: CountrySelection) {
        switch selection {
        case .none:
            countryLabel.text = L10n.Onboarding.Country.placeholder
            countryLabel.textColor = .placeholderText
            countryIconView.image = UIImage(systemName: "globe.americas")
            worldCitizenSwitch.setOn(false, animated: true)
        case .country(let code, let name):
            let flag = CountryOption(code: code, name: name).flagEmoji
            countryLabel.text = "\(flag)  \(name)"
            countryLabel.textColor = .label
            countryIconView.image = nil
            worldCitizenSwitch.setOn(false, animated: true)
        case .worldCitizen:
            countryLabel.text = L10n.Onboarding.Country.placeholder
            countryLabel.textColor = .placeholderText
            countryIconView.image = UIImage(systemName: "globe.americas")
            worldCitizenSwitch.setOn(true, animated: true)
        }
    }

    private func presentCountryPicker() {
        let picker = CountryPickerViewController()
        picker.onSelect = { [weak self] country in
            self?.viewModel.didSelectCountry(country)
        }
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }

    // MARK: - Actions

    @objc private func nameChanged() {
        viewModel.didChangeName(nameField.text ?? "")
    }

    @objc private func countryRowTapped() {
        nameField.resignFirstResponder()
        presentCountryPicker()
    }

    @objc private func worldCitizenToggled() {
        viewModel.didToggleWorldCitizen(worldCitizenSwitch.isOn)
    }

    @objc private func continueTapped() {
        viewModel.didTapContinue()
    }
}

// MARK: - UITextFieldDelegate

extension OnboardingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if continueButton.isEnabled {
            viewModel.didTapContinue()
        } else {
            nameField.resignFirstResponder()
        }
        return true
    }
}
