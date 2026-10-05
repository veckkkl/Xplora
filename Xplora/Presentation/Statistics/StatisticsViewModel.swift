//
//  StatisticsViewModel.swift
//  Xplora
//

import Foundation

enum StatisticsViewState {
    case idle
    case loading
    case content(StatisticsViewData)
    case error(String)
}

@MainActor
final class StatisticsViewModel {
    var onStateChange: ((StatisticsViewState) -> Void)?

    private let getStatisticsUseCase: GetStatisticsUseCase
    private var hasLoadedOnce = false

    init(getStatisticsUseCase: GetStatisticsUseCase) {
        self.getStatisticsUseCase = getStatisticsUseCase
    }

    func viewDidLoad() {
        load(showLoadingSpinner: true)
    }

    /// Re-fetches statistics whenever the screen becomes visible (e.g. user
    /// just added a trip on the Timeline tab and switched back here). The
    /// spinner is suppressed on subsequent loads so the existing cards stay
    /// on screen and silently update once new data arrives.
    func viewWillAppear() {
        guard hasLoadedOnce else { return }
        load(showLoadingSpinner: false)
    }

    private func load(showLoadingSpinner: Bool) {
        if showLoadingSpinner {
            onStateChange?(.loading)
        }
        Task {
            do {
                let summary = try await getStatisticsUseCase.execute()
                hasLoadedOnce = true
                onStateChange?(.content(makeViewData(from: summary)))
            } catch {
                onStateChange?(.error(L10n.Statistics.Error.load))
            }
        }
    }

    // MARK: - Mapping

    private func makeViewData(from summary: StatisticsSummary) -> StatisticsViewData {
        StatisticsViewData(
            totalCard: StatisticsTotalCardViewData(
                title: L10n.Statistics.Total.title,
                subtitle: L10n.Statistics.Total.subtitle(summary.totalUNCount),
                leftValue: L10n.Statistics.percent(summary.worldProgressPercent),
                leftCaption: L10n.Statistics.Total.world,
                rightValue: "\(summary.visitedUNCount)",
                rightCaption: L10n.Statistics.Total.countries,
                progress: Double(summary.worldProgressPercent) / 100.0
            ),
            continentsCard: StatisticsSingleValueCardViewData(
                title: L10n.Statistics.Continents.title,
                subtitle: L10n.Statistics.Continents.subtitle,
                value: "\(summary.visitedContinentsCount) / \(summary.totalContinentsCount)"
            ),
            countriesCard: StatisticsSingleValueCardViewData(
                title: L10n.Statistics.Countries.title,
                subtitle: L10n.Statistics.Countries.subtitle,
                value: "\(summary.visitedUNCount) / \(summary.totalUNCount)"
            ),
            continentCards: summary.continentItems.map { item in
                StatisticsSingleValueCardViewData(
                    title: item.continent.localizedName,
                    subtitle: item.continent.subtitleText,
                    value: "\(item.visitedCount) / \(item.totalCount)"
                )
            }
        )
    }
}

// MARK: - Continent subtitle

private extension Continent {
    var subtitleText: String {
        self == .antarctica
            ? L10n.Statistics.Continent.Subtitle.allTerritories
            : L10n.Statistics.Continent.Subtitle.unCountries
    }
}
