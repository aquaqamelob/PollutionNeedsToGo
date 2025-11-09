//
//  Mob 5.swift
//  temp
//
//  Created by Norbert on 08/11/2025.
//



import SwiftUI
import MapKit
import CoreLocation

// MARK: - Mob Model
final class Mob: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    let name: String
    var isDefeated: Bool = false

    init(coordinate: CLLocationCoordinate2D, name: String) {
        self.coordinate = coordinate
        self.name = name
    }
}

// MKAnnotation wrapper that keeps a reference to the Mob
final class MobAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    let mob: Mob
    var title: String?

    init(mob: Mob) {
        self.mob = mob
        self.coordinate = mob.coordinate
        self.title = mob.name
        super.init()
    }
}

// MARK: - Main Map View
struct UserMapWithPolygons: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showPolygons = true
    @State private var showTooFarAlert = false
    @State private var selectedMob: Mob?    // ✅ Using this as sheet trigger

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CombinedMap(
                showPolygons: showPolygons,
                userLocation: locationManager.userLocation,
                showTooFarAlert: $showTooFarAlert,
                selectedMob: $selectedMob
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                locationManager.requestPermission()
            }

            VStack(alignment: .trailing, spacing: 8) {
                Text("Your Location 📍")
                    .font(.headline)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)

                Toggle("Show Polygons", isOn: $showPolygons)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
            }
            .padding()
        }
        // MARK: - Alert + Sheet
        .alert("Too far!", isPresented: $showTooFarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need to get closer to the monster to start fighting.")
        }
        .sheet(item: $selectedMob) { mob in
            FightSheet(mob: mob)
        }
    }
}

// MARK: - Map View Representable
struct CombinedMap: UIViewRepresentable {
    var showPolygons: Bool
    var userLocation: CLLocation?
    @Binding var showTooFarAlert: Bool
    @Binding var selectedMob: Mob?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        context.coordinator.mapView = mapView
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.updatePolygons(on: uiView, show: showPolygons)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        weak var mapView: MKMapView?
        var parent: CombinedMap
        private var loadedPolygons: [MKPolygon] = []

        // Store pairs of mob + annotation
        private struct Entry {
            var mob: Mob
            var annotation: MobAnnotation
        }
        private var entries: [Entry] = []

        // Timer that drives mob movement checks/steps
        private var movementTimer: Timer?

        // Movement tuning:
        // - detectionRadius: mobs within this (meters) will start moving toward the user
        // - stepFraction: how much of the remaining distance a mob moves each timer tick (0..1)
        // - tickInterval: how often (seconds) we attempt a movement step
        private let detectionRadius: CLLocationDistance = 500.0
        private let stepFraction: Double = 0.50   // move 20% closer each tick
        private let tickInterval: TimeInterval = 0.35 // seconds

        init(parent: CombinedMap) {
            self.parent = parent
        }

        deinit {
            movementTimer?.invalidate()
        }

        // MARK: - Load polygons and spawn mobs
        func updatePolygons(on mapView: MKMapView, show: Bool) {
            self.mapView = mapView
            if show && loadedPolygons.isEmpty {
                loadPolygons(on: mapView)
                startMovementTimerIfNeeded()
            } else if !show {
                mapView.removeOverlays(loadedPolygons)
                loadedPolygons.removeAll()
                removeAllMobs()
                stopMovementTimer()
            }
        }

        private func loadPolygons(on mapView: MKMapView) {
            guard let url = Bundle.main.url(forResource: "pollution", withExtension: "geojson"),
                  let data = try? Data(contentsOf: url) else {
                print("❌ GeoJSON not found")
                return
            }

            do {
                let features = try MKGeoJSONDecoder().decode(data)
                for feature in features {
                    guard let feature = feature as? MKGeoJSONFeature else { continue }
                    for geometry in feature.geometry {
                        if let multiPolygon = geometry as? MKMultiPolygon {
                            for polygon in multiPolygon.polygons { addPolygon(polygon, to: mapView) }
                        } else if let polygon = geometry as? MKPolygon {
                            addPolygon(polygon, to: mapView)
                        }
                    }
                }
                print("✅ Loaded \(loadedPolygons.count) polygons")
            } catch {
                print("❌ Error decoding GeoJSON: \(error)")
            }
        }

        private func addPolygon(_ polygon: MKPolygon, to mapView: MKMapView) {
            loadedPolygons.append(polygon)
            mapView.addOverlay(polygon)
            for _ in 1...100 { spawnMob(in: polygon) }
        }

        private func spawnMob(in polygon: MKPolygon) {
            guard let mapView = mapView else { return }
            let coord = randomCoordinate(in: polygon)
            let mob = Mob(coordinate: coord, name: ["Goblin", "Slime", "Ghost"].randomElement()!)
            let annotation = MobAnnotation(mob: mob)
            entries.append(Entry(mob: mob, annotation: annotation))

            mapView.addAnnotation(annotation)
            startMovementTimerIfNeeded()
        }

        private func removeAllMobs() {
            guard let mapView = mapView else { return }
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            entries.removeAll()
        }

        private func randomCoordinate(in polygon: MKPolygon) -> CLLocationCoordinate2D {
            let boundingRect = polygon.boundingMapRect
            while true {
                let x = Double.random(in: boundingRect.minX...boundingRect.maxX)
                let y = Double.random(in: boundingRect.minY...boundingRect.maxY)
                let point = MKMapPoint(x: x, y: y)
                let coord = point.coordinate
                if polygon.contains(coord) { return coord }
            }
        }

        // MARK: - Movement Timer
        private func startMovementTimerIfNeeded() {
            guard movementTimer == nil else { return }
            movementTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.movementTick()
                }
            }
            // Ensure it runs in common run loop modes so it updates while scrolling/zooming
            RunLoop.main.add(movementTimer!, forMode: .common)
        }

        private func stopMovementTimer() {
            movementTimer?.invalidate()
            movementTimer = nil
        }

        private func movementTick() {
            guard let mapView = mapView,
                  let userLocation = mapView.userLocation.location else { return }

            for i in entries.indices {
                // If mob already defeated skip (future expansion)
                if entries[i].mob.isDefeated { continue }

                let mob = entries[i].mob
                let annotation = entries[i].annotation

                let mobLocation = CLLocation(latitude: mob.coordinate.latitude, longitude: mob.coordinate.longitude)
                let distance = userLocation.distance(from: mobLocation)

                // If within detection radius, step closer to user
                if distance <= detectionRadius {
                    let userCoord = userLocation.coordinate
                    let next = interpolatedCoordinate(from: mob.coordinate, to: userCoord, fraction: stepFraction)

                    // Update model + annotation (annotation coordinate is KVO-compliant so map will update)
                    mob.coordinate = next
                    // For smoother visual movement, update annotation.coordinate repeatedly at small intervals.
                    // Here we set it directly every tick; because ticks are small (0.35s) and stepFraction is small,
                    // movement will appear reasonably smooth.
                    annotation.coordinate = next
                }
            }
        }

        // simple linear interpolation on lat/lon (sufficient for short distances)
        private func interpolatedCoordinate(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
            let lat = from.latitude + (to.latitude - from.latitude) * fraction
            let lon = from.longitude + (to.longitude - from.longitude) * fraction
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }

        // MARK: - Map Delegate
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer() }
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.purple.withAlphaComponent(0.3)
            renderer.strokeColor = UIColor.purple
            renderer.lineWidth = 2
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let identifier = "Mob"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.markerTintColor = .systemRed
                view?.glyphText = ["👾", "👽", "👻"].randomElement()!
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            fightMob(annotationView: view)
        }

        // MARK: - Fight logic
        private func fightMob(annotationView view: MKAnnotationView) {
            guard let annotation = view.annotation as? MobAnnotation,
                  let userLocation = mapView?.userLocation.location else { return }

            let mob = annotation.mob
            let mobLocation = CLLocation(latitude: mob.coordinate.latitude, longitude: mob.coordinate.longitude)
            let distance = userLocation.distance(from: mobLocation)

            if distance <= 500 { // Within 20m
                parent.selectedMob = mob   // ✅ sheet auto-triggers
                mapView?.deselectAnnotation(annotation, animated: true)
                print("⚔️ Engaging \(mob.name) in combat!")
            } else {
                parent.showTooFarAlert = true
                print("❌ Too far to fight \(mob.name). \(Int(distance))m away.")
            }
        }
    }
}

// MARK: - Polygon Extension
extension MKPolygon {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        // Renderer needs a map rect - create one, the renderer will map the point correctly
        let renderer = MKPolygonRenderer(polygon: self)
        let mapPoint = MKMapPoint(coordinate)
        let point = renderer.point(for: mapPoint)
        return renderer.path?.contains(point) ?? false
    }
}

// MARK: - Fight Sheet
struct FightSheet: View {
    let mob: Mob
    @Environment(\.dismiss) var dismiss
    @State private var mobHP = 100
    @State private var playerHP = 100

    var body: some View {
        VStack(spacing: 20) {
            Text("⚔️ Battle vs \(mob.name)")
                .font(.title)
                .bold()
                .padding(.top)

//            HStack(spacing: 30) {
//                VStack {
//                    Text("🧍 You")
//                    ProgressView(value: Double(playerHP) / 100)
//                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
//                    Text("\(playerHP) HP")
//                }
//
//                VStack {
//                    Text("👾 \(mob.name)")
//                    ProgressView(value: Double(mobHP) / 100)
//                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
//                    Text("\(mobHP) HP")
//                }
//            }
//
//            Spacer()
            
            if let videoURL = Bundle.main.url(forResource: "ghost", withExtension: "mp4") {
                            ReusableVideoPlayer(url: videoURL, autoPlay: true, loop: true, height: 250)
                        } else {
                            Text("Video not found")
                        }

            Button("Attack!") {
                let playerHit = Int.random(in: 10...25)
                let mobHit = Int.random(in: 5...20)

                mobHP -= 100
                playerHP -= mobHit

                if mobHP <= 0 {
                    print("✅ You defeated \(mob.name)!")
                    dismiss()
                } else if playerHP <= 0 {
                    print("💀 You were defeated by \(mob.name).")
                    dismiss()
                }
            }
            .font(.title2)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button("Run Away") {
                dismiss()
            }
            .foregroundColor(.red)
            .padding(.bottom, 40)
        }
        .padding()
        .presentationDetents([.large])
    }
}

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            } else {
                manager.stopUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.userLocation = latest
        }
    }
}


#Preview {
    UserMapWithPolygons()
}
