//
//  ProfileDetailsViewController.swift
//  Xplora
//

import PhotosUI
import SnapKit
import UIKit

final class ProfileDetailsViewController: UIViewController {
    private enum ProfileNameValidationResult: Equatable {
        case valid(String)
        case empty
        case tooLong(maxLength: Int)
        case invalidCharacters
    }

    private enum Constants {
        static let horizontalInset: CGFloat = 22
        static let topInset: CGFloat = 28
        static let bottomInset: CGFloat = 24

        static let headerSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 30
        static let statusToPillSpacing: CGFloat = 11

        static let avatarSize: CGFloat = 96
        static let avatarWrapperSize: CGFloat = 114
        static let cardCornerRadius: CGFloat = 22

        static let rowHeight: CGFloat = 56
        static let rowHorizontalInset: CGFloat = 16
        static let rowSpacing: CGFloat = 8

        static let avatarEditButtonSize: CGFloat = 36
        static let avatarEditButtonInset: CGFloat = 2

        static let infoPillHeight: CGFloat = 34
        static let infoPillHorizontalInset: CGFloat = 14
        static let infoPillSpacing: CGFloat = 7
        static let infoPillIconSize: CGFloat = 15

        static let toggleRowHorizontalInset: CGFloat = 16
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let headerStackView = UIStackView()
    private let avatarContainerView = UIView()
    private let avatarCircleView = UIView()
    private let avatarImageView = UIImageView()
    private let initialsLabel = UILabel()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let editPhotoButton = UIButton(type: .system)

    private let infoCardView = UIView()
    private let nameRowButton = UIControl()
    private let nameTitleLabel = UILabel()
    private let nameValueLabel = UILabel()
    private let nameChevronImageView = UIImageView()

    private let statusVisibilityCardView = UIView()
    private let statusVisibilityRowView = UIView()
    private let statusVisibilityTitleLabel = UILabel()
    private let statusVisibilitySwitch = UISwitch()

    private let statusInfoPillButton = UIControl()
    private let statusInfoIconImageView = UIImageView()
    private let statusInfoLabel = UILabel()
    private weak var editNameAlertController: UIAlertController?
    private weak var editNameSaveAction: UIAlertAction?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupHierarchy()
        setupConstraints()
        bindActions()
        refreshProfileData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshProfileData()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Profile.Details.title
        navigationItem.largeTitleDisplayMode = .never

        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Constants.sectionSpacing

        headerStackView.axis = .vertical
        headerStackView.alignment = .center
        headerStackView.spacing = Constants.headerSpacing

        avatarContainerView.backgroundColor = .clear
        avatarContainerView.clipsToBounds = false

        avatarCircleView.backgroundColor = .secondarySystemFill
        avatarCircleView.layer.cornerRadius = Constants.avatarSize / 2
        avatarCircleView.layer.cornerCurve = .continuous
        avatarCircleView.clipsToBounds = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isHidden = true

        initialsLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
        initialsLabel.textColor = .label
        initialsLabel.textAlignment = .center

        nameLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1

        statusLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 1

        editPhotoButton.backgroundColor = .systemBackground
        editPhotoButton.layer.cornerRadius = Constants.avatarEditButtonSize / 2
        editPhotoButton.layer.cornerCurve = .continuous
        editPhotoButton.tintColor = .systemBlue
        editPhotoButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editPhotoButton.setPreferredSymbolConfiguration(.init(pointSize: 16, weight: .semibold), forImageIn: .normal)
        editPhotoButton.layer.shadowColor = UIColor.black.cgColor
        editPhotoButton.layer.shadowOpacity = 0.1
        editPhotoButton.layer.shadowRadius = 8
        editPhotoButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        editPhotoButton.accessibilityLabel = L10n.Profile.Details.changePhoto

        infoCardView.backgroundColor = .secondarySystemGroupedBackground
        infoCardView.layer.cornerRadius = Constants.cardCornerRadius
        infoCardView.layer.cornerCurve = .continuous
        infoCardView.clipsToBounds = true

        nameRowButton.backgroundColor = .clear

        nameTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        nameTitleLabel.textColor = .label
        nameTitleLabel.text = L10n.Profile.Details.name

        nameValueLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        nameValueLabel.textColor = .secondaryLabel
        nameValueLabel.textAlignment = .right
        nameValueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        nameChevronImageView.image = UIImage(systemName: "chevron.right")
        nameChevronImageView.tintColor = .tertiaryLabel
        nameChevronImageView.contentMode = .scaleAspectFit
        nameChevronImageView.preferredSymbolConfiguration = .init(pointSize: 13, weight: .semibold)

        statusVisibilityCardView.backgroundColor = .secondarySystemGroupedBackground
        statusVisibilityCardView.layer.cornerRadius = Constants.cardCornerRadius
        statusVisibilityCardView.layer.cornerCurve = .continuous
        statusVisibilityCardView.clipsToBounds = true

        statusVisibilityTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        statusVisibilityTitleLabel.textColor = .label
        statusVisibilityTitleLabel.text = L10n.Profile.Details.showStatus

        statusVisibilitySwitch.onTintColor = .systemBlue

        statusInfoPillButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        statusInfoPillButton.layer.cornerRadius = Constants.infoPillHeight / 2
        statusInfoPillButton.layer.cornerCurve = .continuous

        statusInfoIconImageView.image = UIImage(systemName: "info.circle.fill")
        statusInfoIconImageView.tintColor = .systemBlue
        statusInfoIconImageView.contentMode = .scaleAspectFit
        statusInfoIconImageView.preferredSymbolConfiguration = .init(pointSize: Constants.infoPillIconSize, weight: .semibold)

        statusInfoLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        statusInfoLabel.textColor = .systemBlue
        statusInfoLabel.text = L10n.Profile.Details.aboutStatus
        statusInfoLabel.numberOfLines = 1
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        stackView.addArrangedSubview(headerStackView)
        stackView.addArrangedSubview(infoCardView)
        stackView.addArrangedSubview(statusVisibilityCardView)

        headerStackView.addArrangedSubview(avatarContainerView)
        headerStackView.addArrangedSubview(nameLabel)
        headerStackView.addArrangedSubview(statusLabel)
        headerStackView.addArrangedSubview(statusInfoPillButton)

        avatarContainerView.addSubview(avatarCircleView)
        avatarCircleView.addSubview(avatarImageView)
        avatarCircleView.addSubview(initialsLabel)
        avatarContainerView.addSubview(editPhotoButton)

        infoCardView.addSubview(nameRowButton)
        statusVisibilityCardView.addSubview(statusVisibilityRowView)

        nameRowButton.addSubview(nameTitleLabel)
        nameRowButton.addSubview(nameValueLabel)
        nameRowButton.addSubview(nameChevronImageView)

        statusVisibilityRowView.addSubview(statusVisibilityTitleLabel)
        statusVisibilityRowView.addSubview(statusVisibilitySwitch)

        statusInfoPillButton.addSubview(statusInfoIconImageView)
        statusInfoPillButton.addSubview(statusInfoLabel)

        headerStackView.setCustomSpacing(Constants.statusToPillSpacing, after: statusLabel)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(Constants.topInset)
            make.leading.trailing.equalTo(contentView).inset(Constants.horizontalInset)
            make.bottom.equalTo(contentView.snp.bottom).offset(-Constants.bottomInset)
        }

        avatarContainerView.snp.makeConstraints { make in
            make.size.equalTo(Constants.avatarWrapperSize)
        }

        avatarCircleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Constants.avatarSize)
        }

        initialsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        editPhotoButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.avatarEditButtonSize)
            make.trailing.equalTo(avatarCircleView.snp.trailing).offset(Constants.avatarEditButtonInset)
            make.bottom.equalTo(avatarCircleView.snp.bottom).offset(Constants.avatarEditButtonInset)
        }

        nameRowButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.rowHeight)
            make.bottom.equalToSuperview()
        }

        statusVisibilityRowView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.rowHeight)
            make.bottom.equalToSuperview()
        }

        nameTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.rowHorizontalInset)
            make.centerY.equalToSuperview()
        }

        nameChevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.rowHorizontalInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 9, height: 14))
        }

        nameValueLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(nameTitleLabel.snp.trailing).offset(Constants.rowSpacing)
            make.trailing.equalTo(nameChevronImageView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        statusVisibilityTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.toggleRowHorizontalInset)
            make.centerY.equalToSuperview()
        }

        statusVisibilitySwitch.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(statusVisibilityTitleLabel.snp.trailing).offset(Constants.rowSpacing)
            make.trailing.equalToSuperview().offset(-Constants.toggleRowHorizontalInset)
            make.centerY.equalToSuperview()
        }

        statusInfoPillButton.snp.makeConstraints { make in
            make.height.equalTo(Constants.infoPillHeight)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(headerStackView.snp.leading).offset(Constants.horizontalInset)
            make.trailing.lessThanOrEqualTo(headerStackView.snp.trailing).offset(-Constants.horizontalInset)
        }

        statusInfoIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.infoPillHorizontalInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.infoPillIconSize)
        }

        statusInfoLabel.snp.makeConstraints { make in
            make.leading.equalTo(statusInfoIconImageView.snp.trailing).offset(Constants.infoPillSpacing)
            make.trailing.equalToSuperview().offset(-Constants.infoPillHorizontalInset)
            make.centerY.equalToSuperview()
        }
    }

    private func bindActions() {
        editPhotoButton.addTarget(self, action: #selector(didTapChangePhoto), for: .touchUpInside)
        nameRowButton.addTarget(self, action: #selector(didTapNameRow), for: .touchUpInside)
        statusInfoPillButton.addTarget(self, action: #selector(didTapStatusInfoPill), for: .touchUpInside)
        statusVisibilitySwitch.addTarget(self, action: #selector(didChangeStatusVisibility(_:)), for: .valueChanged)
    }

    private func refreshProfileData() {
        let currentName = ProfileUserSettings.currentName
        let currentStatus = ProfileUserSettings.currentStatus

        initialsLabel.text = ProfileUserSettings.initials(from: currentName)
        applyAvatarImage(ProfileUserSettings.loadCurrentAvatarImage())
        nameLabel.text = currentName
        statusLabel.text = currentStatus.title

        nameValueLabel.text = currentName
        statusVisibilitySwitch.isOn = ProfileUserSettings.isStatusVisible
        applyStatusVisibility(isVisible: ProfileUserSettings.isStatusVisible)
    }

    @objc private func didTapChangePhoto() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(
            UIAlertAction(title: L10n.Profile.Details.Avatar.choosePhoto, style: .default) { [weak self] _ in
                self?.presentPhotoPicker()
            }
        )
        actionSheet.addAction(
            UIAlertAction(title: L10n.Profile.Details.Avatar.takePhoto, style: .default) { [weak self] _ in
                self?.presentCameraPicker()
            }
        )
        actionSheet.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        present(actionSheet, animated: true)
    }

    @objc private func didTapStatusInfoPill() {
        let alert = UIAlertController(
            title: L10n.Profile.Details.StatusInfo.title,
            message: L10n.Profile.Details.StatusInfo.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    @objc private func didChangeStatusVisibility(_ sender: UISwitch) {
        ProfileUserSettings.saveStatusVisibility(sender.isOn)
        applyStatusVisibility(isVisible: sender.isOn)
    }

    @objc private func didTapNameRow() {
        let alert = UIAlertController(
            title: L10n.Profile.Details.EditName.title,
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = ProfileUserSettings.currentName
            textField.placeholder = L10n.Profile.Details.EditName.placeholder
            textField.clearButtonMode = .whileEditing
            textField.autocapitalizationType = .words
            textField.addTarget(self, action: #selector(self.didChangeEditNameTextField(_:)), for: .editingChanged)
        }

        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel) { [weak self] _ in
            self?.clearEditNameAlertState()
        })
        let saveAction = UIAlertAction(title: L10n.Profile.Details.EditName.save, style: .default) { [weak self, weak alert] _ in
                guard let self, let input = alert?.textFields?.first?.text else { return }
                self.handleNameSave(input)
            }
        alert.addAction(saveAction)

        editNameAlertController = alert
        editNameSaveAction = saveAction
        updateEditNameValidationState(for: ProfileUserSettings.currentName)
        present(alert, animated: true)
    }

    @objc private func didChangeEditNameTextField(_ textField: UITextField) {
        updateEditNameValidationState(for: textField.text ?? "")
    }

    private func handleNameSave(_ input: String) {
        switch validateProfileName(input) {
        case .valid(let normalizedName):
            ProfileUserSettings.saveName(normalizedName)
            refreshProfileData()
            clearEditNameAlertState()
        case .empty, .tooLong, .invalidCharacters:
            updateEditNameValidationState(for: input)
        }
    }

    private func applyStatusVisibility(isVisible: Bool) {
        statusLabel.isHidden = !isVisible
        statusInfoPillButton.isHidden = !isVisible
    }

    private func applyAvatarImage(_ image: UIImage?) {
        avatarImageView.image = image
        avatarImageView.isHidden = image == nil
        initialsLabel.isHidden = image != nil
    }

    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }

    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentCameraUnavailableAlert()
            return
        }

        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }

    private func presentCameraUnavailableAlert() {
        let alert = UIAlertController(
            title: L10n.Profile.Details.Avatar.cameraUnavailable,
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func handlePickedAvatarImage(_ image: UIImage) {
        presentAvatarPreview(for: image)
    }

    private func presentAvatarPreview(for image: UIImage) {
        let previewViewController = AvatarPreviewViewController(
            image: image,
            title: L10n.Profile.Details.Avatar.previewTitle,
            cancelTitle: L10n.Common.cancel,
            saveTitle: L10n.Common.save
        )
        let previewNavigationController = UINavigationController(rootViewController: previewViewController)

        previewViewController.onCancel = { [weak previewNavigationController] in
            previewNavigationController?.dismiss(animated: true)
        }
        previewViewController.onSave = { [weak self, weak previewNavigationController] in
            guard let self else { return }
            guard ProfileUserSettings.saveAvatarImage(image) != nil else { return }
            self.applyAvatarImage(ProfileUserSettings.loadCurrentAvatarImage())
            previewNavigationController?.dismiss(animated: true)
        }

        previewNavigationController.modalPresentationStyle = .fullScreen
        present(previewNavigationController, animated: true)
    }

    private func updateEditNameValidationState(for rawName: String) {
        let validation = validateProfileName(rawName)
        let isValid: Bool
        let message: String?

        switch validation {
        case .valid:
            isValid = true
            message = nil
        case .empty:
            isValid = false
            message = L10n.Profile.Details.Validation.emptyName
        case .tooLong(let maxLength):
            isValid = false
            message = L10n.Profile.Details.Validation.tooLongName(maxLength)
        case .invalidCharacters:
            isValid = false
            message = L10n.Profile.Details.Validation.invalidCharacters
        }

        editNameSaveAction?.isEnabled = isValid
        setInlineValidationMessage(message)
    }

    private func setInlineValidationMessage(_ message: String?) {
        guard let alert = editNameAlertController else { return }

        guard let message else {
            alert.message = nil
            alert.setValue(nil, forKey: "attributedMessage")
            return
        }

        let attributedMessage = NSAttributedString(
            string: message,
            attributes: [
                .foregroundColor: UIColor.systemRed,
                .font: UIFont.systemFont(ofSize: 13, weight: .regular)
            ]
        )
        alert.setValue(attributedMessage, forKey: "attributedMessage")
    }

    private func clearEditNameAlertState() {
        editNameAlertController = nil
        editNameSaveAction = nil
    }

    private func validateProfileName(_ name: String) -> ProfileNameValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .empty
        }

        guard trimmed.count <= ProfileUserSettings.maxNameLength else {
            return .tooLong(maxLength: ProfileUserSettings.maxNameLength)
        }

        guard isAllowedProfileNameCharacters(trimmed) else {
            return .invalidCharacters
        }

        return .valid(trimmed)
    }

    private func isAllowedProfileNameCharacters(_ name: String) -> Bool {
        for scalar in name.unicodeScalars {
            if CharacterSet.letters.contains(scalar) { continue }
            if scalar == " " || scalar == "-" || scalar == "'" || scalar == "." { continue }
            return false
        }
        return true
    }
}

private final class AvatarPreviewViewController: UIViewController {
    private enum Constants {
        static let previewSize: CGFloat = 250
        static let horizontalInset: CGFloat = 24
        static let topInset: CGFloat = 16
        static let minimumTitleToImageSpacing: CGFloat = 24
        static let previewCenterYOffset: CGFloat = -28
    }

    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?

    private let avatarImage: UIImage
    private let titleText: String
    private let cancelTitle: String
    private let saveTitle: String

    private let titleLabel = UILabel()
    private let avatarPreviewView = UIImageView()

    init(image: UIImage, title: String, cancelTitle: String, saveTitle: String) {
        self.avatarImage = image
        self.titleText = title
        self.cancelTitle = cancelTitle
        self.saveTitle = saveTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupHierarchy()
        setupConstraints()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = nil
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: cancelTitle,
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: saveTitle,
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )

        titleLabel.text = titleText
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        avatarPreviewView.image = avatarImage
        avatarPreviewView.contentMode = .scaleAspectFill
        avatarPreviewView.clipsToBounds = true
        avatarPreviewView.layer.cornerRadius = Constants.previewSize / 2
        avatarPreviewView.layer.cornerCurve = .continuous
    }

    private func setupHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(avatarPreviewView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Constants.topInset)
            make.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        avatarPreviewView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(titleLabel.snp.bottom).offset(Constants.minimumTitleToImageSpacing)
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.centerY).offset(Constants.previewCenterYOffset)
            make.centerX.equalToSuperview()
            make.size.equalTo(Constants.previewSize)
        }
    }

    @objc private func didTapSave() {
        onSave?()
    }

    @objc private func didTapCancel() {
        onCancel?()
    }
}

extension ProfileDetailsViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.handlePickedAvatarImage(image)
            }
        }
    }
}

extension ProfileDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            guard let image else { return }
            self?.handlePickedAvatarImage(image)
        }
    }
}
