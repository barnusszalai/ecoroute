import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var transportService = TransportAPIService()
    @StateObject private var bikeService = BikeAPIService() // Add the BikeAPIService
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.5247, longitude: 6.5690),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var stops: [TransportStop] = []
    @State private var bikeStops: [BikeStop] = [] // Add bike stops state
    @State private var forceUpdate = false
    @State private var shouldRecenterToUser = false
    @State private var hasManuallyRecentered = false

    var body: some View {
        ZStack {
            MapView(region: $region, stops: $stops, bikeStops: $bikeStops, forceUpdate: $forceUpdate, showsUserLocation: true, onRegionChange: { newRegion in
                DispatchQueue.main.async {
                    region = newRegion // Update the region based on user movement
                    hasManuallyRecentered = true
                }
            }) { centerCoordinate, radius in
                if radius <= 1000 {
                    transportService.fetchStops(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
                }
            }
            .onChange(of: transportService.stops) { newStops in
                stops = newStops
            }
            .onAppear {
                locationManager.requestLocationUpdate()
                bikeService.fetchBikeStations() // Fetch bike stations on load
            }
            .onChange(of: bikeService.bikeStops) { newBikeStops in
                bikeStops = newBikeStops
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let userLocation = locationManager.userLocation {
                            region = MKCoordinateRegion(
                                center: userLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                            forceUpdate.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                forceUpdate.toggle()
                            }
                            shouldRecenterToUser = true
                            hasManuallyRecentered = true
                        } else {
                            locationManager.requestLocationUpdate()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onReceive(locationManager.$userLocation) { newLocation in
            if let userLocation = newLocation, shouldRecenterToUser {
                region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                forceUpdate.toggle()
                shouldRecenterToUser = false
            }
        }
    }
}
