// CitySuggestionsProvider.swift
// Xplora

import Foundation

protocol CitySuggestionsProviding {
    func suggestions(for countryCode: String) -> [CitySuggestion]
}

final class StaticCitySuggestionsProvider: CitySuggestionsProviding {
    func suggestions(for countryCode: String) -> [CitySuggestion] {
        LocalizedCityCatalog.cities[countryCode] ?? []
    }
}
