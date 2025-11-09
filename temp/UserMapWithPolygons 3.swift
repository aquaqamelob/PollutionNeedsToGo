////
////  UserMapWithPolygons 3.swift
////  temp
////
////  Created by Norbert on 09/11/2025.
////
//
//
////
////  Mob 5.swift
////  temp
////
////  Edited by GitHub Copilot on 2025-11-09.
////  Converted to "green zones" + EXP gain logic
////
//
//import SwiftUI
//import MapKit
//import CoreLocation
//import Foundation
//import Combine
//
//// MARK: - Main Map View
//struct UserMapWithPolygons: View {
//    @StateObject private var locationManager = LocationManager()
//    @State private var showPolygons = true
//
//    // EXP state (imaginary, not persisted)
//    @State private var exp: Int = 0
//    // Trigger for a short-lived visual animation when exp is gained
//    @State private var showExpGain: Bool = false
//
//    var body: some View {
//        ZStack(alignment: .topTrailing) {
//            CombinedMap(
//                showPolygons: showPolygons,
//                userLocation: locationManager.userLocation,
//                exp: $exp,
//                showExpGain: $showExpGain
//            )
//            .edgesIgnoringSafeArea(.all)
//            .onAppear {
//                locationManager.requestPermission()
//            }
//
//            VStack(alignment: .trailing, spacing: 8) {
//                VStack {
//                    Text("Your Location 📍")
//                        .font(.headline)
//                    Text("EXP: \(exp)")
//                        .font(.subheadline).bold()
//                }
//                .padding(8)
//                .background(.ultraThinMaterial)
//                .cornerRadius(10)
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
//        // small floating EXP gain animation
//        .overlay(alignment: .center) {
//            if showExpGain {
//                Text("+5 EXP")
//                    .font(.title)
//                    .bold()
//                    .padding()
//                    .background(.thinMaterial)
//                    .cornerRadius(12)
//                    .scaleEffect(showExpGain ? 1.0 : 0.6)
//                    .transition(.scale.combined(with: .opacity))
//                    .onAppear {
//                        // auto-hide after short delay handled by coordinator
//                    }
//            }
//        }
//        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showExpGain)
//    }
//}
//
//// MARK: - Map View Representable
//struct CombinedMap: UIViewRepresentable {
//    var showPolygons: Bool
//    var userLocation: CLLocation?
//    @Binding var exp: Int
//    @Binding var showExpGain: Bool
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
//        context.coordinator.userLocationDidUpdate(userLocation)
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//
//    // MARK: - Coordinator
//    class Coordinator: NSObject, MKMapViewDelegate {
//        weak var mapView: MKMapView?
//        var parent: CombinedMap
//        private var loadedPolygons: [MKPolygon] = []
//
//        // Timers for occupancy checking + EXP awarding
//        private var occupancyTimer: Timer?
//        private var expTimer: Timer?
//
//        // If true, user is currently inside at least one polygon
//        private var isInsidePolygon: Bool = false
//
//        // EXP awarding configuration
//        private let awardInterval: TimeInterval = 5.0
//        private let awardAmount: Int = 5
//
//        init(parent: CombinedMap) {
//            self.parent = parent
//            super.init()
//        }
//
//        deinit {
//            stopOccupancyTimer()
//            stopExpTimer()
//        }
//
//        // MARK: - Load polygons
//        func updatePolygons(on mapView: MKMapView, show: Bool) {
//            self.mapView = mapView
//            if show && loadedPolygons.isEmpty {
//                loadPolygons(on: mapView)
//                startOccupancyTimerIfNeeded()
//            } else if !show {
//                mapView.removeOverlays(loadedPolygons)
//                loadedPolygons.removeAll()
//                stopOccupancyTimer()
//                stopExpTimer()
//                isInsidePolygon = false
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
//        }
//
//        // MARK: - Occupancy Timer (checks whether user inside any polygon)
//        private func startOccupancyTimerIfNeeded() {
//            guard occupancyTimer == nil else { return }
//            occupancyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//                DispatchQueue.main.async {
//                    guard let self = self else { return }
//                    self.checkUserOccupancy()
//                }
//            }
//            RunLoop.main.add(occupancyTimer!, forMode: .common)
//        }
//
//        private func stopOccupancyTimer() {
//            occupancyTimer?.invalidate()
//            occupancyTimer = nil
//        }
//
//        private func startExpTimer() {
//            stopExpTimer()
//            expTimer = Timer.scheduledTimer(withTimeInterval: awardInterval, repeats: true) { [weak self] _ in
//                DispatchQueue.main.async {
//                    guard let self = self else { return }
//                    // Award EXP
//                    self.parent.$exp.wrappedValue += self.awardAmount
//                    // Trigger short animation
//                    self.parent.$showExpGain.wrappedValue = true
//                    // Hide after a short delay so the animation can run
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
//                        self.parent.$showExpGain.wrappedValue = false
//                    }
//                }
//            }
//            RunLoop.main.add(expTimer!, forMode: .common)
//        }
//
//        private func stopExpTimer() {
//            expTimer?.invalidate()
//            expTimer = nil
//        }
//
//        // Called whenever user location is updated from SwiftUI view
//        func userLocationDidUpdate(_ location: CLLocation?) {
//            // immediate check for responsiveness when location changes
//            checkUserOccupancy()
//        }
//
//        private func checkUserOccupancy() {
//            guard let loc = mapView?.userLocation.location ?? parent.userLocation else {
//                setInside(false)
//                return
//            }
//
//            let coord = loc.coordinate
//            var inside = false
//            for polygon in loadedPolygons {
//                if polygon.contains(coord) {
//                    inside = true
//                    break
//                }
//            }
//            setInside(inside)
//        }
//
//        private func setInside(_ inside: Bool) {
//            if inside && !isInsidePolygon {
//                // Entered polygon
//                isInsidePolygon = true
//                startExpTimer()
//                startOccupancyTimerIfNeeded() // ensure running
//                print("➡️ Entered green zone - EXP will be awarded every \(awardInterval)s")
//            } else if !inside && isInsidePolygon {
//                // Left polygon
//                isInsidePolygon = false
//                stopExpTimer()
//                print("⬅️ Left green zone - EXP awarding stopped")
//            }
//        }
//
//        // MARK: - Map Delegate
//        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer() }
//            let renderer = MKPolygonRenderer(polygon: polygon)
//            renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
//            renderer.strokeColor = UIColor.systemGreen
//            renderer.lineWidth = 2
//            return renderer
//        }
//    }
//}
//
//// MARK: - Polygon point-in-polygon extension (works in map coordinate space)
//extension MKPolygon {
//    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
//        let mapPoint = MKMapPoint(coordinate)
//        let pts = self.points()
//        let count = self.pointCount
//        guard count > 0 else { return false }
//
//        var inside = false
//        var j = count - 1
//        for i in 0..<count {
//            let xi = pts[i].x
//            let yi = pts[i].y
//            let xj = pts[j].x
//            let yj = pts[j].y
//
//            // Ray-casting algorithm for point-in-polygon
//            if ((yi > mapPoint.y) != (yj > mapPoint.y)) {
//                let intersectX = (xj - xi) * (mapPoint.y - yi) / (yj - yi) + xi
//                if mapPoint.x < intersectX {
//                    inside.toggle()
//                }
//            }
//            j = i
//        }
//        return inside
//    }
//}
//
//// MARK: - Location Manager (unchanged)
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
//
//// MARK: - Preview
//#Preview {
//    UserMapWithPolygons()
//}
