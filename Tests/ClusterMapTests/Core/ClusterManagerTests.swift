//
//  ClusterManagerTests.swift
//  Tests
//
//  Created by Lasha Efremidze on 7/11/18.
//  Copyright © 2018 efremidze. All rights reserved.
//

import MapKit
import Testing
@testable import ClusterMap

@Suite
struct ClusterManagerTests {
    @Test
    func addAndRemoveAllAnnotations() async {
        let clusterManager = makeSUT()
        let annotations = makeAnnotations(within: .mediumRect, count: 1000)

        await clusterManager.add(annotations)
        let difference = await clusterManager.reload(mapViewSize: .mediumMapSize, coordinateRegion: .mediumRegion)

        #expect(!difference.insertions.isEmpty)
        #expect(difference.removals.isEmpty)

        await clusterManager.removeAll()
        let difference2 = await clusterManager.reload(mapViewSize: .mediumMapSize, coordinateRegion: .mediumRegion)

        #expect(difference2.insertions.isEmpty)
        #expect(!difference2.removals.isEmpty)

        #expect(difference.insertions.count == difference2.removals.count)
        #expect(difference2.insertions.count == difference.removals.count)
    }

    @Test
    func addAndRemoveAnnotations() async {
        let clusterManager = makeSUT()
        let annotations = makeAnnotations(within: .mediumRect, count: 1000)

        await clusterManager.add(annotations)
        let difference = await clusterManager.reload(mapViewSize: .mediumMapSize, coordinateRegion: .mediumRegion)

        #expect(!difference.insertions.isEmpty)
        #expect(difference.removals.isEmpty)

        await clusterManager.remove(annotations)
        let difference2 = await clusterManager.reload(mapViewSize: .mediumMapSize, coordinateRegion: .mediumRegion)

        #expect(difference2.insertions.isEmpty)
        #expect(!difference2.removals.isEmpty)

        #expect(difference.insertions.count == difference2.removals.count)
        #expect(difference2.insertions.count == difference.removals.count)
    }

    @Test
    func sameCoordinate() async {
        let clusterManager = makeSUT(with: .init(shouldDistributeAnnotationsOnSameCoordinate: false))
        let annotations = makeAnnotations(within: .mediumRect, count: 1000)

        await clusterManager.add(annotations)
        await clusterManager.reload(mapViewSize: .mediumMapSize, coordinateRegion: .mediumRegion)

        let annotationsCount = await clusterManager.fetchVisibleNestedAnnotations().count
        #expect(annotationsCount == 1000)
    }

    @Test
    func removeInvisibleAnnotations() async {
        let clusterManager = makeSUT(with: .init(shouldRemoveInvisibleAnnotations: false))
        let annotations = makeAnnotations(within: .mediumRect, count: 1000)

        await clusterManager.add(annotations)
        await clusterManager.reload(mapViewSize: .mediumMapSize, coordinateRegion: .mediumRegion)

        let annotationsCount = await clusterManager.fetchVisibleNestedAnnotations().count
        #expect(annotationsCount == 1000)
    }

    @Test
    func minCountForClustering() async {
        let clusterManager = makeSUT(with: .init(minCountForClustering: 10))
        let annotations = makeAnnotations(within: .mediumRect, count: 1000)

        await clusterManager.add(annotations)
        await clusterManager.reload(mapViewSize: .mediumMapSize, coordinateRegion: .mediumRegion)

        let annotationsCount = await clusterManager.fetchVisibleNestedAnnotations().count
        #expect(annotationsCount == 1000)
    }

    @Test
    func multipleOperations() async {
        let clusterManager = makeSUT()
        let annotations = makeAnnotations(within: .mediumRect, count: 10)

        await clusterManager.removeAll()
        await clusterManager.add(annotations)

        let annotations2 = makeAnnotations(within: .mediumRect, count: 100)
        await clusterManager.removeAll()
        await clusterManager.add(annotations2)

        let annotationsCount = await clusterManager.fetchAllAnnotations().count
        #expect(annotationsCount == 100, "\(annotationsCount)")
    }
}

private extension ClusterManagerTests {
    func makeSUT(
        with configuration: ClusterManager<StubAnnotation>.Configuration = .init()
    ) -> ClusterManager<StubAnnotation> {
        ClusterManager<StubAnnotation>(configuration: configuration)
    }

    func makeAnnotations(within rect: MKMapRect, count: Int) -> [StubAnnotation] {
        (0..<count).map { _ in StubAnnotation(coordinate: MKCoordinateRegion(rect).randomLocationWithinRegion()) }
    }
}
