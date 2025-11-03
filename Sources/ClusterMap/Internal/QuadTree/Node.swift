//
//  Node.swift
//
//
//  Created by Mikhail Vospennikov on 03.07.2023.
//

import MapKit

final class Node<AnnotationType: CoordinateIdentifiable> where AnnotationType: Hashable {
    let maxPointCapacity = 8
    let rect: MKMapRect

    var annotations: [AnnotationType] = []
    var type: `Type` = .leaf

    init(rect: MKMapRect) {
        self.rect = rect
    }

    @discardableResult
    func add(_ targetAnnotation: AnnotationType) -> Bool {
        guard isAnnotationWithinRect(targetAnnotation) else {
            return false
        }

        switch type {
        case .leaf:
            annotations.append(targetAnnotation)
            if annotations.count >= maxPointCapacity {
                subdivide()
            }
        case .internal(let children):
            for child in children where child.add(targetAnnotation) {
                return true
            }
        }
        return true
    }

    @discardableResult
    func remove(_ targetAnnotation: AnnotationType) -> AnnotationType? {
        guard isAnnotationWithinRect(targetAnnotation) else {
            return nil
        }

        if let element = removeAnnotationFromCurrentNode(targetAnnotation) {
            return element
        }

        if let element = removeAnnotationFromChildren(targetAnnotation) {
            return element
        }

        return nil
    }
    
    func findAnnotations(in targetRect: MKMapRect) -> [AnnotationType] {
        guard rect.intersects(targetRect) else {
            return []
        }

        var foundAnnotations: [AnnotationType] = []
        foundAnnotations.reserveCapacity(annotations.count)

        for annotation in annotations where targetRect.contains(annotation.coordinate) {
            foundAnnotations.append(annotation)
        }

        switch type {
        case .leaf:
            break
        case .internal(let childNodes):
            for childNode in childNodes {
                foundAnnotations.append(contentsOf: childNode.findAnnotations(in: targetRect))
            }
        }

        return foundAnnotations
    }
}

// MARK: RemoveAll
extension Node {
    @discardableResult
    func removeAll(where condition: (AnnotationType) -> Bool) -> [AnnotationType] {
        var removedItems: [AnnotationType] = []
        removedItems += removeAllAnnotationsFromChildren(where: condition)
        removedItems += removeAllAnnotationFromCurrentNode(where: condition)
        return removedItems
    }
    
    private func removeAllAnnotationFromCurrentNode(where condition: (AnnotationType) -> Bool) -> [AnnotationType] {
        let annotationsToRemove = annotations.filter(condition)
        if annotationsToRemove.isEmpty {
            return []
        }
        
        return annotationsToRemove.compactMap { annotations.remove($0) }
    }
    
    private func removeAllAnnotationsFromChildren(where condition: (AnnotationType) -> Bool) -> [AnnotationType] {
        guard case let .internal(children) = type else {
            return []
        }
        
        return children.reduce(into: []) { result, child in
            result += child.removeAll(where: condition)
        }
    }
}

extension Node {
    private func isAnnotationWithinRect(_ targetAnnotation: AnnotationType) -> Bool {
        rect.contains(targetAnnotation.coordinate)
    }

    private func removeAnnotationFromCurrentNode(_ targetAnnotation: AnnotationType) -> AnnotationType? {
        if let indexOfPoint = annotations.firstIndex(where: { $0 == targetAnnotation }) {
            return annotations.remove(at: indexOfPoint)
        }
        return nil
    }

    private func removeAnnotationFromChildren(_ targetAnnotation: AnnotationType) -> AnnotationType? {
        switch type {
        case .internal(let children):
            for child in children {
                if let element = child.remove(targetAnnotation) {
                    return element
                }
            }
        case .leaf:
            break
        }
        return nil
    }

    private func subdivide() {
        switch type {
        case .leaf:
            type = .internal(children: .init(parentNode: self))
        case .internal:
            preconditionFailure("Calling subdivide on an internal node")
        }
    }
}
