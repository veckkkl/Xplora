//
//  CountryCatalog.swift
//  Xplora
//

import Foundation

enum CountryCatalog {
    static func allCountries() -> [Country] {
        let current = Locale.autoupdatingCurrent
        let english = Locale(identifier: "en")
        let isEnglish = current.language.languageCode?.identifier == "en"

        return Locale.isoRegionCodes
            .compactMap { code -> Country? in
                guard let name = current.localizedString(forRegionCode: code) else { return nil }
                // Drop entries where localization fell back to English in a non-English locale,
                // which means the system has no translation for this region code.
                if !isEnglish,
                   let englishName = english.localizedString(forRegionCode: code),
                   name == englishName {
                    return nil
                }
                return Country(id: UUID(), code: code, name: name, regions: [])
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
