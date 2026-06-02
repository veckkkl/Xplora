//
//  CountryVisitAnnotationView.swift
//  Xplora


import MapKit

final class CountryVisitAnnotationView: MKMarkerAnnotationView {
    static let reuseIdentifier = "CountryVisitAnnotationView"
    /// Shared cluster bucket — every per-note marker opts into MapKit's
    /// automatic grouping at low zoom levels. The cluster annotation it
    /// produces gets rendered by `CountryVisitClusterAnnotationView`.
    static let clusterID = "country-visit-cluster"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        canShowCallout = true
        markerTintColor = UIColor(named: "accent_orange") ?? .systemOrange
        glyphImage = UIImage(systemName: "mappin")
        titleVisibility = .hidden
        subtitleVisibility = .hidden
        displayPriority = .defaultHigh
        clusteringIdentifier = Self.clusterID
    }
}
