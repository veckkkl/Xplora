//
//  CountryPickerViewController.swift
//  Xplora
//

import SnapKit
import UIKit

@MainActor
final class CountryPickerViewController: UIViewController {

    var onSelect: ((CatalogPlace) -> Void)?

    private let getCatalogPlaces: GetCatalogPlacesUseCase

    private var sections: [(letter: String, places: [CatalogPlace])] = []

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.sectionIndexColor = .systemBlue
        return tv
    }()

    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    init(getCatalogPlaces: GetCatalogPlacesUseCase) {
        self.getCatalogPlaces = getCatalogPlaces
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Onboarding.Country.pickerTitle
        view.backgroundColor = .systemBackground

        loadingIndicator.hidesWhenStopped = true

        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingIndicator.snp.makeConstraints { $0.center.equalTo(view.safeAreaLayoutGuide) }

        loadCatalog()
    }

    private func loadCatalog() {
        loadingIndicator.startAnimating()
        Task { [weak self] in
            guard let self else { return }
            let places = (try? await self.getCatalogPlaces.execute()) ?? []
            self.applyAlphabetSections(from: places)
            self.loadingIndicator.stopAnimating()
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }

    private func applyAlphabetSections(from places: [CatalogPlace]) {
        let grouped = Dictionary(grouping: places) {
            String($0.localizedName.prefix(1)).uppercased()
        }
        sections = grouped.keys
            .sorted()
            .map { letter in
                let rows = grouped[letter]!.sorted {
                    $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending
                }
                return (letter, rows)
            }
    }
}

extension CountryPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].places.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].letter
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        sections.map(\.letter)
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        index
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let place = sections[indexPath.section].places[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(place.flag)  \(place.localizedName)"
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let place = sections[indexPath.section].places[indexPath.row]
        onSelect?(place)
        navigationController?.popViewController(animated: true)
    }
}
