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
    private lazy var headerView = ScreenHeaderView(title: L10n.Tab.timeline)

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
        applyTransparentNavigationBar()
        viewModel.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore a standard bar for pushed screens (e.g. the country picker)
        // that share this navigation controller.
        restoreDefaultNavigationBarBackground()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTopInsetForScrollingScreenTitle()
        sizeTableHeader()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = nil
        navigationItem.largeTitleDisplayMode = .never

        // Title-less, large-title-less bar. The big title scrolls with content;
        // only the native system "+" lives here. The bar is made fully
        // transparent in `viewWillAppear` so its iOS 26 glass backdrop doesn't
        // gray the title.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )

        tableView.register(TimelineTripCell.self, forCellReuseIdentifier: TimelineTripCell.reuseIdentifier)
        tableView.register(TimelineYearCell.self, forCellReuseIdentifier: TimelineYearCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        // Year is a normal scrollable row (not a section header), so headers
        // never pin while scrolling.
        tableView.estimatedSectionHeaderHeight = 0
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionHeaderTopPadding = 0
        // Title scrolls away with the content, matching the Settings screen.
        tableView.tableHeaderView = headerView

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
            make.edges.equalToSuperview()
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

    private func sizeTableHeader() {
        guard let header = tableView.tableHeaderView else { return }
        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else { return }
        let fittingSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        if abs(header.frame.height - height) > 0.5 || header.frame.width != targetWidth {
            header.frame = CGRect(x: 0, y: 0, width: targetWidth, height: height)
            tableView.tableHeaderView = header
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
        // Row 0 is the scrollable year divider, followed by the trips.
        sections[section].items.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]

        if indexPath.row == 0 {
            guard let yearCell = tableView.dequeueReusableCell(
                withIdentifier: TimelineYearCell.reuseIdentifier,
                for: indexPath
            ) as? TimelineYearCell else {
                return UITableViewCell()
            }
            yearCell.configure(year: section.year)
            return yearCell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TimelineTripCell.reuseIdentifier,
            for: indexPath
        ) as? TimelineTripCell else {
            return UITableViewCell()
        }
        let tripIndex = indexPath.row - 1
        let item = section.items[tripIndex]
        cell.configure(
            with: item,
            isFirstInSection: tripIndex == 0,
            isLastInSection: tripIndex == section.items.count - 1
        )
        return cell
    }
}

extension TimelineViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        // Row 0 is the year divider; trips start at row 1.
        guard indexPath.row >= 1,
              sections.indices.contains(indexPath.section) else {
            return nil
        }
        let tripIndex = indexPath.row - 1
        guard sections[indexPath.section].items.indices.contains(tripIndex) else {
            return nil
        }
        let tripId = sections[indexPath.section].items[tripIndex].id

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

// MARK: - Year divider cell

private final class TimelineYearCell: UITableViewCell {
    static let reuseIdentifier = "TimelineYearCell"

    private let yearLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        yearLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        yearLabel.textColor = .label
        contentView.addSubview(yearLabel)
        yearLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(year: Int) {
        yearLabel.text = "\(year)"
    }
}
