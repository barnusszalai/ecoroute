import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    // Default region centered around EPFL in Lausanne
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.5191, longitude: 6.5668), // Lausanne coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        VStack {
            if let userLocation = locationManager.userLocation {
                MapView(region: $region, showsUserLocation: true)
                    .onAppear {
                        // Update region to focus on user's location
                        region = MKCoordinateRegion(
                            center: userLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    }
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Fetching your location...")
            }
        }
        .onAppear {
            // Request location permission on view appear
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
