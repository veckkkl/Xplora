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
                onStateChange?(.error("Не удалось загрузить статистику"))
            }
        }
    }

    // MARK: - Mapping

    private func makeViewData(from summary: StatisticsSummary) -> StatisticsViewData {
        StatisticsViewData(
            totalCard: StatisticsTotalCardViewData(
                title: "Всего",
                subtitle: "Среди \(summary.totalUNCount) стран ООН",
                leftValue: "\(summary.worldProgressPercent) %",
                leftCaption: "Мир",
                rightValue: "\(summary.visitedUNCount)",
                rightCaption: "Страны",
                progress: Double(summary.worldProgressPercent) / 100.0
            ),
            continentsCard: StatisticsSingleValueCardViewData(
                title: "Континенты",
                subtitle: "Включая Антарктику",
                value: "\(summary.visitedContinentsCount) / \(summary.totalContinentsCount)"
            ),
            countriesCard: StatisticsSingleValueCardViewData(
                title: "Страны",
                subtitle: "Страны, признанные ООН",
                value: "\(summary.visitedUNCount) / \(summary.totalUNCount)"
            ),
            continentCards: summary.continentItems.map { item in
                StatisticsSingleValueCardViewData(
                    title: item.continent.russianName,
                    subtitle: item.continent.subtitleText,
                    value: "\(item.visitedCount) / \(item.totalCount)"
                )
            }
        )
    }
}

// MARK: - Continent + Russian name

private extension Continent {
    var russianName: String {
        switch self {
        case .africa:       return "Африка"
        case .asia:         return "Азия"
        case .europe:       return "Европа"
        case .northAmerica: return "Северная Америка"
        case .southAmerica: return "Южная Америка"
        case .oceania:      return "Океания"
        case .antarctica:   return "Антарктика"
        case .other:        return "Другое"
        }
    }

    var subtitleText: String {
        self == .antarctica ? "Все территории" : "Страны, признанные ООН"
    }
}
