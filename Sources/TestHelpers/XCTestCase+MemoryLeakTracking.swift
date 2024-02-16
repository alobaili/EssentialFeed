//
//  XCTTestCase+MemoryLeakTracking.swift
//
//
//  Created by Abdulaziz Alobaili on 15/02/2024.
//

import XCTest

public extension XCTestCase {
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential memory leak.",
                file: file,
                line: line
            )
        }
    }
}
