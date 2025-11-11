import Foundation
import MapKit

/// A struct to describe the ratio between the map view width in screen points
/// and the visible map width in MapKit map points (MKMapPoints).
///
/// Interpretation:
/// - rawValue = screenPointsPerMapPoint (px/mp)
///   Example: rawValue = 0.5 means 0.5 screen points represent 1 map point.
public struct MapScale: RawRepresentable, Sendable, Equatable, Hashable {
    public let rawValue: Double
    
    /// Returns true if the scale is a finite, non-NaN value.
    public var isValid: Bool {
        rawValue.isFinite && !rawValue.isNaN
    }
    
    public var zoomLevel: Int {
        let maxZoomLevel = log2(MKMapSize.world.width / 256)
        let zoomLevel = floor(log2(rawValue) + 0.5) // negative
        return Int(max(0, maxZoomLevel + zoomLevel)) // max - current
    }
    
    /// Creates a MapScale from a raw screenPointsPerMapPoint value.
    public init(rawValue: Double) {
        self.rawValue = rawValue
    }

    /// Creates a MapScale from the map view width and the
    /// visible map width.
    ///
    /// - Parameters:
    ///   - mapViewWidthInPoints: The width of the map view in screen points.
    ///   - visibleWidthInMapPoints: The width of the visible map.
    public init(
        mapViewWidthInPoints: Double,
        visibleWidthInMapPoints: Double
    ) {
        self.rawValue = mapViewWidthInPoints / visibleWidthInMapPoints
    }
    
    public init(
        mapViewWidthInPoints: CGFloat,
        coordinateRegion: MKCoordinateRegion
    ) {
        let mapRect = MKMapRect(region: coordinateRegion)
        self.init(
            mapViewWidthInPoints: mapViewWidthInPoints,
            visibleWidthInMapPoints: mapRect.width
        )
    }
}
