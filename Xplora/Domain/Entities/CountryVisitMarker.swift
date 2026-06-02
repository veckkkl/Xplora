//
//  CountryVisitMarker.swift
//  Xplora
//
//  Created by valentina balde on 11/20/25.
//

import CoreLocation

/// One pin on the map. Carries `noteIds` (not just one) so a group of notes
/// pinned at the exact same coordinate is represented by a single marker.
/// MapKit clusters handle the *near* case; same-coordinate is handled here.
struct CountryVisitMarker {
    let countryCode: String
    let title: String
    let dateRangeText: String
    let coordinate: CLLocationCoordinate2D
    let noteIds: [String]

    var firstNoteId: String? { noteIds.first }
}
