import SwiftUI
import MapKit
import ClusterMap

@available(iOS 17, *)
extension MapProxy {
    @MainActor
    public func mapScale(
        coordinateRegion: MKCoordinateRegion,
        coordinateSpace: CoordinateSpaceProtocol
    ) -> MapScale? {
        let left = CLLocationCoordinate2D(
            latitude: coordinateRegion.center.latitude,
            longitude: coordinateRegion.center.longitude - (coordinateRegion.span.longitudeDelta / 2)
        )
        let right = CLLocationCoordinate2D(
            latitude: coordinateRegion.center.latitude,
            longitude: coordinateRegion.center.longitude + (coordinateRegion.span.longitudeDelta / 2)
        )
        
        guard let leftPoint = convert(left, to: coordinateSpace) else {
            return nil
        }
        guard let rightPoint = convert(right, to: coordinateSpace) else {
            return nil
        }
        return MapScale(
            mapViewWidthInPoints: abs(leftPoint.x - rightPoint.x),
            coordinateRegion: coordinateRegion
        )
    }
}
