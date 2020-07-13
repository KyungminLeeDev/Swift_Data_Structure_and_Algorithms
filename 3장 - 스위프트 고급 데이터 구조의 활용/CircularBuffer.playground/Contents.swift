import Foundation

private struct Constants {
    fileprivate static let defaultBufferCapacity: Int = 16
}

public enum CircularBufferOperation {
    case Ignore, Overwrite
}

/// 순환 버퍼는 헤드 인덱스와 테일 인덱스를 사용하는 고정 크기의 데이터 구조다.
/// - 버퍼가 꽉 차면 헤드 인덱스는 0으로 되돌아가므로, 순환 버퍼는 지정된 용량까지 데이터를 받아들이고, 기존의 데이터는 새로운 데이터로 대체된다.
/// - 크기가 고정돼있어서 데이터를 저장할 때 배열보다 효율적이다.
/// - 비디오/오디오 분야에서 보편적으로 활용된다.
public struct CircularBuffer<T> {
    fileprivate var data: [T]
    fileprivate var head: Int = 0, tail: Int = 0
    
    private var internalCount: Int = 0
    private var overwriteOperation: CircularBufferOperation = CircularBufferOperation.Overwrite
    
    /// Constructs an empty CircularBuffer.
    public init() {
        data = [T]()
        data.reserveCapacity(Constants.defaultBufferCapacity)
    }
    
    /// Construct a CircularBuffer of `count` elements
    ///
    /// - remark: If `count` is not a power of 2 it will be incremented to the next closest power of 2 of its value.
    /// 'count'만큼 2를 거듭제곱하지 않은 경우, 그에 가장 가까운 수만큼 2를 거듭제곱함
    /// 위 내용 해석: count가 2의 거듭제곱 값 아닌경우, 가장 가까운 2의 거듭제곱 값으로 만듬 (3->4, 5->8. 9->16)
    public init(_ count: Int, overwriteOperation: CircularBufferOperation = .Overwrite) {
        var capacity = count
        if (capacity < 1) {
            capacity = Constants.defaultBufferCapacity
        }
        
        // Ensure that `count` is a power of 2
        // 'count'만큼 2를 거듭제곱 함
        if ((capacity & (~capacity + 1)) != capacity) {
            var b = 1
            while (b < capacity) {
                b = b << 1
            }
            capacity = b
        }
        
        data = [T]()
        data.reserveCapacity(capacity)
        self.overwriteOperation = overwriteOperation
    }
    
    /// Constructs a CircularBuffer from a sequence.
    public init<S: Sequence>(_ elements: S, size: Int) where S.Iterator.Element == T {
        self.init(size)
        elements.forEach({ push(element: $0) })
    }
 
    /// Removes and returns the first `element` in the buffer.
    ///
    /// - returns:
    ///     - If the buffer not empty, the first element of type `T`.
    ///     - If the buffer is empty, 'nil' is returned.
    public mutating func pop() -> T? {
        if (isEmpty()) {
            return nil
        }
        
        let el = data[head]
        head = incrementPointer(pointer: head)
        internalCount -= 1
        return el
    }
    
    /// Returns the first `element` in the buffer without removing it.
    ///
    /// - returns: The first element of type `T`.
    public func peek() -> T? {
        if (isEmpty()) {
            return nil
        }
        return data[head]
    }
    
    
    /// Appends `element` to the end of the buffer.
    ///
    /// The default `overwriteOperation` is `CircularBufferOperation.Overwrite`, which overwrites the oldest elements first if the buffer capacity is full.
    /// 기본 메소드인 'overwriteOperation'이 'CircularBufferOperation.Overwrite'가 되면, 버퍼가 가득 찬 경우, 가장 오래된 요소를 덮어쓰기 한다.
    ///
    /// If `overwriteOperation` is `CircularBufferOperation.Ignore`, when the capacity is full newer elements will not be added to the buffer until exisint elements are removed.
    /// 만일 "CircularBufferOperation.Ignore'이 되면, 기존의 요소가 삭제될 때까지 버퍼에 새로운 요소가 추가하지 않는다.
    ///
    /// - complexity: O(1)
    /// - parameter element: An element of type `T`
    public mutating func push(element: T) {
        if (isFull()) {
            switch overwriteOperation {
            case .Ignore:
                // Do not add new elements until the count is less than the capacity
                return
            case .Overwrite:
                pop()
            }
        }
        
        if (data.endIndex < data.capacity) {
            data.append(element)
        } else {
            data[tail] = element
        }
        
        tail = incrementPointer(pointer: tail)
        internalCount += 1
    }
    
    
    
    
    /// Resets the buffer to an empty state
    public mutating func clear() {
        head = 0
        tail = 0
        internalCount = 0
        data.removeAll(keepingCapacity: true)
    }
    
    /// Returns the number of elements in the buffer.
    ///
    /// `count` is the number of elements in the buffer.
    public var count: Int {
        return internalCount
    }
    
    /// Returns the capacity of the buffer.
    public var capacity: Int {
        get {
            return data.capacity
        }
        set {
            data.reserveCapacity(newValue)
        }
    }
    
    /// Check if the buffer is full.
    ///
    /// - returns: `True` if the buffer is full, otherwise it returns `False`.
    public func isFull() -> Bool {
        return count == data.capacity
    }
    
    /// Check if the buffer is empty.
    ///
    /// - returns: `True` if the buffer is empty, otherwise it returns `False`.
    public func isEmpty() -> Bool {
        return (count < 1)
    }
    
    /// Increment a pointer value by one.
    ///
    /// - remark: This method handles wrapping the incremented value if it would be beyond the last element in the array.
    fileprivate func incrementPointer(pointer: Int) -> Int {
        return (pointer + 1) & (data.capacity - 1) // 증가된 값이 용량-1을 넘지 않도록 제한
    }
    
    /// Decrement a pointer value by 1.
    ///
    /// - remark: This method handles wrapping the decremented value if it would be before the first element in the array.
    fileprivate func decrementPointer(pointer: Int) -> Int {
        return (pointer - 1) & (data.capacity - 1)
    }
    
    /// Converts a logical index used for subscripting to the current internal array index for an element.
    /// 서브스크립트 작성을 위해 로지컬 인덱스 값을 현재 내부 배열 요소의 인덱스 값으로 변환함
    fileprivate func convertLogicalToRealIndex(logicalIndex: Int) -> Int {
        return (head + logicalIndex) & (data.capacity - 1)
    }

    /// Verifies `index` is within range
    fileprivate func checkIndex(index: Int) {
        if index < 0 || index > count {
            fatalError("Index out of range")
        }
    }
}

// 프로토콜 추가 목적: 타입 값을 출력할 때 좀 더 읽기 쉬운 형태의 값을 반환한다.
extension CircularBuffer: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return data.description
    }
    
    public var debugDescription: String {
        return data.debugDescription
    }
}

// 프로토콜 추가 목적: for...in 순환문 사용할 수 있도록 한다.
// 지연 로딩된 시퀀스를 반환하도록 한다.
extension CircularBuffer: Sequence {
    
    /// Returns a *generator* over the elements of this *sequence*.
    ///
    /// - Complexity: O(1).
    public func makeIterator() -> AnyIterator<T> {
        var newData = [T]()
        if count > 0 {
            newData = [T](repeating: data[head], count: count)
            if head > tail {
                
                // number of elements to copy for first half
                // 처음 절반에 해당하는 요소의 수를 복사
                let front = data.capacity - head
                newData[0..<front] = data[head..<data.capacity]
                if front < count {
                    newData[front + 1..<newData.capacity] = data[0..<count - front]
                }
            } else {
                newData[0..<tail - head] = data[head..<tail]
            }
        }
        
        return AnyIterator(IndexingIterator(_elements: newData.lazy))
    }
}

// 프로토콜 추가 목적: 배열 리터럴 문법을 사용할 수 있도록 한다.
extension CircularBuffer: ExpressibleByArrayLiteral {
    
    /// Constructs a circular buffer using an array literal.
    public init(arrayLiteral elements: T...) {
        self.init(elements, size: elements.count)
    }
}




var circBuffer = CircularBuffer<Int>(4)

circBuffer.push(element: 100) // head 0, tail 1, internalCount 1
circBuffer.push(element: 120) // head 0, tail 2, internalCount 2
circBuffer.push(element: 125) // head 0, tail 3, internalCount 3
circBuffer.push(element: 130) // head 0, tail 0, internalCount 4

// 다음 요소를 삭제하고 가져옴 (실제로 지워지는 것이 아니라 head 증가)
let x = circBuffer.pop() // x = 100
circBuffer // head 1, tail 0, internalCount 3, [100,120,125,130]

// 다음 요소를 삭제하지 않고 가져옴 (헤드 증가안함)
let y = circBuffer.peek() // y = 120
circBuffer // head 1, tail 0, internalCount 3, [100,120,125,130]

let z = circBuffer.pop() // z = 120
circBuffer // head 2, tail 0, internalCount 2, [100,120,125,130]

circBuffer.push(element: 150)
circBuffer // head 2, tail 1, internalCount 3, [150,120,125,130]
circBuffer.push(element: 155)
circBuffer // head 2, tail 2, internalCount 4, [150,155,125,130]
circBuffer.push(element: 160)
circBuffer // head 2, tail 3, internalCount 4, [150,155,160,130]
// 이 순환 버퍼의 용량은 4뿐이므로, 새로운 요소는 125를 덮어쓰게 됨


var circBufferIgnore = CircularBuffer<Int>(4, overwriteOperation: .Ignore)
let cnt = circBufferIgnore.count // 0
let capa = circBufferIgnore.capacity // 4


var circularBuffer = CircularBuffer<Int>()
circularBuffer.push(element: 4)
circularBuffer.push(element: 7)
circularBuffer.push(element: 9)
circularBuffer.push(element: 11)
var circBufferFromCircBuffer = CircularBuffer<Int>(circularBuffer, size: circularBuffer.count)

var circularBufferUsingArrayLiteralNotation: CircularBuffer<Int> = [4,5,6,7,8]
