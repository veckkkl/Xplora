//
//  NoteDatePickerSheetViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class NoteDatePickerSheetViewController: UIViewController {
    private let titleText: String
    private let minimumDate: Date?
    private let maximumDate: Date?
    private let onSave: (Date) -> Void
    private let datePicker = UIDatePicker()

    init(
        titleText: String,
        initialDate: Date,
        minimumDate: Date?,
        maximumDate: Date?,
        onSave: @escaping (Date) -> Void
    ) {
        self.titleText = titleText
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        var clampedDate = initialDate
        if let minimumDate, clampedDate < minimumDate {
            clampedDate = minimumDate
        }
        if let maximumDate, clampedDate > maximumDate {
            clampedDate = maximumDate
        }
        datePicker.date = clampedDate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = titleText

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: L10n.Common.cancel,
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.Common.save,
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate

        view.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapSave() {
        onSave(datePicker.date)
    }
}
