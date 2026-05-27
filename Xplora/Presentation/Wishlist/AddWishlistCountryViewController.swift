// AddWishlistCountryViewController.swift
// Xplora

import SnapKit
import UIKit

@MainActor
final class AddWishlistCountryViewController: UIViewController {
    private let viewModel: AddWishlistCountryViewModelInput & AddWishlistCountryViewModelOutput

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addButton = UIButton(type: .system)

    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorContainer = UIView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private var currentLocationBarButton: UIBarButtonItem?

    // Locally cached snapshot of the last applied state, used to render the
    // table data source and to compute minimal in-place cell updates.
    private var currentState: AddWishlistCountryViewState?
    private var sections: [CountrySection] { currentState?.sections ?? [] }

    private let screenBackground = UIColor.systemBackground

    init(viewModel: AddWishlistCountryViewModelInput & AddWishlistCountryViewModelOutput) {
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
        let currentLocationItem = UIBarButtonItem(
            title: L10n.Wishlist.Select.currentLocation,
            style: .plain,
            target: self,
            action: #selector(didTapAddCurrentLocation)
        )
        currentLocationItem.isEnabled = false
        navigationItem.rightBarButtonItem = currentLocationItem
        currentLocationBarButton = currentLocationItem

        searchBar.placeholder = L10n.Wishlist.Search.placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = screenBackground
        searchBar.delegate = self

        tableView.backgroundColor = .clear
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
        tableView.sectionHeaderTopPadding = 0
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = .clear

        var btnConfig = UIButton.Configuration.filled()
        btnConfig.title = L10n.Wishlist.Add.button
        btnConfig.cornerStyle = .large
        btnConfig.baseBackgroundColor = .systemBlue
        btnConfig.baseForegroundColor = .white
        addButton.configuration = btnConfig
        addButton.isHidden = true
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)

        loadingIndicator.hidesWhenStopped = true

        errorContainer.isHidden = true
        errorLabel.font = .systemFont(ofSize: 15, weight: .regular)
        errorLabel.textColor = .secondaryLabel
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.text = L10n.Wishlist.Select.Error.load
        var retryConfig = UIButton.Configuration.borderedTinted()
        retryConfig.title = L10n.Wishlist.Select.retry
        retryConfig.cornerStyle = .large
        retryButton.configuration = retryConfig
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)

        let errorStack = UIStackView(arrangedSubviews: [errorLabel, retryButton])
        errorStack.axis = .vertical
        errorStack.spacing = 16
        errorStack.alignment = .center
        errorContainer.addSubview(errorStack)
        errorStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(addButton)
        view.addSubview(loadingIndicator)
        view.addSubview(errorContainer)

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
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
        errorContainer.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Binding

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state)
        }
        viewModel.onLocationError = { [weak self] error in
            self?.presentLocationError(error)
        }
        viewModel.onScrollToPlace = { [weak self] code in
            self?.scrollToPlace(code: code)
        }
        // `onSelect` is owned by the parent that constructs the view model.
    }

    // MARK: - State rendering

    private func apply(_ state: AddWishlistCountryViewState) {
        let previous = currentState
        currentState = state

        // 1. Loading / loaded / error visibility
        if previous?.loadingState != state.loadingState {
            applyLoadingState(state.loadingState)
        }

        // 2. Buttons
        currentLocationBarButton?.isEnabled = state.currentLocationButtonEnabled
        let addActive = state.addButtonEnabled
        addButton.isHidden = !addActive
        let inset: CGFloat = addActive ? 52 + 32 : 0
        tableView.contentInset.bottom = inset
        tableView.verticalScrollIndicatorInsets.bottom = inset

        // 3. Table — reload only when section/structure data changed; this
        // keeps the in-place city text field focus untouched while the user
        // is typing (state changes that don't change sections shouldn't
        // recreate cells).
        let sectionsChanged = previous?.sections != state.sections
        if sectionsChanged {
            // If the only structural change is the city-entry row toggling
            // (i.e. the user selected/deselected/switched country), animate
            // the insert/delete so the input field slides in/out smoothly —
            // matching the chip-expansion animation that countries with
            // top-5 cities already get. Falls back to reloadData when the
            // section shape changed for other reasons (search, retry, etc.).
            if let previous,
               let plan = cityRowTogglePlan(
                   from: previous.sections,
                   oldSelected: previous.selectedPlace,
                   to: state.sections,
                   newSelected: state.selectedPlace
               ) {
                animateCityRowToggle(plan: plan, oldSections: previous.sections)
            } else {
                tableView.reloadData()
            }
        }

        // 4. City entry cell — minimal in-place update for chip selection
        // changes that aren't accompanied by a section reload.
        if !sectionsChanged {
            let citySelectionChanged = previous?.selectedCity != state.selectedCity
            let citiesChanged = previous?.citiesForSelectedPlace != state.citiesForSelectedPlace
            if citiesChanged, let cell = visibleCityEntryCell() {
                cell.configure(
                    cityText: state.cityText,
                    selectedCity: state.selectedCity,
                    cities: state.citiesForSelectedPlace
                )
                // Cities arrive async after the cell is already laid out at
                // input-only height. Adding chips changes the cell's intrinsic
                // size, but the table won't re-measure rows on its own — the
                // empty-updates pair forces height recalculation without
                // recreating cells (and without losing text-field focus).
                tableView.performBatchUpdates(nil)
            } else if citySelectionChanged, let cell = visibleCityEntryCell() {
                cell.updateChipSelection(state.selectedCity)
            }
            // Pure cityText changes (user typing) don't require any cell update
            // — the text field is the source of truth during typing.
        }
    }

    // MARK: - City-row expand/collapse animation

    /// Describes an isolated city-row toggle between two consecutive states.
    /// `removedCityPath` is in OLD indexing; `insertedCityPath` in NEW indexing.
    /// Country-row refreshes are no longer index-based — they happen via
    /// in-place mutation of visible cells (see `animateCityRowToggle`).
    private struct CityRowTogglePlan {
        let removedCityPath: IndexPath?
        let insertedCityPath: IndexPath?
    }

    /// Returns an animation plan when the only structural difference between
    /// `oldSections` and `newSections` is the position of the single
    /// `cityEntry` row (i.e. the user changed their country selection).
    /// Returns `nil` for broader changes (search query, catalog reload) so the
    /// caller falls back to `tableView.reloadData()`.
    private func cityRowTogglePlan(
        from oldSections: [CountrySection],
        oldSelected: CatalogPlace?,
        to newSections: [CountrySection],
        newSelected: CatalogPlace?
    ) -> CityRowTogglePlan? {
        // 1. After stripping city rows, both shapes must match — otherwise
        //    something more than a selection toggle changed.
        guard Self.stripCityRows(oldSections) == Self.stripCityRows(newSections) else {
            return nil
        }
        let removedCity = Self.findCityEntryIndexPath(in: oldSections)
        let insertedCity = Self.findCityEntryIndexPath(in: newSections)
        guard removedCity != insertedCity else { return nil }
        // Callers (oldSelected/newSelected args) drive the in-place country
        // refresh, so we don't need to bake their paths into the plan.
        _ = oldSelected
        _ = newSelected

        return CityRowTogglePlan(
            removedCityPath: removedCity,
            insertedCityPath: insertedCity
        )
    }

    private func animateCityRowToggle(plan: CityRowTogglePlan, oldSections: [CountrySection]) {
        // Mutate every visible country cell in place to match `currentState`
        // (already updated to the new state by the caller). Done BEFORE the
        // batch begins so badge/checkmark/separator update on the same frame
        // as the tap — there's no perceptible lag where the old highlight
        // hangs around while the city row is fading.
        for cell in tableView.visibleCells {
            guard let oldPath = tableView.indexPath(for: cell),
                  oldPath.section < oldSections.count,
                  oldPath.row < oldSections[oldPath.section].rows.count else { continue }
            guard case .country(let place) = oldSections[oldPath.section].rows[oldPath.row] else {
                continue
            }
            applyCountryCellConfig(cell, place: place)
        }

        // City row fades in/out on its own.
        tableView.performBatchUpdates {
            if let removed = plan.removedCityPath {
                tableView.deleteRows(at: [removed], with: .fade)
            }
            if let inserted = plan.insertedCityPath {
                tableView.insertRows(at: [inserted], with: .fade)
            }
        }
    }

    private static func stripCityRows(_ sections: [CountrySection]) -> [CountrySection] {
        sections.map { section in
            CountrySection(
                continent: section.continent,
                rows: section.rows.filter {
                    if case .cityEntry = $0 { return false }
                    return true
                }
            )
        }
    }

    private static func findCityEntryIndexPath(in sections: [CountrySection]) -> IndexPath? {
        for (s, section) in sections.enumerated() {
            for (r, row) in section.rows.enumerated() {
                if case .cityEntry = row {
                    return IndexPath(row: r, section: s)
                }
            }
        }
        return nil
    }

    private func applyLoadingState(_ state: AddWishlistCountryLoadingState) {
        switch state {
        case .loading:
            searchBar.isHidden = true
            tableView.isHidden = true
            addButton.isHidden = true
            errorContainer.isHidden = true
            loadingIndicator.startAnimating()
        case .loaded:
            loadingIndicator.stopAnimating()
            errorContainer.isHidden = true
            searchBar.isHidden = false
            tableView.isHidden = false
        case .error:
            loadingIndicator.stopAnimating()
            searchBar.isHidden = true
            tableView.isHidden = true
            addButton.isHidden = true
            errorContainer.isHidden = false
        }
    }

    private func visibleCityEntryCell() -> CityEntryCell? {
        tableView.visibleCells.compactMap { $0 as? CityEntryCell }.first
    }

    private func scrollToPlace(code: String) {
        for (si, section) in sections.enumerated() {
            for (ri, row) in section.rows.enumerated() {
                if case .country(let p) = row, p.code == code {
                    tableView.scrollToRow(at: IndexPath(row: ri, section: si), at: .middle, animated: true)
                    return
                }
            }
        }
    }

    private func presentLocationError(_ error: CurrentLocationError) {
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
        viewModel.didTapCurrentLocation()
    }

    @objc private func didTapAdd() {
        viewModel.didTapAdd()
    }

    @objc private func didTapRetry() {
        viewModel.didTapRetry()
    }

}

// MARK: - UISearchBarDelegate

extension AddWishlistCountryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.didChangeSearchQuery(searchText)
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
        case .country(let place):
            return countryCell(for: place, at: indexPath)
        case .cityEntry(let countryCode):
            return cityEntryCell(countryCode: countryCode, at: indexPath)
        }
    }

    private func countryCell(for place: CatalogPlace, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        applyCountryCellConfig(cell, place: place)
        return cell
    }

    /// Applies all visual state for a country cell. Pulled out of the dequeue
    /// path so the city-row animation can refresh visible country cells in
    /// place — without `reloadRows`, which would lag a beat behind the
    /// fade-in/out and leave the badge / checkmark / separator looking stale.
    fileprivate func applyCountryCellConfig(_ cell: UITableViewCell, place: CatalogPlace) {
        let isSelected = place.code == currentState?.selectedPlace?.code

        var content = cell.defaultContentConfiguration()
        content.text = "\(place.flag)  \(place.localizedName)"
        content.textProperties.font = .systemFont(ofSize: 20)
        cell.contentConfiguration = content
        cell.accessoryType = .none
        cell.accessoryView = CatalogPlaceBadgeView.accessoryView(for: place.status, isSelected: isSelected)
        cell.tintColor = .systemBlue

        let cellBackground: UIColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.08) : .clear
        var bg = UIBackgroundConfiguration.clear()
        bg.backgroundColor = cellBackground
        cell.backgroundConfiguration = bg
        cell.backgroundColor = cellBackground
        cell.contentView.backgroundColor = .clear

        // Hide separator on the selected row AND on the row immediately above
        // it, so no gray line appears above the blue expanded block.
        let precedes = precedesSelectedCountry(place)
        cell.separatorInset = (isSelected || precedes)
            ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            : tableView.separatorInset
    }

    /// True when the country immediately following `place` in its section is
    /// the currently selected place — i.e. `place` sits directly above the
    /// expanded card and should hide its bottom separator.
    private func precedesSelectedCountry(_ place: CatalogPlace) -> Bool {
        guard let selectedCode = currentState?.selectedPlace?.code else { return false }
        for section in sections {
            for (idx, row) in section.rows.enumerated() {
                if case .country(let p) = row, p.code == place.code {
                    let nextRowIndex = idx + 1
                    guard nextRowIndex < section.rows.count else { return false }
                    if case .country(let next) = section.rows[nextRowIndex] {
                        return next.code == selectedCode
                    }
                    return false
                }
            }
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

        let state = currentState
        cell.configure(
            cityText: state?.cityText ?? "",
            selectedCity: state?.selectedCity,
            cities: state?.citiesForSelectedPlace ?? []
        )

        cell.onCityTextChanged = { [weak self] text in
            self?.viewModel.didChangeCityText(text)
        }
        cell.onCitySelected = { [weak self] city in
            self?.viewModel.didSelectCity(city)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension AddWishlistCountryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard case .country(let place) = sections[indexPath.section].rows[indexPath.row] else { return }
        viewModel.didTapPlaceRow(place)
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].continent?.localizedName
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].continent == nil
            ? CGFloat.leastNonzeroMagnitude
            : UITableView.automaticDimension
    }
}
