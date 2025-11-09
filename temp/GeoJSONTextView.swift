//
//  GeoJSONTextView.swift
//  temp
//
//  Created by Norbert on 08/11/2025.
//


import SwiftUI
import MapKit

struct GeoJSONTextView: View {
    @State private var coordinatesText: String = "Loading..."

    var body: some View {
        ScrollView {
            Text(coordinatesText)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .onAppear(perform: loadGeoJSON)
        .navigationTitle("GeoJSON Coordinates")
    }

    private func loadGeoJSON() {
        guard let url = Bundle.main.url(forResource: "pollution", withExtension: "geojson") else {
            coordinatesText = "❌ Could not find pollution.geojson in bundle."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let features = try MKGeoJSONDecoder().decode(data)
            var output = "✅ Loaded \(features.count) features\n\n"

            for (i, feature) in features.enumerated() {
                guard let feature = feature as? MKGeoJSONFeature else { continue }
                output += "Feature \(i + 1):\n"

                for geometry in feature.geometry {
                    if let polygon = geometry as? MKPolygon {
                        let coords = polygon.coordinates
                        output += coords.map {
                            "(\($0.latitude), \($0.longitude))"
                        }.joined(separator: "\n")
                        output += "\n\n"
                    } else if let multiPolygon = geometry as? MKMultiPolygon {
                        for poly in multiPolygon.polygons {
                            let coords = poly.coordinates
                            output += coords.map {
                                "(\($0.latitude), \($0.longitude))"
                            }.joined(separator: "\n")
                            output += "\n\n"
                        }
                    } else {
                        output += "⚠️ Unknown geometry type\n\n"
                    }
                }
            }

            coordinatesText = output
        } catch {
            coordinatesText = "❌ Error decoding GeoJSON:\n\(error.localizedDescription)"
        }
    }
}



#Preview {
    GeoJSONTextView()
}

extension MKPolygon {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }

        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.3,
                                    longitudeDelta: (maxLon - minLon) * 1.3)
        self.init(center: center, span: span)
    }
}
