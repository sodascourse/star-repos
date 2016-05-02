//
//  StarredGithubRepos.swift
//  StarRepos
//
//  Created by sodas on 5/2/16.
//  Copyright © 2016 sodas. All rights reserved.
//

import Alamofire
import ObjectMapper
import AlamofireObjectMapper

struct GithubRepo {
    let name: String
    let owner: String

    var urlString: String {
        return "https://github.com/\(self.owner)/\(self.name)"
    }
}

// MARK: ObjectMapper

extension GithubRepo: Mappable {
    init?(_ map: Map) {
        self.name = map["name"].valueOrFail()
        self.owner = map["owner.login"].valueOrFail()
        guard map.isValid else {
            return nil
        }
    }

    mutating func mapping(map: Map) {
        switch map.mappingType {
        case .FromJSON:
            if let x = GithubRepo(map) {
                self = x
            }
        case .ToJSON:
            var name = self.name
            var owner = self.owner
            name <- map["name"]
            owner <- map["owner.login"]
        }
    }
}

// MARK: - Collection

struct StarredGithubRepoCollection {
    let username: String
    init(username: String) {
        self.username = username
    }

    func fetch(completion: (repos: [GithubRepo]?) -> Void) {
        let url = "https://api.github.com/users/\(self.username)/starred"
        Alamofire.request(.GET, url).responseArray { (response: Response<[GithubRepo], NSError>) in
            // Check for invalid result
            guard response.response?.statusCode < 400 else {
                completion(repos: nil)
                return
            }
            completion(repos: response.result.value)
        }
    }
}
