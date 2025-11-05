//
//  Node.swift
//
//
//  Created by Mikhail Vospennikov on 03.07.2023.
//

import MapKit



final class Node<Storage: NodeStorage> where Storage.Element: CoordinateIdentifiable & Hashable {
    typealias Annotation = Storage.Element
    
    let maxPointCapacity = 8
    let rect: MKMapRect

    var annotations: Storage
    var type: `Type` = .leaf

    init(rect: MKMapRect) {
        self.rect = rect
        self.annotations = []
    }

    @discardableResult
    func add(_ targetAnnotation: Annotation) -> Bool {
        guard isAnnotationWithinRect(targetAnnotation) else {
            return false
        }

        switch type {
        case .leaf:
            guard annotations.add(targetAnnotation) else {
                return false
            }
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
    func remove(_ targetAnnotation: Annotation) -> Annotation? {
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
    
    func findAnnotations(in targetRect: MKMapRect) -> [Annotation] {
        guard rect.intersects(targetRect) else {
            return []
        }

        var foundAnnotations: [Annotation] = []
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
    func add<Annotations: Sequence>(annotations: Annotations) -> [Annotation] where Annotations.Element == Annotation {
        let annotationsInRectangle = annotations.filter { isAnnotationWithinRect($0) }
        if annotationsInRectangle.isEmpty {
            return []
        }
        
        switch type {
        case .leaf:
            var addedAnnotations: [Annotation] = []
            for annotation in annotationsInRectangle {
                guard self.annotations.add(annotation) else {
                    continue
                }
                addedAnnotations.append(annotation)
                guard self.annotations.count >= maxPointCapacity else {
                    continue
                }
                subdivide()
                break
            }
            let remainingAnnotations = annotationsInRectangle.filter { !addedAnnotations.contains($0) }
            guard remainingAnnotations.count < annotationsInRectangle.count else {
                return addedAnnotations
            }
            addedAnnotations.append(
                contentsOf: self.add(annotations: remainingAnnotations)
            )
            return addedAnnotations
        case .internal(let children):
            return children
                .flatMap { node in
                    node.add(annotations: annotations)
                }
        }
    }
    
    @discardableResult
    func removeAll(where condition: (Annotation) -> Bool) -> [Annotation] {
        var removedItems: [Annotation] = []
        removedItems += removeAllAnnotationsFromChildren(where: condition)
        removedItems += removeAllAnnotationFromCurrentNode(where: condition)
        return removedItems
    }
    
    private func removeAllAnnotationFromCurrentNode(where condition: (Annotation) -> Bool) -> [Annotation] {
        return annotations.removeAll(where: condition)
    }
    
    private func removeAllAnnotationsFromChildren(where condition: (Annotation) -> Bool) -> [Annotation] {
        guard case let .internal(children) = type else {
            return []
        }
        
        return children.reduce(into: []) { result, child in
            result += child.removeAll(where: condition)
        }
    }
}

extension Node {
    private func isAnnotationWithinRect(_ targetAnnotation: Annotation) -> Bool {
        rect.contains(targetAnnotation.coordinate)
    }

    private func removeAnnotationFromCurrentNode(_ targetAnnotation: Annotation) -> Annotation? {
        return annotations.remove(targetAnnotation)
    }

    private func removeAnnotationFromChildren(_ targetAnnotation: Annotation) -> Annotation? {
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
