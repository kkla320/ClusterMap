//
//  QuadTree.swift
//
//
//  Created by Mikhail Vospennikov on 03.07.2023.
//

import MapKit

final class QuadTree<Storage: NodeStorage> where Storage.Element: CoordinateIdentifiable & Hashable {
    public typealias Annotation = Storage.Element
    
    private let root: Node<Storage>

    init(rect: MKMapRect = .world) {
        root = Node<Storage>(rect: rect)
    }

    @discardableResult
    func add(_ annotation: Annotation) -> Bool {
        root.add(annotation)
    }
    
    @discardableResult
    func add<Annotations: Sequence>(annotations: Annotations) -> [Annotation] where Annotations.Element == Annotation {
        root.add(annotations: annotations)
    }

    @discardableResult
    func remove(_ annotation: Annotation) -> Annotation? {
        root.remove(annotation)
    }
    
    @discardableResult
    func removeAll(where condition: (Annotation) -> Bool) -> [Annotation] {
        root.removeAll(where: condition)
    }

    func findAnnotations(in targetRect: MKMapRect) -> [Annotation] {
        root.findAnnotations(in: targetRect)
    }
}
