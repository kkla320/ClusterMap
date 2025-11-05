extension Array: NodeStorage where Element: Hashable {
    public mutating func removeAll(where condition: (Element) -> Bool) -> [Element] {
        let elementsToRemove = filter(condition)
        if elementsToRemove.isEmpty {
            return []
        }
        
        return elementsToRemove.compactMap { remove($0) }
    }
    
    public mutating func add(_ element: Element) -> Bool {
        append(element)
        return true
    }
    
    public mutating func remove(_ element: Element) -> Element? {
        if let indexOfPoint = self.firstIndex(of: element) {
            return remove(at: indexOfPoint)
        }
        return nil
    }
}
