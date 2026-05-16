//
//  TripDateRangeViewController.swift
//  Xplora
//

import SnapKit
import UIKit

@MainActor
final class TripDateRangeViewController: UIViewController {
    private let viewModel: TripDateRangeViewModelInput & TripDateRangeViewModelOutput

    private let contentStack = UIStackView()
    private let countryLabel = UILabel()
    private let startTitleLabel = UILabel()
    private let startPicker = UIDatePicker()
    private let endTitleLabel = UILabel()
    private let endPicker = UIDatePicker()
    private let errorLabel = UILabel()

    private var saveButton: UIBarButtonItem!

    init(viewModel: TripDateRangeViewModelInput & TripDateRangeViewModelOutput) {
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
        viewModel.viewDidLoad()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: L10n.Common.cancel,
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )

        saveButton = UIBarButtonItem(
            title: L10n.Common.save,
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )
        navigationItem.rightBarButtonItem = saveButton

        countryLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        countryLabel.textColor = .label
        countryLabel.textAlignment = .center

        startTitleLabel.text = L10n.Timeline.DateRange.start
        startTitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        startTitleLabel.textColor = .secondaryLabel

        endTitleLabel.text = L10n.Timeline.DateRange.end
        endTitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        endTitleLabel.textColor = .secondaryLabel

        startPicker.datePickerMode = .date
        startPicker.preferredDatePickerStyle = .compact
        startPicker.maximumDate = Date()
        startPicker.addTarget(self, action: #selector(didChangeStart), for: .valueChanged)

        endPicker.datePickerMode = .date
        endPicker.preferredDatePickerStyle = .compact
        endPicker.addTarget(self, action: #selector(didChangeEnd), for: .valueChanged)

        errorLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true

        let startRow = makeRow(title: startTitleLabel, control: startPicker)
        let endRow = makeRow(title: endTitleLabel, control: endPicker)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.addArrangedSubview(countryLabel)
        contentStack.addArrangedSubview(startRow)
        contentStack.addArrangedSubview(endRow)
        contentStack.addArrangedSubview(errorLabel)

        view.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }

    private func makeRow(title: UILabel, control: UIView) -> UIView {
        let row = UIStackView(arrangedSubviews: [title, control])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        return row
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state)
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
    }

    private func apply(_ state: TripDateRangeViewState) {
        title = state.title
        countryLabel.text = state.countryDisplay

        if startPicker.date != state.startDate {
            startPicker.setDate(state.startDate, animated: false)
        }
        if endPicker.date != state.endDate {
            endPicker.setDate(state.endDate, animated: false)
        }

        endPicker.minimumDate = state.startDate

        saveButton.isEnabled = state.saveEnabled

        if let message = state.errorMessage {
            errorLabel.text = message
            errorLabel.isHidden = false
        } else {
            errorLabel.text = nil
            errorLabel.isHidden = true
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: L10n.Common.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    @objc private func didChangeStart() {
        viewModel.didChangeStartDate(startPicker.date)
    }

    @objc private func didChangeEnd() {
        viewModel.didChangeEndDate(endPicker.date)
    }

    @objc private func didTapSave() {
        viewModel.didTapSave()
    }

    @objc private func didTapCancel() {
        viewModel.didTapCancel()
    }
}
