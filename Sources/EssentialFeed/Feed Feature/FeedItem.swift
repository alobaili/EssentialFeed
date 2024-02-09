//
//  FeedItem.swift
//
//
//  Created by Abdulaziz Alobaili on 06/02/2024.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
