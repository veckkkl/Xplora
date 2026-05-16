//
//  TimelineViewController.swift
//  Xplora
//

import SnapKit
import UIKit

@MainActor
final class TimelineViewController: UIViewController {
    private let viewModel: TimelineViewModelInput & TimelineViewModelOutput

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var sections: [TripTimelineSection] = []

    init(viewModel: TimelineViewModelInput & TimelineViewModelOutput) {
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
        title = L10n.Tab.timeline

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )

        tableView.register(TimelineTripCell.self, forCellReuseIdentifier: TimelineTripCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.estimatedSectionHeaderHeight = 48
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionHeaderTopPadding = 0

        emptyLabel.text = L10n.Timeline.Empty.title
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

    private func apply(_ state: TimelineViewState) {
        sections = state.sections
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

extension TimelineViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TimelineTripCell.reuseIdentifier,
            for: indexPath
        ) as? TimelineTripCell else {
            return UITableViewCell()
        }
        let section = sections[indexPath.section]
        let item = section.items[indexPath.row]
        cell.configure(
            with: item,
            isFirstInSection: indexPath.row == 0,
            isLastInSection: indexPath.row == section.items.count - 1
        )
        return cell
    }
}

extension TimelineViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "\(sections[section].year)"
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label

        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-8)
        }

        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard sections.indices.contains(indexPath.section),
              sections[indexPath.section].items.indices.contains(indexPath.row) else {
            return nil
        }
        let tripId = sections[indexPath.section].items[indexPath.row].id

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }

            let editAction = UIAction(
                title: L10n.Timeline.Menu.editDates,
                image: UIImage(systemName: "calendar")
            ) { [weak self] _ in
                self?.viewModel.didTapEditDates(tripId: tripId)
            }

            let deleteAction = UIAction(
                title: L10n.Timeline.Menu.delete,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.presentDeleteConfirmation(tripId: tripId)
            }

            return UIMenu(children: [editAction, deleteAction])
        }
    }

    private func presentDeleteConfirmation(tripId: UUID) {
        let alert = UIAlertController(
            title: L10n.Timeline.Delete.Alert.title,
            message: L10n.Timeline.Delete.Alert.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Common.delete, style: .destructive) { [weak self] _ in
            self?.viewModel.didConfirmDelete(tripId: tripId)
        })
        present(alert, animated: true)
    }
}
