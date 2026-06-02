//
//  CountryVisitClusterAnnotationView.swift
//  Xplora
//

import MapKit

/// Rendered by MapKit whenever multiple `CountryVisitAnnotation`s collapse
/// into an `MKClusterAnnotation`. The orange-pin look matches the per-note
/// marker, and the glyph text shows how many notes are inside so the user
/// can predict the carousel size before tapping.
final class CountryVisitClusterAnnotationView: MKMarkerAnnotationView {
    static let reuseIdentifier = "CountryVisitClusterAnnotationView"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override var annotation: MKAnnotation? {
        didSet { applyCount() }
    }

    private func configure() {
        canShowCallout = true
        // Red is the cluster signal — same convention as multi-note same-
        // coordinate pins. Single-note pins stay orange via
        // `CountryVisitAnnotationView`.
        markerTintColor = .systemRed
        titleVisibility = .hidden
        subtitleVisibility = .hidden
        displayPriority = .required
        collisionMode = .circle
        applyCount()
    }

    private func applyCount() {
        guard let cluster = annotation as? MKClusterAnnotation else {
            glyphText = nil
            glyphImage = UIImage(systemName: "mappin")
            return
        }
        glyphImage = nil
        glyphText = "\(cluster.memberAnnotations.count)"
    }
}
