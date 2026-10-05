//
//  ThemeSelectionViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class ThemeSelectionViewController: UIViewController {
    private enum Constants {
        static let rowHeight: CGFloat = 56
    }

    var onSelect: ((AppTheme) -> Void)?

    private var selectedTheme: AppTheme

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = Constants.rowHeight
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ThemeCell")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    init(selectedTheme: AppTheme) {
        self.selectedTheme = selectedTheme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Profile.Item.theme
        navigationItem.largeTitleDisplayMode = .never
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func handleSelection(at indexPath: IndexPath) {
        guard AppTheme.allCases.indices.contains(indexPath.row) else { return }

        let theme = AppTheme.allCases[indexPath.row]
        guard theme != selectedTheme else { return }
        selectedTheme = theme
        tableView.reloadData()
        onSelect?(theme)
    }
}

extension ThemeSelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AppTheme.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        L10n.Profile.Theme.footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeCell", for: indexPath)

        guard AppTheme.allCases.indices.contains(indexPath.row) else {
            return cell
        }

        let theme = AppTheme.allCases[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = theme.title
        content.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        content.textProperties.color = .label
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        cell.contentConfiguration = content

        cell.accessoryType = theme == selectedTheme ? .checkmark : .none
        cell.tintColor = .systemBlue
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.selectionStyle = .default

        return cell
    }
}

extension ThemeSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handleSelection(at: indexPath)
    }
}
