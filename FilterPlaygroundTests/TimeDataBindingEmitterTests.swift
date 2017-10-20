//
//  TimeDataBindingEmitterTests.swift
//  FilterPlaygroundTests
//
//  Created by Leo Thomas on 19.10.17.
//  Copyright © 2017 Leo Thomas. All rights reserved.
//

import XCTest
@testable import FilterPlayground

class TimeDataBindingEmitterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DataBindingContext.shared.reset()
    }

    func testValueChanged() {
        let observer = MockDataBindingObserver(id: "foo")
        observer.mockedBindingType = .time
        XCTAssertFalse(observer.valueChangedCalled)
        DataBindingContext.shared.add(observer: observer, with: observer.id)
        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(observer.valueChangedCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4)
    }

    func testTimerDeactivatesAfterRemovingObserver() {
        let observer = MockDataBindingObserver(id: "foo")
        observer.mockedBindingType = .time
        XCTAssertNil((TimeDataBindingEmitter.shared as! TimeDataBindingEmitter).timer)
        DataBindingContext.shared.add(observer: observer, with: observer.id)
        XCTAssertNotNil((TimeDataBindingEmitter.shared as! TimeDataBindingEmitter).timer)
        DataBindingContext.shared.removeObserver(with: observer.id)
        XCTAssertNil((TimeDataBindingEmitter.shared as! TimeDataBindingEmitter).timer)
    }
}
