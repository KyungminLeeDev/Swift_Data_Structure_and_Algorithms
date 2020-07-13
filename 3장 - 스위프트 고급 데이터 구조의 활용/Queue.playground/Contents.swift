import Foundation

/// The Queue structure is a fixed-size data structure that stores data in a First In First Out (FIFO) collection.
/// 큐는 입력된 순서대로 데이터를 처리할 때 보편적으로 활용.
public struct Queue<T> {
    private var data = [T]()
    
    // MARK: - Creating a Queue
    
    /// Constructs an empty Queue.
    public init() {}
    
    /// Constructs a Queue from a sequence.
    public init<S: Sequence>(_ elements: S) where S.Iterator.Element == T {
        data.append(contentsOf: elements)
    }
    
    // MARK: - Adding and Removing elements
    
    /// Appends `element` to the end of the queue.
    ///
    /// - complexity: O(1)
    /// - parameter element: An element of type `T`
    public mutating func enqueue(element: T) {
        data.append(element)
    }
    
    /// Removes and returns the first `element` in the queue.
    ///
    /// - returns:
    ///     - If the queue not empty, the first element of type `T`.
    ///     - If the queue is empty, 'nil' is returned.
    public mutating func dequeue() -> T? {
        return data.removeFirst()
    }
    
    /// Returns the first `element` in the queue without removing it.
    ///
    /// - returns:
    ///     - If the queue not empty, the first element of type `T`.
    ///     - If the queue is empty, 'nil' is returned.
    public func peek() -> T? {
        return data.first
    }
    
    // MARK: - Helpers for a Circular Buffer
    
    /// Resets the buffer to an empty state
    public mutating func clear() {
        data.removeAll()
    }
    
    /// Returns the number of elements in the queue.
    ///
    /// `count` is the number of elements in the queue.
    public var count: Int {
        return data.count
    }
    
    /// Returns the capacity of the queue.
    public var capacity: Int {
        get {
            return data.capacity
        }
        set {
            data.reserveCapacity(newValue)
        }
    }
    
    /// Check if the queue is full.
    ///
    /// - returns: `True` if the queue is full, otherwise it returns `False`.
    public func isFull() -> Bool {
        return count == data.capacity
    }
    
    /// Check if the queue is empty.
    ///
    /// - returns: `True` if the queue is empty, otherwise it returns `False`.
    public func isEmpty() -> Bool {
        return data.isEmpty
    }
    
    /// Verifies `index` is within range
    private func checkIndex(index: Int) {
        if index < 0 || index > count {
            fatalError("Index out of range")
        }
    }
    
}




// 타입 값을 출력할 때 이해하기 쉽게 반환
// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension Queue: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return data.description
    }
    
    public var debugDescription: String {
        return data.debugDescription
    }
}

// for...in 루프에서 큐를 사용할수 있도록 지연 로딩된 시퀀스를 반환
extension Queue: Sequence {
    // MARK: Sequence protocol conformance
    
    // 원본 코드 - 오류 발생
    /*
    /// Returns an *iterator* over the elements of this *sequence*.
    ///
    /// - Complexity: O(1).
    public func generate() -> AnyIterator<T> {
        return AnyIterator(IndexingIterator(_elements: data.lazy))
    }
    */
    
    // 수정한 코드 - 2020.07.13 수정
    /// Returns an *iterator* over the elements of this *sequence*.
    ///
    /// - Complexity: O(1).
    public func makeIterator() -> AnyIterator<T> {
        return AnyIterator(IndexingIterator(_elements: data.lazy))
    }
}

extension Queue: ExpressibleByArrayLiteral {
    // MARK: ExpressibleByArrayLiteral protocol conformance
    
    /// Constructs a queue using an array literal.
    public init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}



extension Queue: Collection {
    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return data.index(after: i)
    }
}

// 서브스크립트 문법을 통해 큐의 값을 설정하거나 가져올 수 있음
extension Queue: MutableCollection {
    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return count - 1
    }

    public subscript(index: Int) -> T {
        get {
            checkIndex(index: index)
            return data[index]
        }
        set {
            checkIndex(index: index)
            data[index] = newValue
        }
    }
}





// MARK: 큐 구조를 확인할 수 있는 예제

var queue = Queue<Int>()
queue.enqueue(element: 100) // [100]
queue.enqueue(element: 120) // [100,120]
queue.enqueue(element: 125) // [100,120,125]
queue.enqueue(element: 130) // [100,120,125,130]

let x = queue.dequeue() // x = 100, queue = [120,125,130]

// 해당 요소를 제거 하지 않고 다음 요소를 확인
let y = queue.peek() // y = 120 // queue = [120,125,130]

let z = queue.dequeue() // z = 120 // queue = [125,130]



// MARK: 프로토콜이 제대로 작동하는지 확인

// ArrayLiteral 문법 사용
var q1: Queue<Int> = [1,2,3,4,5] // [1,2,3,4,5]

// q1에서 가져온 SequenceType을 받는 초기화 메소드를 이용해서 새로운 큐를 생성
var q2 = Queue<Int>(q1)
 
let q1x = q1.dequeue() // q1x = 1, [2,3,4,5]

q2.enqueue(element: 55) // [1,2,3,4,5,55]

// For..in은 Sequenetype 프로토콜 사용
for el in q1 {
    print(el) // 2, 3, 4, 5
}

// MutableCollection 확인
// 0번 요소에 직접 접근해서 갑 변경
q1[0] = 1 // [1,3,4,5]

// 인덱스범위 아니면 에러
// q1[5] = 1 // Fatal error: Index out of range:...
print(q1) // 1,3,4,5
