//
//  Note.swift
//  Xplora
//
//  Created by valentina balde on 11/14/25.
//

import Foundation

struct Note: Identifiable, Equatable {
    let id: String
    let coordinate: LocationCoordinate
    var title: String?
    var text: String
    var photoURLs: [URL]
    var createdAt: Date
    var updatedAt: Date
    var city: String?
    var country: String?
    var isBookmarked: Bool
    var dateRangeText: String?
    var headerTitle: String?
}
