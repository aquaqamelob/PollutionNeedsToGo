////
////  UserMapWithPolygons.swift
////  temp
////
////  Created by Norbert on 08/11/2025.
////
//
//
////
////  UserMapWithPolygons.swift
////  fifth
////
////  Created by Norbert on 08/11/2025.
////
//
//import SwiftUI
//import MapKit
//import CoreLocation
//
//struct UserMapWithPolygons: View {
//    @StateObject private var locationManager = LocationManager()
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    )
//    @State private var showPolygons = false
//    
//    var body: some View {
//        ZStack(alignment: .topTrailing) {
//            CombinedMap(region: $region, showPolygons: showPolygons)
//                .edgesIgnoringSafeArea(.all)
//                .onAppear {
//                    locationManager.requestPermission()
//                }
//                .onChange(of: locationManager.userLocation) { newLocation in
//                    guard let newLocation = newLocation else { return }
//                    withAnimation(.easeInOut(duration: 0.5)) {
//                        region.center = newLocation.coordinate
//                    }
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
//                    .toggleStyle(SwitchToggleStyle(tint: .red))
//                    .padding(8)
//                    .background(.ultraThinMaterial)
//                    .cornerRadius(10)
//            }
//            .padding()
//        }
//    }
//}
//
//#Preview {
//    UserMapWithPolygons()
//}
//
//struct CombinedMap: UIViewRepresentable {
//    @Binding var region: MKCoordinateRegion
//    var showPolygons: Bool
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.showsUserLocation = true
//        mapView.setRegion(region, animated: false)
//        return mapView
//    }
//
//    func updateUIView(_ uiView: MKMapView, context: Context) {
//        uiView.setRegion(region, animated: true)
//        context.coordinator.updatePolygons(on: uiView, show: showPolygons)
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
////    class Coordinator: NSObject, MKMapViewDelegate {
////        private var loadedPolygons: [MKPolygon] = []
////
////        func updatePolygons(on mapView: MKMapView, show: Bool) {
////            if show && loadedPolygons.isEmpty {
////                loadGeoJSON(on: mapView)
////            } else if !show {
////                mapView.removeOverlays(loadedPolygons)
////                loadedPolygons.removeAll()
////            }
////        }
////
////        private func loadGeoJSON(on mapView: MKMapView) {
////            guard let url = Bundle.main.url(forResource: "pollution", withExtension: "geojson"),
////                  let data = try? Data(contentsOf: url) else {
////                print("❌ GeoJSON not found")
////                return
////            }
////
////            do {
////                let features = try MKGeoJSONDecoder().decode(data)
////                for feature in features {
////                    guard let feature = feature as? MKGeoJSONFeature else { continue }
////                    for geometry in feature.geometry {
////                        if let multiPolygon = geometry as? MKMultiPolygon {
////                            for polygon in multiPolygon.polygons {
////                                mapView.addOverlay(polygon)
////                                loadedPolygons.append(polygon)
////                            }
////                        } else if let polygon = geometry as? MKPolygon {
////                            mapView.addOverlay(polygon)
////                            loadedPolygons.append(polygon)
////                        }
////                    }
////                }
////                print("✅ Loaded \(loadedPolygons.count) polygons")
////            } catch {
////                print("❌ Error decoding GeoJSON: \(error)")
////            }
////        }
////
////        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
////            guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer() }
////            let renderer = MKPolygonRenderer(polygon: polygon)
////            renderer.fillColor = UIColor.purple.withAlphaComponent(0.3)
////            renderer.strokeColor = UIColor.purple
////            renderer.lineWidth = 1
////            return renderer
////        }
////    }
//    class Coordinator: NSObject, MKMapViewDelegate {
//        private var loadedPolygons: [MKPolygon] = []
//        private var recenterTimer: Timer?
//        private weak var mapView: MKMapView?
//
//        func updatePolygons(on mapView: MKMapView, show: Bool) {
//            self.mapView = mapView
//            if show && loadedPolygons.isEmpty {
//                loadGeoJSON(on: mapView)
//            } else if !show {
//                mapView.removeOverlays(loadedPolygons)
//                loadedPolygons.removeAll()
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
//                                mapView.addOverlay(polygon)
//                                loadedPolygons.append(polygon)
//                            }
//                        } else if let polygon = geometry as? MKPolygon {
//                            mapView.addOverlay(polygon)
//                            loadedPolygons.append(polygon)
//                        }
//                    }
//                }
//                print("✅ Loaded \(loadedPolygons.count) polygons")
//            } catch {
//                print("❌ Error decoding GeoJSON: \(error)")
//            }
//        }
//
//        // MARK: - 🗺️ Interaction Tracking
//
//        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
//            // User started interacting — cancel any auto-center timer
//            recenterTimer?.invalidate()
//        }
//
//        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//            // Restart the inactivity timer
//            recenterTimer?.invalidate()
//            recenterTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self, weak mapView] _ in
//                guard let self = self, let mapView = mapView else { return }
//                self.recenterOnUser(in: mapView)
//            }
//        }
//
//        private func recenterOnUser(in mapView: MKMapView) {
//            guard let userLocation = mapView.userLocation.location else { return }
//
//            let newRegion = MKCoordinateRegion(
//                center: userLocation.coordinate,
//                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // tighter zoom
//            )
//
//            DispatchQueue.main.async {
//                mapView.setRegion(newRegion, animated: true)
//            }
//        }
//
//        // MARK: - Polygon Rendering
//        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer() }
//            let renderer = MKPolygonRenderer(polygon: polygon)
//            renderer.fillColor = UIColor.purple.withAlphaComponent(0.3)
//            renderer.strokeColor = UIColor.purple
//            renderer.lineWidth = 1
//            return renderer
//        }
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
//    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
//
//    override init() {
//        super.init()
//        manager.delegate = self
//        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.distanceFilter = kCLDistanceFilterNone
//    }
//
//    func requestPermission() {
//        // ✅ No need to check `locationServicesEnabled()` on main thread.
//        manager.requestWhenInUseAuthorization()
//    }
//
//    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        let status = manager.authorizationStatus
//        
//        Task { @MainActor in
//            self.authorizationStatus = status
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
