//
//  URLSessionConfiguration.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import Foundation

let sharedSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.httpCookieStorage = HTTPCookieStorage.shared
    
    return URLSession(configuration: configuration)
}()
