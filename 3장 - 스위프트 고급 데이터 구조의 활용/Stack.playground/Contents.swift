import Foundation

public struct ArrayStack<T> {
    private var elements = [T]()
    
    public init() {}
    
    public init<S : Sequence>(_ s: S) where S.Iterator.Element == T {
        self.elements = Array(s.reversed())
    }
    
    public mutating func pop() -> T? {
        return self.elements.popLast()
    }
 
    public mutating func push(element: T) {
        self.elements.append(element)
    }
    
    public func peek() -> T? {
        return self.elements.last
    }
    
    public func isEmpty() -> Bool {
        return self.elements.isEmpty
    }
    
    public var count: Int {
        return self.elements.count
    }
}



extension ArrayStack: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self.init(elements)
    }
   
}

// 타입 갑을 출력할 때 좀 더 이해하기 쉬운 이름을 반환하기 위한 프로토콜
extension ArrayStack: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return self.elements.description
    }
    
    public var debugDescription: String {
        return self.elements.debugDescription
    }
}

extension ArrayStack: Sequence {
    public func makeIterator() -> AnyIterator<T> {
        return AnyIterator(IndexingIterator(_elements: self.elements.lazy.reversed()))
    }
}



var myStack = ArrayStack<Int>() // 빈 스택 생성

myStack.push(element: 5)    // [5]
myStack.push(element: 44)   // [5, 44]
myStack.push(element: 23)   // [5, 44, 23]
print(myStack)              // [5, 44, 23]

var x = myStack.pop()   // 23
x = myStack.pop()       // 44
x = myStack.pop()       // 5
x = myStack.pop()       // nil
x = myStack.pop()       // nil
print(myStack)          // []

myStack.push(element: 4)
myStack.push(element: 5)
myStack.push(element: 6)
myStack.push(element: 7)
print(myStack) // [4, 5, 6, 7]



// 스택으로 또 다른 스택 생성
var myStackFromStack = ArrayStack<Int>(myStack)
print(myStackFromStack) // [4, 5, 6, 7]

// 스택은 LIFO 이므로 for문으로 순서대로 순회할때
// 배열의 뒤에서부터 순회하게 된다.
for el in myStackFromStack {
    print(el) // 7 -> 6 -> 5 -> 4
}
