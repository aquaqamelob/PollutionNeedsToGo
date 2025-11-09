////
////  Mob 2.swift
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
//    @State private var showFightSheet = false
//    @State private var showTooFarAlert = false
//    @State private var selectedMob: Mob?
//
//    var body: some View {
//        ZStack(alignment: .topTrailing) {
//            CombinedMap(showPolygons: showPolygons,
//                        userLocation: locationManager.userLocation)
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
//                
//            }
//            .padding()
//        }
//        .alert("Too far!", isPresented: $showTooFarAlert) {
//                    Button("OK", role: .cancel) { }
//                } message: {
//                    Text("You need to get closer to the monster to start fighting.")
//                }
//                .sheet(isPresented: $showFightSheet) {
//                    if let mob = selectedMob {
//                        FightSheet(mob: mob)
//                    }
//                }
//    }
//}
//
//// MARK: - Map View Representable
//struct CombinedMap: UIViewRepresentable {
//    var showPolygons: Bool
//    var userLocation: CLLocation?
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.showsUserLocation = true
//        context.coordinator.mapView = mapView
//
//        // Start automatic fight proximity checking
//   
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
//        private var recenterTimer: Timer?
//        private var loadedPolygons: [MKPolygon] = []
//        private var mobs: [Mob] = []
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
//            
//            for _ in 1...5 {
//                spawnMob(in: polygon)
//            }
//        }
//
//        private func spawnMob(in polygon: MKPolygon) {
//            guard let mapView = mapView else { return }
//            let coord = randomCoordinate(in: polygon)
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
//                view?.markerTintColor = .red
//                view?.glyphText = "👾"
//            } else {
//                view?.annotation = annotation
//            }
//            return view
//        }
//        
//        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
//                    // User interacted, cancel auto-recenter
//                    recenterTimer?.invalidate()
//                }
//        
//                func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//                    // Restart timer after 5 seconds of inactivity
//                    recenterTimer?.invalidate()
//                    recenterTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self, weak mapView] _ in
//                        guard let self = self, let mapView = mapView else { return }
//                        self.recenterOnUser(in: mapView)
//                    }
//                }
//        
//        
//        private func recenterOnUser(in mapView: MKMapView) {
//                    guard let userLocation = mapView.userLocation.location else { return }
//        
//                    let newRegion = MKCoordinateRegion(
//                        center: userLocation.coordinate,
//                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//                    )
//        
//                    DispatchQueue.main.async {
//                        mapView.setRegion(newRegion, animated: true)
//                    }
//                }
//
//        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            fightMob(annotationView: view)
//        }
//        
//        
//
//        // MARK: - Fight logic
//        private func fightMob(annotationView view: MKAnnotationView) {
//            guard let annotation = view.annotation,
//                  !(annotation is MKUserLocation),
//                  let userLocation = mapView?.userLocation.location,
//                  let mobIndex = mobs.firstIndex(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude })
//            else { return }
//
//            let mob = mobs[mobIndex]
//            let mobLocation = CLLocation(latitude: mob.coordinate.latitude, longitude: mob.coordinate.longitude)
//            let distance = userLocation.distance(from: mobLocation)
//
//            if distance <= 20 { // 2 meters range
//                mobs[mobIndex].isDefeated = true
//                mapView?.removeAnnotation(annotation)
//                print("⚔️ You fought and defeated \(mob.name)!")
//            } else {
//                print("❌ Too far to fight \(mob.name). Get closer! \(distance)")
//            }
//        }
//
//       
//       
//    }
//}
//
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
//            VStack {
//                Text("Your HP: \(playerHP)")
//                Text("\(mob.name)'s HP: \(mobHP)")
//            }
//            .font(.headline)
//            .padding()
//            
//            Spacer()
//            
//            Button("Attack!") {
//                let playerHit = Int.random(in: 10...30)
//                let mobHit = Int.random(in: 5...25)
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
//            .background(.blue)
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
//// MARK: - Polygon containment
//extension MKPolygon {
//    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
//        let renderer = MKPolygonRenderer(polygon: self)
//        let mapPoint = MKMapPoint(coordinate)
//        let point = renderer.point(for: mapPoint)
//        return renderer.path?.contains(point) ?? false
//    }
//}
//
//import Foundation
//import CoreLocation
//import Combine
//// MARK: - Location Manager
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
