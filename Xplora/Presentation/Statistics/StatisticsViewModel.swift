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

    init(getStatisticsUseCase: GetStatisticsUseCase) {
        self.getStatisticsUseCase = getStatisticsUseCase
    }

    func viewDidLoad() {
        onStateChange?(.loading)
        Task {
            do {
                let summary = try await getStatisticsUseCase.execute()
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
                rightCaption: "Страны"
            ),
            continentsCard: StatisticsSingleValueCardViewData(
                title: "Континенты",
                subtitle: "Включая Антарктику",
                value: "\(summary.visitedContinentsCount) / \(summary.totalContinentsCount)"
            ),
            countriesCard: StatisticsSingleValueCardViewData(
                title: "Страны",
                subtitle: "Среди \(summary.totalUNCount) стран ООН",
                value: "\(summary.visitedUNCount) / \(summary.totalUNCount)"
            ),
            continentCards: summary.continentItems.map { item in
                StatisticsSingleValueCardViewData(
                    title: item.continent.russianName,
                    subtitle: "Среди \(item.totalCount) стран ООН",
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
}
