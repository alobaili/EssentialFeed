//
//  FeedItemsMapper.swift
//
//
//  Created by Abdulaziz Alobaili on 09/02/2024.
//

import Foundation

final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var item: FeedItem {
            FeedItem(
                id: id,
                description: description,
                location: location,
                imageURL: image
            )
        }
    }

    private static var ok200: Int { 200 }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == ok200 else {
            throw RemoteFeedLoader.Error.invalidData
        }

        let root = try JSONDecoder().decode(Root.self, from: data)

        return root.items.map(\.item)
    }
}
