import CoreLocation

public enum ClusterOrAnnotation<Annotation: CoordinateIdentifiable & Equatable & Sendable>: Equatable, Sendable {
    public struct Cluster: CoordinateIdentifiable, Equatable, Sendable {
        public var coordinate: CLLocationCoordinate2D
        public let annotations: [Annotation]
    }
    
    case cluster(Cluster)
    case annotation(Annotation)
}

// MARK: Identifiable
extension ClusterOrAnnotation: Identifiable where Annotation: Identifiable {
    public enum ID: Hashable {
        case annotation(Annotation.ID)
        case cluster([Annotation.ID])
    }
    
    public var id: ID {
        switch self {
        case .cluster(let cluster):
            return .cluster(cluster.annotations.map(\.id))
        case .annotation(let annotation):
            return .annotation(annotation.id)
        }
    }
}
