import Foundation

struct TransportStop: Codable, Equatable {
    let id: String?
    let name: String
    let coordinate: Coordinate
    let icon: String? // Add this field to represent the stop type, such as 'bus', 'train', etc.

    static func == (lhs: TransportStop, rhs: TransportStop) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.coordinate == lhs.coordinate
    }
}

struct Coordinate: Codable, Equatable {
    let x: Double?
    let y: Double?
}

