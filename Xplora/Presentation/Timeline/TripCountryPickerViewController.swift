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
    private let emptyLabel = UILabel()

    // Grouped data for the default (non-search) mode
    private var sections: [(letter: String, countries: [Country])] = []
    // Flat data for search-results mode
    private var filteredCountries: [Country] = []

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
        viewModel.onCountriesLoaded = { [weak self] countries in
            self?.apply(countries)
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
        tableView.sectionIndexColor = .systemBlue

        emptyLabel.text = L10n.Timeline.CountryPicker.Empty.noResults
        emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true

        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    // MARK: - State

    private func apply(_ countries: [Country]) {
        if isFiltering {
            filteredCountries = countries
        } else {
            let grouped = Dictionary(grouping: countries) { String($0.name.prefix(1)).uppercased() }
            sections = grouped.keys.sorted().map { (letter: $0, countries: grouped[$0]!.sorted { $0.name < $1.name }) }
        }
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        let count = isFiltering
            ? filteredCountries.count
            : sections.reduce(0) { $0 + $1.countries.count }
        emptyLabel.isHidden = count > 0
        tableView.isHidden = count == 0
    }

    @objc private func didTapCancel() {
        viewModel.didTapCancel()
    }
}

// MARK: - UISearchResultsUpdating

extension TripCountryPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text ?? "")
        tableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - UITableViewDataSource

extension TripCountryPickerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        isFiltering ? 1 : sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isFiltering ? filteredCountries.count : sections[section].countries.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        isFiltering ? nil : sections[section].letter
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        isFiltering ? nil : sections.map(\.letter)
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        index
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        let country = isFiltering
            ? filteredCountries[indexPath.row]
            : sections[indexPath.section].countries[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = "\(flagEmoji(for: country.code))  \(country.name)"
        config.textProperties.font = UIFont.systemFont(ofSize: 17)
        cell.contentConfiguration = config
        cell.accessoryType = .none
        return cell
    }

    private func flagEmoji(for countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }
}

// MARK: - UITableViewDelegate

extension TripCountryPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = isFiltering
            ? filteredCountries[indexPath.row]
            : sections[indexPath.section].countries[indexPath.row]
        viewModel.didSelect(country: country)
    }
}
