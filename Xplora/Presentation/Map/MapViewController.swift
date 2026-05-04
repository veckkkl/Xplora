//
//  MapViewController.swift
//  Xplora


import MapKit
import SnapKit
import UIKit

final class MapViewController: UIViewController {
    private let viewModel: MapViewModelInput & MapViewModelOutput

    private let mapView = MKMapView()
    private let actionsContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let notesButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private var didSetInitialCamera = false

    init(viewModel: MapViewModelInput & MapViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMapView()
        setupActionButtons()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setPlanetCameraIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupMapView() {
        mapView.mapType = .hybridFlyover
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsBuildings = false
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.cameraBoundary = nil
        mapView.cameraZoomRange = nil
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: CountryVisitAnnotationView.reuseIdentifier)
        view.addSubview(mapView)

        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupActionButtons() {
        actionsContainer.clipsToBounds = true
        actionsContainer.layer.cornerRadius = 16
        actionsContainer.layer.cornerCurve = .continuous
        view.addSubview(actionsContainer)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 6
        actionsContainer.contentView.addSubview(stack)

        var notesConfiguration = UIButton.Configuration.tinted()
        notesConfiguration.title = L10n.Map.Actions.notes
        notesConfiguration.image = UIImage(systemName: "note.text")
        notesConfiguration.imagePadding = 6
        notesConfiguration.baseForegroundColor = .systemBlue
        notesConfiguration.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.22)
        notesConfiguration.cornerStyle = .medium
        notesConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        notesButton.configuration = notesConfiguration
        notesButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold),
            forImageIn: .normal
        )
        notesButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        notesButton.addTarget(self, action: #selector(didTapNotes), for: .touchUpInside)

        var addConfiguration = UIButton.Configuration.tinted()
        addConfiguration.image = UIImage(systemName: "plus")
        addConfiguration.baseForegroundColor = .systemBlue
        addConfiguration.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.22)
        addConfiguration.cornerStyle = .medium
        addConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        addButton.configuration = addConfiguration
        addButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold),
            forImageIn: .normal
        )
        addButton.addTarget(self, action: #selector(didTapAddNote), for: .touchUpInside)

        stack.addArrangedSubview(notesButton)
        stack.addArrangedSubview(addButton)

        actionsContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(16)
        }

        stack.snp.makeConstraints { make in
            make.edges.equalTo(actionsContainer.contentView).inset(8)
        }

        addButton.snp.makeConstraints { make in
            make.width.equalTo(40)
        }
    }

    private func bindViewModel() {
        viewModel.onMarkersUpdated = { [weak self] markers in
            self?.renderMarkers(markers)
        }
        viewModel.onOverlaysUpdated = { [weak self] overlays in
            self?.renderOverlays(overlays)
        }
    }

    private func setPlanetCameraIfNeeded() {
        guard !didSetInitialCamera else { return }
        guard mapView.bounds.width > 0 else { return }
        didSetInitialCamera = true
        setPlanetCamera()
    }

    private func setPlanetCamera() {
        let center = CLLocationCoordinate2D(latitude: 20, longitude: 0)
        let camera = MKMapCamera(lookingAtCenter: center, fromDistance: 20_000_000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: false)
    }

    private func renderMarkers(_ markers: [CountryVisitMarker]) {
        let removable = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(removable)
        let annotations = markers.map { CountryVisitAnnotation(marker: $0) }
        mapView.addAnnotations(annotations)
    }

    private func renderOverlays(_ overlays: [MKOverlay]) {
        mapView.removeOverlays(mapView.overlays)
        guard !overlays.isEmpty else { return }
        mapView.addOverlays(overlays)
    }

    @objc private func didTapAddNote() {
        viewModel.didTapAddNote()
    }

    @objc private func didTapNotes() {
        viewModel.didTapNotes()
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? CountryVisitAnnotation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: CountryVisitAnnotationView.reuseIdentifier, for: annotation)
        view.annotation = annotation

        if let markerView = view as? MKMarkerAnnotationView {
            markerView.canShowCallout = true
            markerView.markerTintColor = UIColor(named: "accent_orange") ?? .systemOrange
            markerView.glyphImage = UIImage(systemName: "mappin")
            markerView.titleVisibility = .hidden
            markerView.subtitleVisibility = .hidden
            let previewModel = viewModel.previewModel(for: annotation.marker)
            let calloutView = TripNoteCalloutView(model: previewModel)
            calloutView.onTap = { [weak self] in
                self?.viewModel.didSelectMarker(annotation.marker)
            }
            markerView.detailCalloutAccessoryView = calloutView
        }

        return view
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKOverlayRenderer(overlay: overlay)
    }
}
