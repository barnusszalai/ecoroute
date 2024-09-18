
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var stops: [TransportStop]
    @Binding var bikeStops: [BikeStop]
    @Binding var forceUpdate: Bool
    var showsUserLocation: Bool
    var onRegionChange: (MKCoordinateRegion) -> Void
    var onStopsRequest: (CLLocationCoordinate2D, Double) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.mapType = .mutedStandard
        mapView.setRegion(region, animated: true)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if forceUpdate {
            uiView.setRegion(region, animated: true)
        }

        uiView.removeAnnotations(uiView.annotations)

        // Add Transport Stops
        let transportAnnotations = stops.compactMap { stop -> MKPointAnnotation? in
            if let latitude = stop.coordinate.x, let longitude = stop.coordinate.y {
                let annotation = MKPointAnnotation()
                annotation.title = stop.name
                annotation.subtitle = stop.icon?.lowercased() ?? "unknown"
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                return annotation
            }
            return nil
        }
        uiView.addAnnotations(transportAnnotations)
        
        // Add Bike Stops
        let bikeAnnotations = bikeStops.map { stop -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = stop.name
            annotation.subtitle = "bike"
            annotation.coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
            return annotation
        }
        uiView.addAnnotations(bikeAnnotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onRegionChange: onRegionChange, onStopsRequest: onStopsRequest)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onRegionChange: (MKCoordinateRegion) -> Void
        var onStopsRequest: (CLLocationCoordinate2D, Double) -> Void

        init(_ parent: MapView, onRegionChange: @escaping (MKCoordinateRegion) -> Void, onStopsRequest: @escaping (CLLocationCoordinate2D, Double) -> Void) {
            self.parent = parent
            self.onRegionChange = onRegionChange
            self.onStopsRequest = onStopsRequest
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let center = mapView.centerCoordinate
            let radius = getRadius(of: mapView)

            if radius <= 1000 {
                onStopsRequest(center, radius)
            }
            onRegionChange(mapView.region)
        }

        func getRadius(of mapView: MKMapView) -> Double {
            let centerLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            let topCenterCoordinate = mapView.convert(CGPoint(x: mapView.frame.size.width / 2.0, y: 0), toCoordinateFrom: mapView)
            let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
            return centerLocation.distance(from: topCenterLocation)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKPointAnnotation {
                let identifier = "StopAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.frame = CGRect(x: 0, y: 0, width: 34, height: 34) // Larger circle size
                    annotationView?.layer.cornerRadius = 17 // Half the width to make it circular
                } else {
                    annotationView?.annotation = annotation // Ensure the annotation is updated
                }

                // Set the white background with 0.8 opacity
                annotationView?.backgroundColor = UIColor(white: 1.0, alpha: 0.9)

                // Set the border color based on the type of stop (no icons)
                if let subtitle = annotation.subtitle {
                    switch subtitle?.lowercased() {
                    case "bus":
                        annotationView?.layer.borderColor = UIColor.blue.cgColor
                    case "tram":
                        annotationView?.layer.borderColor = UIColor.green.cgColor
                    case "train":
                        annotationView?.layer.borderColor = UIColor.red.cgColor
                    case "bike":
                        annotationView?.layer.borderColor = UIColor.orange.cgColor
                    default:
                        annotationView?.layer.borderColor = UIColor.gray.cgColor
                    }
                }

                annotationView?.layer.borderWidth = 3 // Set the border thickness for a clear circle outline

                return annotationView
            }
            return nil
        }

        func createFixedIconImage(systemName: String) -> UIImage? {
            // Create a fixed icon size to maintain consistency
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium) // Adjust icon size if needed
            let image = UIImage(systemName: systemName, withConfiguration: config)?
                .withTintColor(.gray, renderingMode: .alwaysOriginal) // Set a fixed icon color (gray)
            return image
        }
    }
}
