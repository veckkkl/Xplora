//
//  OnboardingViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class OnboardingViewController: UIViewController {

    private enum Layout {
        static let hInset: CGFloat = 20
        static let logoTop: CGFloat = 48
        static let logoSize: CGFloat = 56
        static let cardRadius: CGFloat = 12
        static let cardPad: CGFloat = 16
        static let rowHeight: CGFloat = 50
        static let worldCitizenRowHeight: CGFloat = 56
        static let separatorH: CGFloat = 0.5
        static let buttonHeight: CGFloat = 50
    }

    private let viewModel: OnboardingViewModelInput & OnboardingViewModelOutput
    private let getCatalogPlaces: GetCatalogPlacesUseCase
    private var currentSelection: CountrySelection = .none

    // MARK: - Header

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
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Track everywhere you've been."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Name

    private let nameCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = Layout.cardRadius
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

    // MARK: - Location section

    private let sectionHeaderLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }()

    private let locationCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = Layout.cardRadius
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        return v
    }()

    private let countryRow = UIControl()

    private let countryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
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

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        return v
    }()

    private let worldCitizenRow = UIControl()

    private let worldCitizenTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        return l
    }()

    private let worldCitizenSubtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }()

    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = .init(pointSize: 15, weight: .semibold)
        iv.alpha = 0
        return iv
    }()

    private let countryErrorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemRed
        l.numberOfLines = 0
        l.alpha = 0
        return l
    }()

    // MARK: - Button

    private let continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Get Started"
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        let b = UIButton(configuration: config)
        b.isEnabled = false
        return b
    }()

    // MARK: - Init

    init(
        viewModel: OnboardingViewModelInput & OnboardingViewModelOutput,
        getCatalogPlaces: GetCatalogPlacesUseCase
    ) {
        self.viewModel = viewModel
        self.getCatalogPlaces = getCatalogPlaces
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Nav bar is hidden on this root screen and re-enabled when the picker
        // is pushed; popping back here must re-hide it.
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        sectionHeaderLabel.text = L10n.Onboarding.Country.pickerTitle.uppercased()
        worldCitizenTitleLabel.text = L10n.Onboarding.WorldCitizen.title
        worldCitizenSubtitleLabel.text = L10n.Onboarding.WorldCitizen.subtitle
        applyPlaceholderCountry()
        addHighlightBehavior(to: countryRow)
        addHighlightBehavior(to: worldCitizenRow)
    }

    private func setupHierarchy() {
        [logoImageView, titleLabel, subtitleLabel,
         nameCard, nameErrorLabel,
         sectionHeaderLabel,
         locationCard, countryErrorLabel,
         continueButton].forEach { view.addSubview($0) }

        nameCard.addSubview(nameField)
        [countryRow, separator, worldCitizenRow].forEach { locationCard.addSubview($0) }
        [countryLabel, countryChevron].forEach { countryRow.addSubview($0) }
        [worldCitizenTitleLabel, worldCitizenSubtitleLabel, checkmarkImageView].forEach {
            worldCitizenRow.addSubview($0)
        }
    }

    private func setupConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.logoTop)
            make.size.equalTo(Layout.logoSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(Layout.hInset)
        }

        nameCard.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(Layout.hInset)
            make.height.equalTo(Layout.rowHeight)
        }
        nameField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.cardPad)
            make.top.bottom.equalToSuperview().inset(4)
        }
        nameErrorLabel.snp.makeConstraints { make in
            make.top.equalTo(nameCard.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(Layout.hInset + 4)
        }

        sectionHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(nameErrorLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(Layout.hInset + 4)
        }
        locationCard.snp.makeConstraints { make in
            make.top.equalTo(sectionHeaderLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(Layout.hInset)
        }

        countryRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.rowHeight)
        }
        countryLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.cardPad)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(countryChevron.snp.leading).offset(-8)
        }
        countryChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.cardPad)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        separator.snp.makeConstraints { make in
            make.top.equalTo(countryRow.snp.bottom)
            make.leading.equalToSuperview().inset(Layout.cardPad)
            make.trailing.equalToSuperview()
            make.height.equalTo(Layout.separatorH)
        }

        worldCitizenRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Layout.worldCitizenRowHeight)
        }
        worldCitizenTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.cardPad)
            make.bottom.equalTo(worldCitizenRow.snp.centerY).offset(-1)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }
        worldCitizenSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.cardPad)
            make.top.equalTo(worldCitizenRow.snp.centerY).offset(1)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }
        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.cardPad)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        countryErrorLabel.snp.makeConstraints { make in
            make.top.equalTo(locationCard.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(Layout.hInset + 4)
        }
        continueButton.snp.makeConstraints { make in
            make.top.equalTo(countryErrorLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(Layout.hInset)
            make.height.equalTo(Layout.buttonHeight)
        }
    }

    private func bindActions() {
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        nameField.delegate = self

        countryRow.addTarget(self, action: #selector(countryRowTapped), for: .touchUpInside)
        worldCitizenRow.addTarget(self, action: #selector(worldCitizenRowTapped), for: .touchUpInside)
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

    // MARK: - State

    private func applyCountrySelection(_ selection: CountrySelection) {
        currentSelection = selection
        switch selection {
        case .none:
            applyPlaceholderCountry()
            setCheckmark(visible: false)
        case .country(let code, let name):
            countryLabel.text = "\(Self.flagEmoji(forCode: code))  \(name)"
            countryLabel.textColor = .label
            setCheckmark(visible: false)
        case .worldCitizen:
            applyPlaceholderCountry()
            setCheckmark(visible: true)
        }
    }

    private func applyPlaceholderCountry() {
        countryLabel.text = L10n.Onboarding.Country.placeholder
        countryLabel.textColor = .placeholderText
    }

    private func setCheckmark(visible: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.checkmarkImageView.alpha = visible ? 1 : 0
        }
    }

    private func showError(_ message: String?, in label: UILabel?) {
        guard let label else { return }
        if let message, !message.isEmpty {
            label.text = message
            UIView.animate(withDuration: 0.2) { label.alpha = 1 }
        } else {
            UIView.animate(withDuration: 0.2) { label.alpha = 0 }
        }
    }

    private func addHighlightBehavior(to control: UIControl) {
        control.addTarget(self, action: #selector(rowHighlighted(_:)), for: [.touchDown, .touchDragEnter])
        control.addTarget(self, action: #selector(rowUnhighlighted(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    private func presentCountryPicker() {
        let picker = CountryPickerViewController(getCatalogPlaces: getCatalogPlaces)
        picker.onSelect = { [weak self] place in
            self?.viewModel.didSelectPlace(place)
        }
        // Push onto the wrapping nav (`AppCoordinator.showOnboarding` builds
        // it). Nav bar is hidden on the onboarding root and re-enabled here so
        // the system back button is shown on the picker.
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(picker, animated: true)
    }

    /// Inline flag derivation. Kept local so this screen doesn't reach into a
    /// shared helper just for one cell label; matches the formula used in
    /// `CatalogPlace.flag`.
    private static func flagEmoji(forCode code: String) -> String {
        String(
            code.uppercased().unicodeScalars
                .compactMap { Unicode.Scalar(127397 + $0.value) }
                .map { Character($0) }
        )
    }

    // MARK: - Actions

    @objc private func nameChanged() {
        viewModel.didChangeName(nameField.text ?? "")
    }

    @objc private func countryRowTapped() {
        nameField.resignFirstResponder()
        presentCountryPicker()
    }

    @objc private func worldCitizenRowTapped() {
        if case .worldCitizen = currentSelection {
            viewModel.didToggleWorldCitizen(false)
        } else {
            viewModel.didToggleWorldCitizen(true)
        }
    }

    @objc private func continueTapped() {
        viewModel.didTapContinue()
    }

    @objc private func rowHighlighted(_ sender: UIControl) {
        UIView.animate(withDuration: 0.05) {
            sender.backgroundColor = .systemFill
        }
    }

    @objc private func rowUnhighlighted(_ sender: UIControl) {
        UIView.animate(withDuration: 0.15) {
            sender.backgroundColor = .clear
        }
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
