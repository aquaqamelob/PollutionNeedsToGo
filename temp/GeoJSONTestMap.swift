////
////  GeoJSONTestMap.swift
////  temp
////
////  Created by Norbert on 08/11/2025.
////
//
//
////
////  GeoJSONTestMap.swift
////  fifth
////
////  Created by Norbert on 07/11/2025.
////
//
//
//import SwiftUI
//import MapKit
//
//struct GeoJSONTestMap: UIViewRepresentable {
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.isPitchEnabled = false
//        mapView.showsUserLocation = false
//        
//        // Center map roughly on San Francisco
//        let region = MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//        )
//        mapView.setRegion(region, animated: false)
//
//        // Load GeoJSON
//        guard let url = Bundle.main.url(forResource: "pollution", withExtension: "geojson"),
//              let data = try? Data(contentsOf: url) else {
//            print("❌ GeoJSON not found in bundle")
//            return mapView
//        }
//
//        do {
//            let features = try MKGeoJSONDecoder().decode(data)
//            print("✅ Loaded \(features.count) GeoJSON features")
//
//            for feature in features {
//                guard let feature = feature as? MKGeoJSONFeature else { continue }
//
//                for geometry in feature.geometry {
//                    if let multiPolygon = geometry as? MKMultiPolygon {
//                        for polygon in multiPolygon.polygons {
//                            mapView.addOverlay(polygon)
//                        }
//                    } else if let polygon = geometry as? MKPolygon {
//                        mapView.addOverlay(polygon)
//                    }
//                }
//            }
//
//        } catch {
//            print("❌ Error decoding GeoJSON: \(error)")
//        }
//
//        return mapView
//    }
//
//    func updateUIView(_ uiView: MKMapView, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject, MKMapViewDelegate {
//        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer() }
//            let renderer = MKPolygonRenderer(polygon: polygon)
//            renderer.fillColor = UIColor.red.withAlphaComponent(0.2)
//            renderer.strokeColor = UIColor.red
//            renderer.lineWidth = 1
//            return renderer
//        }
//    }
//}
//
//#Preview {
//    GeoJSONTestMap()
//}
