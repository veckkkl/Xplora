//
//  CountryOption.swift
//  Xplora
//

import Foundation

struct CountryOption: Hashable {
    let code: String
    let name: String

    var flagEmoji: String {
        code.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    static func all() -> [CountryOption] {
        let current = Locale.current
        let english = Locale(identifier: "en")
        let isEnglish = current.language.languageCode?.identifier == "en"

        return Locale.isoRegionCodes
            .compactMap { code -> CountryOption? in
                guard let name = current.localizedString(forRegionCode: code) else { return nil }
                // Drop entries that fell back to English in a non-English locale.
                if !isEnglish,
                   let englishName = english.localizedString(forRegionCode: code),
                   name == englishName {
                    return nil
                }
                return CountryOption(code: code, name: name)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
