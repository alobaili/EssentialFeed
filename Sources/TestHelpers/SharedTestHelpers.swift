//
//  SharedTestHelpers.swift
//
//
//  Created by Abdulaziz Alobaili on 26/02/2024.
//

import Foundation

public func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

public func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}
