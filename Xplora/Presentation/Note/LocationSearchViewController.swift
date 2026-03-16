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
    private let completer = MKLocalSearchCompleter()
    private var completions: [MKLocalSearchCompletion] = []
    private var isResolvingSelection = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Location"
        configureSearchBar()
        configureTableView()
        configureCompleter()
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    private func configureSearchBar() {
        searchBar.placeholder = "Search location"
        searchBar.autocapitalizationType = .words
        searchBar.delegate = self
    }

    private func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()
    }

    private func configureCompleter() {
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    private func setupLayout() {
        view.addSubview(searchBar)
        view.addSubview(tableView)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
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
            title: "Location unavailable",
            message: "Couldn't fetch this location. Try another one.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LocationSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        completions = []
        tableView.reloadData()
        completer.queryFragment = query
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension LocationSearchViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
        tableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
        tableView.reloadData()
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
