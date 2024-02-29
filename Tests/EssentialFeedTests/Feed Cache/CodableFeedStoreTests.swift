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
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreTests: XCTestCase {
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
}
