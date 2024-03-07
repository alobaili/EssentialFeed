//
//  XCTestCase+FeedStoreSpecs.swift
//
//
//  Created by Abdulaziz Alobaili on 07/03/2024.
//

import XCTest
import EssentialFeed
import TestHelpers

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieveTwice: .empty, file: file, line: line)
    }

    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date.now

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date.now

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp), file: file, line: line)
    }

    func assertThatInsertDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let insertionError = insert((uniqueImageFeed().local, Date.now), to: sut)

        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }

    func assertThatInsertDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), to: sut)

        let insertionError = insert((uniqueImageFeed().local, Date.now), to: sut)

        XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
    }

    func assertThatInsertOverridesPreviouslyInsertedCacheValues(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date.now), to: sut)

        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), to: sut)

        expect(
            sut,
            toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp),
            file: file,
            line: line
        )
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(
            deletionError,
            "Expected empty cache deletion to succeed",
            file: file,
            line: line
        )
    }

    func assertThatDeleteHasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date.now), to: sut)

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(
            deletionError,
            "Expected non-empty cache deletion to succeed",
            file: file,
            line: line
        )
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), to: sut)

        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatSideEffectsRunSerially(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var completedOperationsInOrder = [XCTestExpectation]()

        let operation1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date.now) { _ in
            completedOperationsInOrder.append(operation1)
            operation1.fulfill()
        }

        let operation2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(operation2)
            operation2.fulfill()
        }

        let operation3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date.now) { _ in
            completedOperationsInOrder.append(operation3)
            operation3.fulfill()
        }

        waitForExpectations(timeout: 5)

        XCTAssertEqual(
            completedOperationsInOrder,
            [operation1, operation2, operation3],
            "Expected side-effects to run serially but operations finished in the wrong order",
            file: file,
            line: line
        )
    }
}

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let expectation = expectation(description: "Wait for cache insertion")
        var insertionError: Error?

        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        return insertionError
    }

    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let expectation = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        return deletionError
    }

    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
                case (.empty, .empty), (.failure, .failure):
                    break

                case (
                    .found(let expectedFeed, let expectedTimestamp),
                    .found(let retrievedFeed, let retrievedTimestamp)
                ):
                    XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                    XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)

                default:
                    XCTFail(
                        "Expected to retrieve \(expectedResult), but got \(retrievedResult) instead",
                        file: file,
                        line: line
                    )
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
