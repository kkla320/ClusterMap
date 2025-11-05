//
//  ClusterManager.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import CoreLocation
import MapKit

/// Manages the clustering behavior for map annotations.
///
/// The `ClusterManager` is responsible for optimizing the display of map annotations by grouping close annotations
/// into clusters.
///
/// Example:
///
/// ```swift
/// let manager = ClusterManager<MyAnnotation>()
///
/// // Adding an annotation
/// let annotation = MyAnnotation(coordinate: someCoordinate)
/// manager.add(annotation)
///
/// // Adding multiple annotations
/// manager.add([annotation1, annotation2, annotation3])
///
/// // Reloading the clustering for a map region
/// manager.reload(mapSize: someSize, coordinateRegion: someRegion) { difference in
///     // Handle the difference here
/// }
/// ```
public actor ClusterManager<Storage: NodeStorage> where Storage.Element: CoordinateIdentifiable & Hashable & Sendable {
    public typealias Annotation = Storage.Element
    
    private var tree: QuadTree<Storage>
    private let configuration: Configuration
    private var zoomLevel: Double = 0

    /// Initializes a new ClusterManager instance.
    ///
    /// - Parameter configuration: The clustering configuration settings.
    public init(
        configuration: Configuration = Configuration(),
        storage: Storage
    ) {
        self.configuration = configuration
        self.tree = QuadTree(rect: .world)
    }

    /// A collection of currently visible annotations on the map.
    public private(set) var visibleAnnotations: [ClusterOrAnnotation<Annotation>] = []

    /// Adds a single annotation to the cluster manager.
    ///
    /// - Parameter annotation: The annotation to be added.
    public func add(_ annotation: Storage.Element) {
        tree.add(annotation)
    }

    /// Adds multiple annotations to the cluster manager.
    ///
    /// - Parameter annotations: An array of annotations to be added.
    public func add<Annotations: Sequence>(_ annotations: Annotations) where Annotations.Element == Storage.Element {
        annotations.forEach { tree.add($0) }
    }

    /// Removes a single annotation from the cluster manager.
    ///
    /// - Parameter annotation: The annotation to be removed.
    public func remove(_ annotation: Storage.Element) {
        tree.remove(annotation)
    }

    /// Removes multiple annotations from the cluster manager.
    ///
    /// - Parameter annotations: An array of annotations to be removed.
    public func remove<Annotations: Sequence>(_ annotations: Annotations) where Annotations.Element == Storage.Element {
        annotations.forEach { tree.remove($0) }
    }

    /// Removes all annotations that match a certain condition
    /// - Parameter condition: The condition which will be used to check wether the annotation will be removed
    public func removeAll(where condition: (Storage.Element) -> Bool) {
        tree.removeAll(where: condition)
    }
    
    /// Removes all annotations from the cluster manager.
    public func removeAll() {
        tree = QuadTree<Storage>(rect: .world)
    }

    /// A collection of all annotations.
    public func fetchAllAnnotations() -> [Storage.Element] {
        tree.findAnnotations(in: .world)
    }

    /// A collection of currently visible nested annotations on the map.
    ///
    /// This includes individual annotations as well as annotations within visible clusters.
    public func fetchVisibleNestedAnnotations() -> [Storage.Element] {
        visibleAnnotations.reduce(into: [Storage.Element]()) { partialResult, annotationType in
            switch annotationType {
            case .annotation(let annotation):
                partialResult.append(annotation)
            case .cluster(let clusterAnnotation):
                partialResult += clusterAnnotation.annotations
            }
        }
    }

    /// Reloads the annotations on the map based on the current zoom level and visible map region.
    /// This is an async-await variant of the `reload(mapViewSize:coordinateRegion:completion:)` method.
    ///
    /// - Parameters:
    ///   - mapViewSize: The size of the map view.
    ///   - coordinateRegion: The visible coordinate region on the map.
    /// - Returns: A `Difference` object which contains the changes made during the reload.
    @discardableResult
    public func reload(mapViewSize: CGSize, coordinateRegion: MKCoordinateRegion) async -> Difference {
        let visibleMapRect = MKMapRect(region: coordinateRegion)
        let visibleMapRectWidth = visibleMapRect.size.width
        let zoomScale = Double(mapViewSize.width) / visibleMapRectWidth
        let changes = performAnnotationClustering(zoomScale: zoomScale, visibleMapRect: visibleMapRect)
        return changes
    }

    /// Reloads the annotations on the map based on the current zoom level and visible map region.
    ///
    /// - Parameters:
    ///   - mkMapView: The map view.
    /// - Returns: A `Difference` object which contains the changes made during the reload.
    public func reload(mkMapView: MKMapView) async {
        await reload(mapViewSize: mkMapView.bounds.size, coordinateRegion: mkMapView.region)
    }
}

private extension ClusterManager {
    func performAnnotationClustering(zoomScale: Double, visibleMapRect: MKMapRect) -> Difference {
        let mapRects = divideMapIntoGridCells(for: zoomScale, visibleMapRect: visibleMapRect)

        if configuration.shouldDistributeAnnotationsOnSameCoordinate {
            adjustOverlappingAnnotations(within: visibleMapRect)
        }

        let allAnnotations = clusterAnnotations(within: mapRects, zoomLevel: zoomLevel)
        let (toAdd, toRemove) = determineAnnotationChanges(
            allAnnotations: allAnnotations,
            visibleMapRect: visibleMapRect
        )

        applyVisibleAnnotationChanges(toAdd: toAdd, toRemove: toRemove)

        return Difference(insertions: toAdd, removals: toRemove)
    }

    func determineAnnotationChanges(
        allAnnotations: [ClusterOrAnnotation<Annotation>],
        visibleMapRect: MKMapRect
    ) -> (toAdd: [ClusterOrAnnotation<Annotation>], toRemove: [ClusterOrAnnotation<Annotation>]) {
        let before = visibleAnnotations
        let after = allAnnotations

        var toRemove = before.subtracted(after)
        let toAdd = after.subtracted(before)

        if !configuration.shouldRemoveInvisibleAnnotations {
            let toKeep = toRemove.filter { annotationType in
                switch annotationType {
                case .annotation(let annotation):
                    !visibleMapRect.contains(annotation.coordinate)
                case .cluster(let clusterAnnotation):
                    !visibleMapRect.contains(clusterAnnotation.coordinate)
                }
            }
            toRemove.subtract(toKeep)
        }

        return (toAdd, toRemove)
    }

    func applyVisibleAnnotationChanges(
        toAdd: [ClusterOrAnnotation<Annotation>],
        toRemove: [ClusterOrAnnotation<Annotation>]
    ) {
        visibleAnnotations.subtract(toRemove)
        visibleAnnotations.add(toAdd)
    }

    func clusterAnnotations(within mapRects: [MKMapRect], zoomLevel: Double) -> [ClusterOrAnnotation<Annotation>] {
        var allAnnotations: [ClusterOrAnnotation<Annotation>] = []
        for mapRect in mapRects {
            var annotations: [Storage.Element] = []

            for node in tree.findAnnotations(in: mapRect) {
                if node.shouldCluster {
                    annotations.append(node)
                } else {
                    allAnnotations.append(.annotation(node))
                }
            }

            let count = annotations.count
            if count >= configuration.minCountForClustering, zoomLevel <= configuration.maxZoomLevel {
                let cluster = ClusterOrAnnotation<Annotation>.Cluster(
                    coordinate: configuration.clusterPosition.calculatePosition(
                        for: annotations.map(\.coordinate),
                        within: mapRect
                    ),
                    annotations: annotations
                )
                allAnnotations.append(.cluster(cluster))
            } else {
                allAnnotations.append(contentsOf: annotations.map { .annotation($0) })
            }
        }
        return allAnnotations
    }

    func adjustOverlappingAnnotations(within mapRect: MKMapRect) {
        let annotations = tree.findAnnotations(in: mapRect)
        let hash = Dictionary(grouping: annotations) { $0.coordinate }
        for value in hash.values where value.count > 1 {
            let radiansBetweenAnnotations = (.pi * 2) / Double(value.count)
            for (index, annotation) in value.enumerated() {
                if var element = tree.remove(annotation) {
                    let bearing = radiansBetweenAnnotations * Double(index)
                    element.coordinate = annotation.coordinate.coordinate(
                        onBearingInRadians: bearing,
                        atDistanceInMeters: configuration.distanceFromContestedLocation
                    )
                    tree.add(element)
                }
            }
        }
    }

    func divideMapIntoGridCells(for zoomScale: Double, visibleMapRect: MKMapRect) -> [MKMapRect] {
        guard !zoomScale.isInfinite, !zoomScale.isNaN else { return [] }

        zoomLevel = zoomScale.zoomLevel
        let scaleFactor = zoomScale / configuration.cellSizeForZoomLevel(Int(zoomLevel)).width

        let minX = Int(floor(visibleMapRect.minX * scaleFactor))
        let maxX = Int(floor(visibleMapRect.maxX * scaleFactor))
        let minY = Int(floor(visibleMapRect.minY * scaleFactor))
        let maxY = Int(floor(visibleMapRect.maxY * scaleFactor))

        var mapRects = [MKMapRect]()
        for x in minX...maxX {
            for y in minY...maxY {
                var mapRect = MKMapRect(
                    x: Double(x) / scaleFactor,
                    y: Double(y) / scaleFactor,
                    width: 1 / scaleFactor,
                    height: 1 / scaleFactor
                )
                if mapRect.origin.x > MKMapPointMax.x {
                    mapRect.origin.x -= MKMapPointMax.x
                }
                mapRects.append(mapRect)
            }
        }
        return mapRects
    }
}
