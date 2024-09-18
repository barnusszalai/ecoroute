import Foundation
import Combine

class TransportAPIService: ObservableObject {
    @Published var stops: [TransportStop] = []

    // Fetch stops near a given latitude and longitude
    func fetchStops(latitude: Double, longitude: Double) {
        let urlString = "https://transport.opendata.ch/v1/locations?x=\(latitude)&y=\(longitude)&type=station"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for fetching stops")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                print("Error fetching stops: \(String(describing: error))")
                return
            }

            do {
                let stopsResponse = try JSONDecoder().decode(StopsResponse.self, from: data)
                DispatchQueue.main.async {
                    // Filter out stops without valid coordinates
                    let validStops = stopsResponse.stations.filter { $0.coordinate.x != nil && $0.coordinate.y != nil }
                    self.stops = validStops
                }
            } catch {
                print("Error decoding stops: \(error)")
            }
        }
        task.resume()
    }
}
