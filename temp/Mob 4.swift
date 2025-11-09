////
////  Mob 4.swift
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
//// MARK: - Mob Model
//struct Mob: Identifiable {
//    let id = UUID()
//    let coordinate: CLLocationCoordinate2D
//    let name: String
//    var isDefeated: Bool = false
//}
//
//// MARK: - Main Map View
//struct UserMapWithPolygons: View {
//    @StateObject private var locationManager = LocationManager()
//    @State private var showPolygons = true
//    @State private var showTooFarAlert = false
//    @State private var selectedMob: Mob?    // ✅ Using this as sheet trigger
//
//    var body: some View {
//        ZStack(alignment: .topTrailing) {
//            CombinedMap(
//                showPolygons: showPolygons,
//                userLocation: locationManager.userLocation,
//                showTooFarAlert: $showTooFarAlert,
//                selectedMob: $selectedMob
//            )
//            .edgesIgnoringSafeArea(.all)
//            .onAppear {
//                locationManager.requestPermission()
//            }
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
//            }
//            .padding()
//        }
//        // MARK: - Alert + Sheet
//        .alert("Too far!", isPresented: $showTooFarAlert) {
//            Button("OK", role: .cancel) { }
//        } message: {
//            Text("You need to get closer to the monster to start fighting.")
//        }
//        .sheet(item: $selectedMob) { mob in
//            FightSheet(mob: mob)
//        }
//    }
//}
//
//// MARK: - Map View Representable
//struct CombinedMap: UIViewRepresentable {
//    var showPolygons: Bool
//    var userLocation: CLLocation?
//    @Binding var showTooFarAlert: Bool
//    @Binding var selectedMob: Mob?
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.showsUserLocation = true
//        context.coordinator.mapView = mapView
//        return mapView
//    }
//
//    func updateUIView(_ uiView: MKMapView, context: Context) {
//        context.coordinator.updatePolygons(on: uiView, show: showPolygons)
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//
//    // MARK: - Coordinator
//    class Coordinator: NSObject, MKMapViewDelegate {
//        var mapView: MKMapView?
//        var parent: CombinedMap
//        private var loadedPolygons: [MKPolygon] = []
//        private var mobs: [Mob] = []
//
//        init(parent: CombinedMap) {
//            self.parent = parent
//        }
//
//        // MARK: - Load polygons and spawn mobs
//        func updatePolygons(on mapView: MKMapView, show: Bool) {
//            self.mapView = mapView
//            if show && loadedPolygons.isEmpty {
//                loadPolygons(on: mapView)
//            } else if !show {
//                mapView.removeOverlays(loadedPolygons)
//                loadedPolygons.removeAll()
//                removeAllMobs()
//            }
//        }
//
//        private func loadPolygons(on mapView: MKMapView) {
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
//                            for polygon in multiPolygon.polygons { addPolygon(polygon, to: mapView) }
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
//            mapView.addOverlay(polygon)
//            for _ in 1...100 { spawnMob(in: polygon) }
//        }
//
//        private func spawnMob(in polygon: MKPolygon) {
//            guard let mapView = mapView else { return }
//            let coord = randomCoordinate(in: polygon)
//            let mob = Mob(coordinate: coord, name: ["Goblin", "Slime", "Orc"].randomElement()!)
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
//        private func randomCoordinate(in polygon: MKPolygon) -> CLLocationCoordinate2D {
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
//                view?.markerTintColor = .systemRed
//                view?.glyphText = "👾"
//                view?.canShowCallout = true
//            } else {
//                view?.annotation = annotation
//            }
//            return view
//        }
//
//        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            fightMob(annotationView: view)
//        }
//
//        // MARK: - Fight logic
//        private func fightMob(annotationView view: MKAnnotationView) {
//            guard let annotation = view.annotation,
//                  !(annotation is MKUserLocation),
//                  let userLocation = mapView?.userLocation.location,
//                  let mob = mobs.first(where: {
//                      $0.coordinate.latitude == annotation.coordinate.latitude &&
//                      $0.coordinate.longitude == annotation.coordinate.longitude
//                  }) else { return }
//
//            let mobLocation = CLLocation(latitude: mob.coordinate.latitude, longitude: mob.coordinate.longitude)
//            let distance = userLocation.distance(from: mobLocation)
//
//            if distance <= 20 { // Within 20m
//                parent.selectedMob = mob   // ✅ sheet auto-triggers
//                mapView?.deselectAnnotation(annotation, animated: true)
//                print("⚔️ Engaging \(mob.name) in combat!")
//            } else {
//                parent.showTooFarAlert = true
//                print("❌ Too far to fight \(mob.name). \(Int(distance))m away.")
//            }
//        }
//    }
//}
//
//// MARK: - Polygon Extension
//extension MKPolygon {
//    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
//        let renderer = MKPolygonRenderer(polygon: self)
//        let mapPoint = MKMapPoint(coordinate)
//        let point = renderer.point(for: mapPoint)
//        return renderer.path?.contains(point) ?? false
//    }
//}
//
//// MARK: - Fight Sheet
//struct FightSheet: View {
//    let mob: Mob
//    @Environment(\.dismiss) var dismiss
//    @State private var mobHP = 100
//    @State private var playerHP = 100
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("⚔️ Battle vs \(mob.name)")
//                .font(.title)
//                .bold()
//                .padding(.top)
//
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
//            
//            
//
//            Button("Attack!") {
//                let playerHit = Int.random(in: 10...25)
//                let mobHit = Int.random(in: 5...20)
//
//                mobHP -= playerHit
//                playerHP -= mobHit
//
//                if mobHP <= 0 {
//                    print("✅ You defeated \(mob.name)!")
//                    dismiss()
//                } else if playerHP <= 0 {
//                    print("💀 You were defeated by \(mob.name).")
//                    dismiss()
//                }
//            }
//            .font(.title2)
//            .padding()
//            .frame(maxWidth: .infinity)
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(12)
//
//            Button("Run Away") {
//                dismiss()
//            }
//            .foregroundColor(.red)
//            .padding(.bottom, 40)
//        }
//        .padding()
//        .presentationDetents([.medium])
//    }
//}
//
//import Foundation
//import CoreLocation
//import Combine
//
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
