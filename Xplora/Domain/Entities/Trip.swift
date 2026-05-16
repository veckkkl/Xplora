//
//  Trip.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

struct Trip: Identifiable, Equatable, Codable {
    let id: UUID
    let country: Country
    let startDate: Date
    let endDate: Date
    let notesCount: Int
    let visitedPlaces: [VisitedPlace]
}

struct VisitedPlace: Identifiable, Equatable, Codable {
    let id: UUID
    let city: City
    let date: Date
}
