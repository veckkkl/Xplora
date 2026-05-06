//
//  LanguageSelectionViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class LanguageSelectionViewController: UIViewController {
    private enum Constants {
        static let rowHeight: CGFloat = 56
    }

    private var selectedLanguage: AppLanguage = .current

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = Constants.rowHeight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 16)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedLanguage = .current
        tableView.reloadData()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Profile.LanguageSelection.title
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func handleSelection(at indexPath: IndexPath) {
        guard AppLanguage.allCases.indices.contains(indexPath.row) else { return }

        let language = AppLanguage.allCases[indexPath.row]
        selectedLanguage = language
        AppLanguage.save(language)
        tableView.reloadData()

        let alert = UIAlertController(
            title: nil,
            message: L10n.Profile.LanguageSelection.restartMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

extension LanguageSelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AppLanguage.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as UITableViewCell? else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        guard AppLanguage.allCases.indices.contains(indexPath.row) else {
            return cell
        }

        let language = AppLanguage.allCases[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = language.displayName
        content.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        content.textProperties.color = .label
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        cell.contentConfiguration = content

        cell.accessoryType = language == selectedLanguage ? .checkmark : .none
        cell.tintColor = .systemBlue
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.selectionStyle = .default

        return cell
    }
}

extension LanguageSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleSelection(at: indexPath)
    }
}
