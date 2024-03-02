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

    private let storeURL = URL.documentsDirectory.appending(component: "image-feed.store")

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

        let storeURL = URL.documentsDirectory.appending(component: "image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()

        let storeURL = URL.documentsDirectory.appending(component: "image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for cache retrieval")

        sut.retrieve { result in
            switch result {
                case .empty:
                    break
                default:
                    XCTFail("Expected empty result, but got \(result) instead")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for cache retrieval")

        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                    case (.empty, .empty):
                        break
                    default:
                        XCTFail(
                            """
                            Expected retrieving twice from empty cache to deliver the same
                            empty result, but got \(firstResult) ans \(secondResult) instead
                            """
                        )
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let feed = uniqueImageFeed().local
        let timestamp = Date.now
        let expectation = expectation(description: "Wait for cache retrieval")

        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")

            sut.retrieve { retrieveResult in
                switch retrieveResult {
                    case .found(let retrievedFeed, let retrievedTimestamp):
                        XCTAssertEqual(retrievedFeed, feed)
                        XCTAssertEqual(retrievedTimestamp, timestamp)
                    default:
                        XCTFail(
                            """
                            Expected found result with feed \(feed) and timestamp \(timestamp),
                            but got \(retrieveResult) instead
                            """
                        )
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }
}
