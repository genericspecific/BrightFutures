// The MIT License (MIT)
//
// Copyright (c) 2014 Thomas Visser
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
import BrightFutures

class Counter {
    var i: Int = 0
}

class ExecutionContextTests: XCTestCase {
    
    func testImmediateOnMainThreadContextOnMainThread() {
        let counter = Counter()
        
        counter.i = 1
        
        ImmediateOnMainExecutionContext {
            XCTAssert(NSThread.isMainThread())
            counter.i = 2
        }
        
        XCTAssertEqual(counter.i, 2)
    }
    
    func testImmediateOnMainThreadContextOnBackgroundThread() {
        let e = self.expectation()
        Queue.global.async {
            ImmediateOnMainExecutionContext {
                XCTAssert(NSThread.isMainThread())
                e.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testDispatchQueueToContext() {
        var key = "key"
        let value1 = getMutablePointer("queue1")
        
        let queue1 = dispatch_queue_create("test1", DISPATCH_QUEUE_SERIAL)
        dispatch_queue_set_specific(queue1, &key, value1, nil)
        
        let e1 = self.expectation()
        (toContext(queue1)) {
            XCTAssertEqual(dispatch_get_specific(&key), value1)
            e1.fulfill()
        }
        
        let value2 = getMutablePointer("queue2")
        
        let queue2 = dispatch_queue_create("test2", DISPATCH_QUEUE_CONCURRENT)
        dispatch_queue_set_specific(queue2, &key, value2, nil)
        
        let e2 = self.expectation()
        (toContext(queue2)) {
            XCTAssertEqual(dispatch_get_specific(&key), value2)
            e2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func getMutablePointer (object: AnyObject) -> UnsafeMutablePointer<Void> {
        return UnsafeMutablePointer<Void>(bitPattern: Int(ObjectIdentifier(object).uintValue))
    }
    
}