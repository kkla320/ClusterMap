//
//  QuadTreeTests.swift
//
//
//  Created by Mikhail Vospennikov on 03.07.2023.
//

import Foundation
import MapKit
import Testing
@testable import ClusterMap

@Suite
struct QuadTreeTests {
    @Test
    func add_pointInsideBoundary_returnsTrue() {
        let point = StubAnnotation.insideMediumRect
        let quadTree = makeSUT(with: .mediumRect)

        let result = quadTree.add(point)
        let points = quadTree.findAnnotations(in: .mediumRect)

        #expect(result)
        #expect(points.contains(point))
    }

    @Test
    func add_pointOutsideBoundary_returnsFalse() {
        let point = StubAnnotation.outsideMediumRect
        let quadTree = makeSUT(with: .mediumRect)

        let result = quadTree.add(point)
        let points = quadTree.findAnnotations(in: .mediumRect)

        #expect(result == false)
        #expect(!points.contains(point))
    }

    @Test
    func remove_pointInQuadTree_returnsTrue() {
        let point = StubAnnotation.insideMediumRect
        let quadTree = makeSUT(with: .mediumRect)

        quadTree.add(point)

        let result = quadTree.remove(point)
        let points = quadTree.findAnnotations(in: .mediumRect)

        #expect(result != nil)
        #expect(!points.contains(point))
    }

    @Test
    func remove_pointNotInQuadTree_returnsFalse() {
        let point = StubAnnotation.insideMediumRect
        let quadTree = makeSUT(with: .mediumRect)

        let result = quadTree.remove(point)
        let points = quadTree.findAnnotations(in: .mediumRect)

        #expect(result == nil)
        #expect(!points.contains(point))
    }
    
    @Test
    func removeAll_shouldRemoveAllAnnotationsWithMathingCondition() {
        let point1 = StubAnnotation.insideMediumRect
        let point2 = StubAnnotation.outsideMediumRect
        let quadTree = makeSUT(with: .world)
        
        quadTree.add(point1)
        quadTree.add(point2)
        
        let removedAnnotations = quadTree.removeAll { annotation in
            return MKMapRect.mediumRect.contains(annotation.coordinate)
        }
        
        let points = quadTree.findAnnotations(in: .world)

        #expect(removedAnnotations.count == 1)
        #expect(!points.contains(point1))
        #expect(points.contains(point2))
    }

    @Test
    func pointsInRect_containingPointsInsideAndOutside_returnsPointsOnlyInsideSelectedRect() {
        let point1 = StubAnnotation.insideSmallRect
        let point2 = StubAnnotation.insideSmallRect
        let pointOutside = StubAnnotation.outsideSmallRect
        let quadTree = makeSUT(with: .mediumRect)

        quadTree.add(point1)
        quadTree.add(point2)
        quadTree.add(pointOutside)

        let points = quadTree.findAnnotations(in: .smallRect)

        #expect(points.contains(point1))
        #expect(points.contains(point2))
        #expect(!points.contains(pointOutside), "\(pointOutside) \(points)")
    }
    
    @Test
    func checkMemoryLeak() {
        weak var weakReference: QuadTree<StubAnnotation>?
        var quadTree: QuadTree<StubAnnotation>? = makeSUT()
        
        weakReference = quadTree
        #expect(quadTree != nil)
        quadTree = nil
        #expect(weakReference == nil)
    }
    
    private func makeSUT(with rect: MKMapRect = .world) -> QuadTree<StubAnnotation> {
        return QuadTree<StubAnnotation>(rect: rect)
    }
}
