//
//  CountryPickerViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class CountryPickerViewController: UIViewController {

    var onSelect: ((CountryOption) -> Void)?

    private let sections: [(letter: String, countries: [CountryOption])] = {
        let all = CountryOption.all()
        let grouped = Dictionary(grouping: all) { String($0.name.prefix(1)).uppercased() }
        return grouped.keys.sorted().map { letter in
            (letter, grouped[letter]!)
        }
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.sectionIndexColor = .systemBlue
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Onboarding.Country.pickerTitle
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

extension CountryPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].countries.count
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
        let country = sections[indexPath.section].countries[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(country.flagEmoji)  \(country.name)"
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect?(sections[indexPath.section].countries[indexPath.row])
        dismiss(animated: true)
    }
}
