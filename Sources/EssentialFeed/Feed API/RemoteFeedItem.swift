//
//  RemoteFeedItem.swift
//
//
//  Created by Abdulaziz Alobaili on 25/02/2024.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
