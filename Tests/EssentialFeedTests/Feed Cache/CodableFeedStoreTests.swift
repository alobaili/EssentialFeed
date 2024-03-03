//
//  CodableFeedStoreTests.swift
//  
//
//  Created by Abdulaziz Alobaili on 29/02/2024.
//

import XCTest
import EssentialFeed
import TestHelpers

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            feed.map(\.local)
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }

        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }

    func insert(
        _ feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping FeedStore.InsertionCompletion
    ) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()

        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()

        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date.now

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date.now

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    // MARK: Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)

        return sut
    }

    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
        let expectation = expectation(description: "Wait for cache insertion")

        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    private func expect(
        _ sut: CodableFeedStore,
        toRetrieve expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
                case (.empty, .empty):
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

    private func expect(
        _ sut: CodableFeedStore,
        toRetrieveTwice expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    func testSpecificStoreURL() -> URL {
        URL.cachesDirectory.appending(component: "\(type(of: self)).store")
    }
}
