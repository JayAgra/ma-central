//
//  URLSessionConfiguration.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import Foundation

let sharedSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.httpCookieStorage = HTTPCookieStorage.shared
    
    return URLSession(configuration: configuration)
}()
