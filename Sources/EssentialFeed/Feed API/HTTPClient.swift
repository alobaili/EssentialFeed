//
//  HTTPClient.swift
//
//
//  Created by Abdulaziz Alobaili on 09/02/2024.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
