//
//  TripNotePreviewViewModel.swift
//  Xplora

import Foundation

struct TripNotePreviewViewModel {
    let title: String
    let dateRange: String
    let photoURLs: [URL]
    let photoOverflowCount: Int
    let isBookmarked: Bool
    let locationTitle: String?
    let locationSubtitle: String?
    let locationChipText: String?
    let textPreview: String

    var placeTitle: String? {
        locationChipText ?? locationTitle
    }
}
