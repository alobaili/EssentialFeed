//
//  FeedLoader.swift
//  
//
//  Created by Abdulaziz Alobaili on 06/02/2024.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
