//
//  TripCountryPickerViewController.swift
//  Xplora
//

import SnapKit
import UIKit

@MainActor
final class TripCountryPickerViewController: UIViewController {
    private let viewModel: TripCountryPickerViewModel

    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UILabel()

    private var sections: [CountrySection] = []
    private var loadingState: TripCountryPickerLoadingState = .loading

    private var isFiltering: Bool {
        searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }

    init(viewModel: TripCountryPickerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state)
        }
        viewModel.viewDidLoad()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = L10n.Timeline.CountryPicker.title

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: L10n.Common.cancel,
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = L10n.Timeline.CountryPicker.Search.placeholder
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CountryCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionHeaderTopPadding = 0

        loadingIndicator.hidesWhenStopped = true

        emptyLabel.text = L10n.Timeline.CountryPicker.Empty.noResults
        emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true

        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyLabel)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    // MARK: - State

    private func apply(_ state: TripCountryPickerViewState) {
        loadingState = state.loadingState
        sections = state.sections
        tableView.reloadData()
        updateChrome()
    }

    private func updateChrome() {
        switch loadingState {
        case .loading:
            loadingIndicator.startAnimating()
            tableView.isHidden = true
            emptyLabel.isHidden = true
        case .loaded:
            loadingIndicator.stopAnimating()
            let totalRows = sections.reduce(0) { $0 + $1.rows.count }
            tableView.isHidden = totalRows == 0
            emptyLabel.isHidden = totalRows > 0
        case .error:
            loadingIndicator.stopAnimating()
            tableView.isHidden = true
            emptyLabel.isHidden = false
        }
    }

    @objc private func didTapCancel() {
        viewModel.didTapCancel()
    }
}

// MARK: - UISearchResultsUpdating

extension TripCountryPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text ?? "")
    }
}

// MARK: - UITableViewDataSource

extension TripCountryPickerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].continent?.localizedName
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].continent == nil
            ? CGFloat.leastNonzeroMagnitude
            : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        guard case .country(let place) = sections[indexPath.section].rows[indexPath.row] else {
            return cell
        }

        // Status surfaces as a trailing pill (same component as Wishlist), not
        // as a subtitle. The main Timeline screen still shows no status — this
        // is only the picker.
        var config = cell.defaultContentConfiguration()
        config.text = "\(place.flag)  \(place.localizedName)"
        config.textProperties.font = UIFont.systemFont(ofSize: 17)
        cell.contentConfiguration = config
        cell.accessoryType = .none
        cell.accessoryView = CatalogPlaceBadgeView.accessoryView(for: place.status, isSelected: false)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TripCountryPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard case .country(let place) = sections[indexPath.section].rows[indexPath.row] else { return }
        viewModel.didSelect(place: place)
    }
}
