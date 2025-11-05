/// A protocol representing a mutable collection-like storage for nodes or elements.
/// Conforming types provide storage capabilities with insertion and removal of elements.
public protocol NodeStorage: Sequence, ExpressibleByArrayLiteral {
    /// The type of elements stored by the conforming type.
    associatedtype Element
    
    /// The number of elements currently stored.
    var count: Int { get }
    
    /// Inserts the given element if possible.
    ///
    /// - Parameter element: The element to insert.
    /// - Returns: `true` if the element was added; `false` otherwise.
    mutating func add(_ element: Element) -> Bool
    
    /// Removes the given element if present.
    ///
    /// - Parameter element: The element to remove.
    /// - Returns: The removed element if it was found; otherwise, `nil`.
    mutating func remove(_ element: Element) -> Element?
    
    /// Removes all elements matching the given predicate.
    ///
    /// - Parameter condition: A closure that takes an element and returns `true` if the element should be removed.
    /// - Returns: An array of the elements that were removed, in unspecified order.
    mutating func removeAll(where condition: (Element) -> Bool) -> [Element]
}
