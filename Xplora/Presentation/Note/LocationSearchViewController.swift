//
//  LocationSearchViewController.swift
//  Xplora
//

import MapKit
import SnapKit
import UIKit

final class LocationSearchViewController: UIViewController {
    var onLocationSelected: ((MKMapItem, MKLocalSearchCompletion) -> Void)?

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let completer = MKLocalSearchCompleter()
    private var completions: [MKLocalSearchCompletion] = []
    private var isResolvingSelection = false
    private var hasQuery = false
    private var hasNetworkError = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = L10n.Notes.Location.Search.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
        configureSearchBar()
        configureTableView()
        configureEmptyLabel()
        configureCompleter()
        setupLayout()
        updateEmptyState()
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    private func configureSearchBar() {
        searchBar.placeholder = L10n.Notes.Location.Search.placeholder
        searchBar.autocapitalizationType = .words
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
    }

    private func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()
    }

    private func configureEmptyLabel() {
        emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
    }

    private func configureCompleter() {
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        // Intentionally leaving `completer.region` at its default. Setting a
        // world-wide region was observed to make the completer silently return
        // no results on iOS 18 simulators.
    }

    private func setupLayout() {
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
    }

    private func updateEmptyState() {
        let isEmpty = completions.isEmpty
        if !hasQuery {
            emptyLabel.text = L10n.Notes.Location.Search.placeholder
        } else if hasNetworkError {
            emptyLabel.text = L10n.Notes.Location.Search.Network.message
        } else if isEmpty {
            emptyLabel.text = L10n.Notes.Location.Search.Empty.message
        } else {
            emptyLabel.text = nil
        }
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    private func resolveSelection(for completion: MKLocalSearchCompletion) {
        guard !isResolvingSelection else { return }
        isResolvingSelection = true

        let request = MKLocalSearch.Request(completion: completion)
        Task { [weak self] in
            guard let self else { return }
            defer { self.isResolvingSelection = false }

            do {
                let response = try await MKLocalSearch(request: request).start()
                guard let mapItem = response.mapItems.first else {
                    self.showError()
                    return
                }
                self.onLocationSelected?(mapItem, completion)
                self.dismiss(animated: true)
            } catch {
                self.showError()
            }
        }
    }

    private func showError() {
        let alert = UIAlertController(
            title: L10n.Notes.Location.Search.Error.title,
            message: L10n.Notes.Location.Search.Error.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

extension LocationSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        hasQuery = !query.isEmpty
        hasNetworkError = false
        if query.isEmpty {
            completer.cancel()
            completions = []
            tableView.reloadData()
            updateEmptyState()
            return
        }
        // Don't clear the previous list yet — keep showing the last results
        // until the new ones come back, so the table doesn't flicker empty
        // on every keystroke.
        completer.queryFragment = query
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension LocationSearchViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
        hasNetworkError = false
        tableView.reloadData()
        updateEmptyState()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
        hasNetworkError = Self.isNetworkError(error)
        tableView.reloadData()
        updateEmptyState()
    }

    private static func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }
}

extension LocationSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        completions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let completion = completions[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = completion.title
        config.secondaryText = completion.subtitle
        config.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension LocationSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        resolveSelection(for: completions[indexPath.row])
    }
}
