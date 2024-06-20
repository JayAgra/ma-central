//
//  CheckLoginState.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import Foundation

func checkLoginState(completion: @escaping (Bool) -> Void) {
    // for testing
    completion(true)
    /*
    guard let url = URL(string: "https://beartracks.io/api/v1/whoami") else {
        completion(false)
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    let task = sharedSession.dataTask(with: request) { (data, response, error) in
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    task.resume()
    */
}
