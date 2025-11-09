////
////  Mob.swift
////  temp
////
////  Created by Norbert on 08/11/2025.
////
//
//
//import SwiftUI
//import MapKit
//import CoreLocation
//
//// MARK: - Models
//struct Mob: Identifiable {
//    let id = UUID()
//    let coordinate: CLLocationCoordinate2D
//    let name: String
//    var isDefeated: Bool = false
//}
//
//struct Zone {
//    let polygon: MKPolygon
//    let isGreenZone: Bool
//}
//
//// MARK: - Main View
//struct UserMapWithPolygons: View {
//    @StateObject private var locationManager = LocationManager()
//    @State private var showPolygons = true
//    @State private var userXP = 0
//
//    var body: some View {
//        ZStack(alignment: .topTrailing) {
//            CombinedMap(showPolygons: showPolygons,
//                        userLocation: locationManager.userLocation,
//                        userXP: $userXP)
//                .edgesIgnoringSafeArea(.all)
//                .onAppear {
//                    locationManager.requestPermission()
//                }
//
//            VStack(alignment: .trailing, spacing: 8) {
//                Text("Your Location 📍")
//                    .font(.headline)
//                    .padding(8)
//                    .background(.ultraThinMaterial)
//                    .cornerRadius(10)
//
//                Toggle("Show Polygons", isOn: $showPolygons)
//                    .labelsHidden()
//                    .toggleStyle(SwitchToggleStyle(tint: .green))
//                    .padding(8)
//                    .background(.ultraThinMaterial)
//                    .cornerRadius(10)
//
//                Text("XP: \(userXP)")
//                    .font(.headline)
//                    .padding(8)
//                    .background(.ultraThinMaterial)
//                    .cornerRadius(10)
//            }
//            .padding()
//        }
//    }
//}
//
//// MARK: - Map View
//struct CombinedMap: UIViewRepresentable {
//    var showPolygons: Bool
//    var userLocation: CLLocation?
//    @Binding var userXP: Int
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.showsUserLocation = true
//        context.coordinator.mapView = mapView
//
//        // Start XP timer
//        context.coordinator.startXPTimer(userXP: $userXP)
//
//        return mapView
//    }
//
//    func updateUIView(_ uiView: MKMapView, context: Context) {
//        context.coordinator.updatePolygons(on: uiView, show: showPolygons)
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    // MARK: - Coordinator
//    class Coordinator: NSObject, MKMapViewDelegate {
//        var mapView: MKMapView?
//        private var loadedPolygons: [MKPolygon] = []
//        private var zones: [Zone] = []
//        private var mobs: [Mob] = []
//        private var recenterTimer: Timer?
//        private var xpTimer: Timer?
//        private var userXP: Binding<Int>?
//
//        // MARK: - Polygons and Mobs
//        func updatePolygons(on mapView: MKMapView, show: Bool) {
//            self.mapView = mapView
//
//            if show && loadedPolygons.isEmpty {
//                loadGeoJSON(on: mapView)
//            } else if !show {
//                mapView.removeOverlays(loadedPolygons)
//                loadedPolygons.removeAll()
//                zones.removeAll()
//                removeAllMobs()
//            }
//        }
//
//        private func loadGeoJSON(on mapView: MKMapView) {
//            guard let url = Bundle.main.url(forResource: "pollution", withExtension: "geojson"),
//                  let data = try? Data(contentsOf: url) else {
//                print("❌ GeoJSON not found")
//                return
//            }
//
//            do {
//                let features = try MKGeoJSONDecoder().decode(data)
//                for feature in features {
//                    guard let feature = feature as? MKGeoJSONFeature else { continue }
//                    for geometry in feature.geometry {
//                        if let multiPolygon = geometry as? MKMultiPolygon {
//                            for polygon in multiPolygon.polygons {
//                                addPolygon(polygon, to: mapView)
//                            }
//                        } else if let polygon = geometry as? MKPolygon {
//                            addPolygon(polygon, to: mapView)
//                        }
//                    }
//                }
//                print("✅ Loaded \(loadedPolygons.count) polygons")
//            } catch {
//                print("❌ Error decoding GeoJSON: \(error)")
//            }
//        }
//
//        private func addPolygon(_ polygon: MKPolygon, to mapView: MKMapView) {
//            loadedPolygons.append(polygon)
//            zones.append(Zone(polygon: polygon, isGreenZone: true)) // all zones green for XP
//            mapView.addOverlay(polygon)
//            spawnMob(in: polygon)
//            spawnMob(in: polygon)
//            spawnMob(in: polygon)
//            spawnMob(in: polygon)
//            spawnMob(in: polygon)
//        }
//
//        private func spawnMob(in polygon: MKPolygon) {
//            guard let mapView = mapView else { return }
//            let coord = randomCoordinate(in: polygon, mapView: mapView)
//            let mob = Mob(coordinate: coord, name: "Goblin")
//            mobs.append(mob)
//
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = coord
//            annotation.title = mob.name
//            mapView.addAnnotation(annotation)
//        }
//
//        private func removeAllMobs() {
//            guard let mapView = mapView else { return }
//            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
//            mobs.removeAll()
//        }
//
//        private func randomCoordinate(in polygon: MKPolygon, mapView: MKMapView) -> CLLocationCoordinate2D {
//            let boundingRect = polygon.boundingMapRect
//            while true {
//                let x = Double.random(in: boundingRect.minX...boundingRect.maxX)
//                let y = Double.random(in: boundingRect.minY...boundingRect.maxY)
//                let point = MKMapPoint(x: x, y: y)
//                let coord = point.coordinate
//                if polygon.contains(coord) { return coord }
//            }
//        }
//
//        // Polygon containment
//        private func polygonRenderer(for polygon: MKPolygon) -> MKPolygonRenderer {
//            MKPolygonRenderer(polygon: polygon)
//        }
//
//        // MARK: - XP Timer
//        func startXPTimer(userXP: Binding<Int>) {
//            self.userXP = userXP
//            xpTimer?.invalidate()
//            xpTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
//                self?.checkUserInGreenZone()
//            }
//        }
//
//        private func checkUserInGreenZone() {
//            guard let mapView = mapView,
//                  let userLocation = mapView.userLocation.location,
//                  let xp = userXP else { return }
//
//            for zone in zones where zone.isGreenZone {
//                if zone.polygon.contains(userLocation.coordinate) {
//                    xp.wrappedValue += 1
//                    print("✅ +1 XP! Total: \(xp.wrappedValue)")
//                    break
//                }
//            }
//        }
//
//        // MARK: - Map Delegate
//        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer() }
//            let renderer = MKPolygonRenderer(polygon: polygon)
//            renderer.fillColor = UIColor.purple.withAlphaComponent(0.3)
//            renderer.strokeColor = UIColor.purple
//            renderer.lineWidth = 2
//            return renderer
//        }
//
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            guard !(annotation is MKUserLocation) else { return nil }
//            let identifier = "Mob"
//            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
//            if view == nil {
//                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                view?.markerTintColor = .red
//                view?.glyphText = "👾"
//            } else {
//                view?.annotation = annotation
//            }
//            return view
//        }
//
//        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            guard let title = view.annotation?.title ?? "", let index = mobs.firstIndex(where: { $0.name == title }) else { return }
//            mobs[index].isDefeated = true
//            mapView.removeAnnotation(view.annotation!)
//            print("⚔️ \(title) defeated!")
//        }
//    }
//}
//
//// MARK: - Polygon containment extension
//extension MKPolygon {
//    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
//        let renderer = MKPolygonRenderer(polygon: self)
//        let mapPoint = MKMapPoint(coordinate)
//        let point = renderer.point(for: mapPoint)
//        return renderer.path?.contains(point) ?? false
//    }
//}
//
//// MARK: - Location Manager
//
//import Foundation
//import CoreLocation
//import Combine
//@MainActor
//final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private let manager = CLLocationManager()
//    @Published var userLocation: CLLocation?
//
//    override init() {
//        super.init()
//        manager.delegate = self
//        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.distanceFilter = kCLDistanceFilterNone
//    }
//
//    func requestPermission() {
//        manager.requestWhenInUseAuthorization()
//    }
//
//    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        let status = manager.authorizationStatus
//        Task { @MainActor in
//            if status == .authorizedWhenInUse || status == .authorizedAlways {
//                manager.startUpdatingLocation()
//            } else {
//                manager.stopUpdatingLocation()
//            }
//        }
//    }
//
//    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let latest = locations.last else { return }
//        Task { @MainActor in
//            self.userLocation = latest
//        }
//    }
//}
