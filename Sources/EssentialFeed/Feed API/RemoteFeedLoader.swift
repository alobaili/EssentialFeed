//
//  RemoteFeedLoader.swift
//
//
//  Created by Abdulaziz Alobaili on 09/02/2024.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
                case .success(let data, let response):
                    completion(FeedItemsMapper.map(data, from: response))
                case .failure:
                    completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
