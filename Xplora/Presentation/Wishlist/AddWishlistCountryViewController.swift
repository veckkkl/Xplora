// AddWishlistCountryViewController.swift
// Xplora

import SnapKit
import UIKit

@MainActor
final class AddWishlistCountryViewController: UIViewController {
    var onSelect: ((WishlistCountry) -> Void)?

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addButton = UIButton(type: .system)

    private let suggestionsProvider: CitySuggestionsProviding = StaticCitySuggestionsProvider()
    private let locationProvider: CurrentCountryProviding = CurrentCountryProvider()

    private var sections: [CountrySection] = []
    private var searchQuery = ""

    private var selectedCountry: CatalogCountry? { didSet { updateAddButton() } }
    private var selectedSuggestion: CitySuggestion?
    private var cityText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        rebuildSections()
    }

    // Unified background for the full-screen Select Destination flow.
    // Full-screen presentation owns its own surface, so systemBackground is correct here.
    private let screenBackground = UIColor.systemBackground

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = screenBackground
        title = L10n.Wishlist.Select.title
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.Wishlist.Select.currentLocation,
            style: .plain,
            target: self,
            action: #selector(didTapAddCurrentLocation)
        )

        searchBar.placeholder = L10n.Wishlist.Search.placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.backgroundColor = screenBackground
        searchBar.delegate = self

        tableView.backgroundColor = screenBackground
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CountryCell")
        tableView.register(CityEntryCell.self, forCellReuseIdentifier: CityEntryCell.reuseIdentifier)
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = screenBackground

        var btnConfig = UIButton.Configuration.filled()
        btnConfig.title = L10n.Wishlist.Add.button
        btnConfig.cornerStyle = .large
        btnConfig.baseBackgroundColor = .systemBlue
        btnConfig.baseForegroundColor = .white
        addButton.configuration = btnConfig
        addButton.isHidden = true
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(addButton)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        addButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(52)
        }
    }

    // MARK: - Sections

    private func rebuildSections() {
        if searchQuery.isEmpty {
            sections = Continent.allCases.compactMap { continent in
                let rows = CountryCatalog.all
                    .filter { $0.continent == continent }
                    .sorted { $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending }
                    .flatMap { expandedRows(for: $0) }
                return rows.isEmpty ? nil : CountrySection(continent: continent, rows: rows)
            }
        } else {
            let normalized = searchQuery
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            let rows = CountryCatalog.all
                .filter {
                    $0.localizedName
                        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                        .hasPrefix(normalized)
                }
                .sorted { $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending }
                .flatMap { expandedRows(for: $0) }
            sections = rows.isEmpty ? [] : [CountrySection(continent: nil, rows: rows)]
        }
        tableView.reloadData()
    }

    private func expandedRows(for country: CatalogCountry) -> [AddCountryRow] {
        var result: [AddCountryRow] = [.country(country)]
        if country.code == selectedCountry?.code {
            result.append(.cityEntry(countryCode: country.code))
        }
        return result
    }

    private func updateAddButton() {
        let active = selectedCountry != nil
        addButton.isHidden = !active
        let inset: CGFloat = active ? 52 + 32 : 0
        tableView.contentInset.bottom = inset
        tableView.verticalScrollIndicatorInsets.bottom = inset
    }

    // MARK: - Location

    private func handleAddCurrentLocation() {
        locationProvider.requestCurrentCountryCode { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let code):
                selectCountry(byCode: code)
            case .failure(let error):
                showLocationError(error)
            }
        }
    }

    private func selectCountry(byCode code: String) {
        guard let country = CountryCatalog.all.first(where: { $0.code == code }) else {
            showLocationError(.countryNotFound)
            return
        }
        searchQuery = ""
        searchBar.text = ""
        selectedCountry = country
        selectedSuggestion = nil
        cityText = ""
        rebuildSections()
        scrollToSelectedCountry()
    }

    private func scrollToSelectedCountry() {
        for (si, section) in sections.enumerated() {
            for (ri, row) in section.rows.enumerated() {
                if case .country(let c) = row, c.code == selectedCountry?.code {
                    tableView.scrollToRow(at: IndexPath(row: ri, section: si), at: .middle, animated: true)
                    return
                }
            }
        }
    }

    private func showLocationError(_ error: CurrentLocationError) {
        let title: String
        let message: String
        switch error {
        case .permissionDenied:
            title = L10n.Wishlist.CurrentLocation.Permission.title
            message = L10n.Wishlist.CurrentLocation.Permission.message
        case .locationUnavailable, .geocodingFailed, .countryNotFound:
            title = L10n.Wishlist.CurrentLocation.NotFound.title
            message = L10n.Wishlist.CurrentLocation.NotFound.message
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        if case .permissionDenied = error {
            alert.addAction(UIAlertAction(title: L10n.Wishlist.CurrentLocation.settings, style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            })
        }
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func didTapAddCurrentLocation() {
        handleAddCurrentLocation()
    }

    @objc private func didTapAdd() {
        guard let catalog = selectedCountry else { return }
        let trimmed = cityText.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = WishlistCountry(
            id: UUID(),
            code: catalog.code,
            flag: catalog.flag,
            name: catalog.name,
            cityKey: selectedSuggestion?.key,
            note: selectedSuggestion == nil && !trimmed.isEmpty ? trimmed : nil,
            isCompleted: false,
            addedAt: Date()
        )
        dismiss(animated: true) { [weak self] in self?.onSelect?(country) }
    }
}

// MARK: - UISearchBarDelegate

extension AddWishlistCountryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedCountry = nil
        selectedSuggestion = nil
        cityText = ""
        rebuildSections()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource

extension AddWishlistCountryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .country(let catalog):
            return countryCell(for: catalog, at: indexPath)
        case .cityEntry(let countryCode):
            return cityEntryCell(countryCode: countryCode, at: indexPath)
        }
    }

    private func countryCell(for catalog: CatalogCountry, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        let isSelected = catalog.code == selectedCountry?.code

        var content = cell.defaultContentConfiguration()
        content.text = "\(catalog.flag)  \(catalog.localizedName)"
        content.textProperties.font = .systemFont(ofSize: 20)
        cell.contentConfiguration = content
        cell.accessoryType = isSelected ? .checkmark : .none
        cell.tintColor = .systemBlue

        var bg = UIBackgroundConfiguration.clear()
        bg.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.08) : screenBackground
        cell.backgroundConfiguration = bg
        cell.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.08) : screenBackground
        cell.contentView.backgroundColor = .clear

        // Hide separator on the selected row AND on the row immediately above it,
        // so no gray line appears above the blue expanded block.
        let precedesSelected = nextRowIsSelected(after: indexPath)
        cell.separatorInset = (isSelected || precedesSelected)
            ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            : tableView.separatorInset

        return cell
    }

    private func nextRowIsSelected(after indexPath: IndexPath) -> Bool {
        let nextRow = indexPath.row + 1
        guard nextRow < sections[indexPath.section].rows.count else { return false }
        if case .country(let next) = sections[indexPath.section].rows[nextRow] {
            return next.code == selectedCountry?.code
        }
        return false
    }

    private func cityEntryCell(countryCode: String, at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CityEntryCell.reuseIdentifier, for: indexPath
        ) as? CityEntryCell else { return UITableViewCell() }

        let selectedTint = UIColor.systemBlue.withAlphaComponent(0.08)
        var tintBg = UIBackgroundConfiguration.clear()
        tintBg.backgroundColor = selectedTint
        cell.backgroundConfiguration = tintBg
        cell.backgroundColor = selectedTint
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)

        let suggestions = suggestionsProvider.suggestions(for: countryCode)
        cell.configure(cityText: cityText, selectedSuggestion: selectedSuggestion, suggestions: suggestions)

        cell.onCityTextChanged = { [weak self] text in
            guard let self else { return }
            let hadSuggestion = selectedSuggestion != nil
            cityText = text
            if hadSuggestion && text != selectedSuggestion?.displayName {
                selectedSuggestion = nil
                (tableView.cellForRow(at: indexPath) as? CityEntryCell)?.updateChipSelection(nil)
            }
        }

        cell.onSuggestionSelected = { [weak self] suggestion in
            guard let self else { return }
            selectedSuggestion = suggestion
            cityText = suggestion.displayName
            (tableView.cellForRow(at: indexPath) as? CityEntryCell)?
                .configure(cityText: cityText, selectedSuggestion: selectedSuggestion, suggestions: suggestions)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension AddWishlistCountryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard case .country(let catalog) = sections[indexPath.section].rows[indexPath.row] else { return }
        let isSame = catalog.code == selectedCountry?.code
        selectedCountry = isSame ? nil : catalog
        selectedSuggestion = nil
        cityText = ""
        rebuildSections()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .cityEntry: return 220
        case .country: return 52
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let continent = sections[section].continent else { return nil }
        return ContinentHeaderView(title: continent.localizedName)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].continent == nil ? CGFloat.leastNonzeroMagnitude : 44
    }
}
