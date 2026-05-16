// AddWishlistCountryViewController.swift
// Xplora

import SnapKit
import UIKit

@MainActor
final class AddWishlistCountryViewController: UIViewController {
    var onSelect: ((WishlistCountry) -> Void)?

    private let getCatalogPlacesUseCase: GetCatalogPlacesUseCase
    private let getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addButton = UIButton(type: .system)

    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorContainer = UIView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private var currentLocationBarButton: UIBarButtonItem?

    private let locationProvider: CurrentCountryProviding = CurrentCountryProvider()

    private var places: [CatalogPlace] = []
    private var sections: [CountrySection] = []
    private var searchQuery = ""

    private var selectedPlace: CatalogPlace? { didSet { updateAddButton() } }
    private var selectedCity: CatalogCity?
    private var citiesForSelectedPlace: [CatalogCity] = []
    private var cityText = ""

    private let screenBackground = UIColor.systemBackground

    init(
        getCatalogPlacesUseCase: GetCatalogPlacesUseCase,
        getCitiesForPlaceUseCase: GetCitiesForPlaceUseCase
    ) {
        self.getCatalogPlacesUseCase = getCatalogPlacesUseCase
        self.getCitiesForPlaceUseCase = getCitiesForPlaceUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCatalog()
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
        // `.minimal` still keeps a 1pt hairline at the bar's bottom edge on
        // some iOS versions — an empty background image suppresses it.
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = screenBackground
        searchBar.delegate = self

        // Use the host view's background everywhere: table view, cells and the
        // search bar all sit on the same surface, so the section-header blur
        // and the search-bar area read as the same colour.
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

    // MARK: - Loading

    private func loadCatalog() {
        showLoading()

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await getCatalogPlacesUseCase.execute()
                self.places = result
                self.showLoaded()
            } catch {
                self.showError()
            }
        }
    }

    private func showLoading() {
        searchBar.isHidden = true
        tableView.isHidden = true
        addButton.isHidden = true
        errorContainer.isHidden = true
        loadingIndicator.startAnimating()
        currentLocationBarButton?.isEnabled = false
    }

    private func showLoaded() {
        loadingIndicator.stopAnimating()
        errorContainer.isHidden = true
        searchBar.isHidden = false
        tableView.isHidden = false
        currentLocationBarButton?.isEnabled = true
        rebuildSections()
    }

    private func showError() {
        loadingIndicator.stopAnimating()
        searchBar.isHidden = true
        tableView.isHidden = true
        addButton.isHidden = true
        errorLabel.text = L10n.Wishlist.Select.Error.load
        errorContainer.isHidden = false
        currentLocationBarButton?.isEnabled = false
    }

    @objc private func didTapRetry() {
        loadCatalog()
    }

    // MARK: - Sections
    //
    // Sections and search share the same source (`places`). A place is either in
    // exactly one continent bucket, or in the "Other" fallback. A search result
    // appears iff the underlying place is also in a continent / Other section.

    private func rebuildSections() {
        let expanded = selectedPlace?.code
        if searchQuery.isEmpty {
            sections = CatalogSectionBuilder.continentSections(from: places, expandedCode: expanded)
        } else if let results = CatalogSectionBuilder.searchResultsSection(
            from: places,
            query: searchQuery,
            expandedCode: expanded
        ) {
            sections = [results]
        } else {
            sections = []
        }
        tableView.reloadData()
    }

    private func updateAddButton() {
        let active = selectedPlace != nil
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
                selectPlace(byCode: code)
            case .failure(let error):
                showLocationError(error)
            }
        }
    }

    /// Selects a place only if the policy recognises the code. Unsupported
    /// codes (e.g. an obscure territory not in the Xplora catalog) surface as
    /// a "country not found" error rather than picking something silently.
    private func selectPlace(byCode code: String) {
        guard let place = places.first(where: { $0.code == code }) else {
            showLocationError(.countryNotFound)
            return
        }
        searchQuery = ""
        searchBar.text = ""
        selectedPlace = place
        selectedCity = nil
        citiesForSelectedPlace = []
        cityText = ""
        rebuildSections()
        scrollToSelectedPlace()
        loadCities(for: place)
    }

    private func loadCities(for place: CatalogPlace) {
        let placeCode = place.code
        Task { [weak self] in
            guard let self else { return }
            let result = (try? await self.getCitiesForPlaceUseCase.execute(placeCode: placeCode)) ?? []
            // Drop the result if the selection moved on while loading.
            guard self.selectedPlace?.code == placeCode else { return }
            self.citiesForSelectedPlace = result
            self.rebuildSections()
        }
    }

    private func scrollToSelectedPlace() {
        for (si, section) in sections.enumerated() {
            for (ri, row) in section.rows.enumerated() {
                if case .country(let p) = row, p.code == selectedPlace?.code {
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
        guard let place = selectedPlace else { return }
        let trimmed = cityText.trimmingCharacters(in: .whitespacesAndNewlines)

        // If a curated city was chosen, prefer its localization key. Otherwise
        // fall back to the typed text (or the city's fallback name if it has
        // no L10n key) so the WishlistCountry round-trips correctly later.
        let cityKey = selectedCity.flatMap(\.nameKey)
        let note: String? = {
            if let cityKey, !cityKey.isEmpty { return nil }
            if let city = selectedCity { return city.fallbackName }
            return trimmed.isEmpty ? nil : trimmed
        }()

        let country = WishlistCountry(
            id: UUID(),
            code: place.code,
            flag: place.flag,
            name: place.name,
            cityKey: cityKey,
            note: note,
            isCompleted: false,
            addedAt: Date()
        )
        dismiss(animated: true) { [weak self] in self?.onSelect?(country) }
    }

    // MARK: - Accessory view

    private func makeAccessoryView(badge: String?, isSelected: Bool) -> UIView? {
        let badgeView: CatalogPlaceBadgeView? = badge.map { CatalogPlaceBadgeView(text: $0) }
        let checkmark: UIImageView? = isSelected
            ? {
                let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
                let imageView = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: cfg))
                imageView.tintColor = .systemBlue
                imageView.contentMode = .center
                return imageView
            }()
            : nil

        let parts: [UIView] = [badgeView, checkmark].compactMap { $0 }
        guard !parts.isEmpty else { return nil }

        if parts.count == 1 {
            let view = parts[0]
            view.frame = CGRect(origin: .zero, size: view.intrinsicContentSize)
            return view
        }

        // Explicit frame math: `accessoryView` is sized from `frame.size`, and
        // `systemLayoutSizeFitting` on a standalone view (no parent in the
        // Auto Layout engine) is unreliable. Compose manually using each
        // child's intrinsic size.
        let spacing: CGFloat = 6
        let sizes = parts.map { $0.intrinsicContentSize }
        let totalWidth = sizes.reduce(0) { $0 + $1.width } + CGFloat(parts.count - 1) * spacing
        let maxHeight = sizes.map(\.height).max() ?? 0

        let container = UIView(frame: CGRect(x: 0, y: 0, width: totalWidth, height: maxHeight))
        var x: CGFloat = 0
        for (view, size) in zip(parts, sizes) {
            view.frame = CGRect(
                x: x,
                y: (maxHeight - size.height) / 2,
                width: size.width,
                height: size.height
            )
            container.addSubview(view)
            x += size.width + spacing
        }
        return container
    }
}

// MARK: - UISearchBarDelegate

extension AddWishlistCountryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedPlace = nil
        selectedCity = nil
        citiesForSelectedPlace = []
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
        case .country(let place):
            return countryCell(for: place, at: indexPath)
        case .cityEntry(let countryCode):
            return cityEntryCell(countryCode: countryCode, at: indexPath)
        }
    }

    private func countryCell(for place: CatalogPlace, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        let isSelected = place.code == selectedPlace?.code

        var content = cell.defaultContentConfiguration()
        content.text = "\(place.flag)  \(place.localizedName)"
        content.textProperties.font = .systemFont(ofSize: 20)
        cell.contentConfiguration = content
        cell.accessoryType = .none
        cell.accessoryView = makeAccessoryView(badge: place.status.badgeLabel, isSelected: isSelected)
        cell.tintColor = .systemBlue

        let cellBackground: UIColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.08) : .clear
        var bg = UIBackgroundConfiguration.clear()
        bg.backgroundColor = cellBackground
        cell.backgroundConfiguration = bg
        cell.backgroundColor = cellBackground
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
            return next.code == selectedPlace?.code
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

        let cities = citiesForSelectedPlace
        cell.configure(cityText: cityText, selectedCity: selectedCity, cities: cities)

        cell.onCityTextChanged = { [weak self] text in
            guard let self else { return }
            let hadSelection = selectedCity != nil
            cityText = text
            if hadSelection && text != selectedCity?.displayName {
                selectedCity = nil
                (tableView.cellForRow(at: indexPath) as? CityEntryCell)?.updateChipSelection(nil)
            }
        }

        cell.onCitySelected = { [weak self] city in
            guard let self else { return }
            selectedCity = city
            cityText = city.displayName
            (tableView.cellForRow(at: indexPath) as? CityEntryCell)?
                .configure(cityText: cityText, selectedCity: selectedCity, cities: cities)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension AddWishlistCountryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard case .country(let place) = sections[indexPath.section].rows[indexPath.row] else { return }
        let isSame = place.code == selectedPlace?.code
        selectedPlace = isSame ? nil : place
        selectedCity = nil
        citiesForSelectedPlace = []
        cityText = ""
        rebuildSections()
        if let newPlace = selectedPlace { loadCities(for: newPlace) }
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
        // Returning a String (not a custom view) opts us into the system header
        // for `.plain`-style tables: sticky pinned, translucent blurred
        // background, system typography.
        sections[section].continent?.localizedName
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].continent == nil
            ? CGFloat.leastNonzeroMagnitude
            : UITableView.automaticDimension
    }
}
