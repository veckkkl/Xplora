//
//  NotesListViewController.swift
//  Xplora
//

import SnapKit
import UIKit

@MainActor
final class NotesListViewController: UIViewController {
    private let viewModel: NotesListViewModelInput & NotesListViewModelOutput

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var items: [NotesListItemViewState] = []

    init(viewModel: NotesListViewModelInput & NotesListViewModelOutput) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = L10n.Notes.List.title

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )

        tableView.register(NotesListPreviewCell.self, forCellReuseIdentifier: NotesListPreviewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        emptyLabel.text = L10n.Notes.List.Empty.title
        emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        activityIndicator.hidesWhenStopped = true

        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(activityIndicator)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state)
        }

        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
    }

    private func apply(_ state: NotesListViewState) {
        items = state.items
        tableView.reloadData()

        emptyLabel.isHidden = !state.isEmpty
        tableView.isHidden = state.isEmpty

        if state.isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: L10n.Common.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    @objc private func didTapAdd() {
        viewModel.didTapAdd()
    }
}

extension NotesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NotesListPreviewCell.reuseIdentifier,
            for: indexPath
        ) as? NotesListPreviewCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

extension NotesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectItem(at: indexPath.row)
    }
}
