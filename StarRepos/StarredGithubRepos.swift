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
import Foundation

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

    // MARK: Local cache

    /*
     * Use NSUserDefaults
     */
    /*
    static let LastSearchedUserNameUserDefaultsKey = "tw.sodas.StarRepos.last-searched-user-name"
    static var lastSearchedUserName: String? {
        get {
            return NSUserDefaults.standardUserDefaults()
                .stringForKey(StarredGithubRepoCollection.LastSearchedUserNameUserDefaultsKey)
        }
        set(newValue) {
            NSUserDefaults.standardUserDefaults().setObject(newValue,
                forKey: StarredGithubRepoCollection.LastSearchedUserNameUserDefaultsKey)
        }
    }
     */

    /*
     * Use File system
     */
    static var lastSearchedUserNameStoragePath: String {
        // Get library path
        let libPath = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true).first!
        // Check existence
        if !NSFileManager.defaultManager().fileExistsAtPath(libPath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(libPath,
                                                                         withIntermediateDirectories: true,
                                                                         attributes: nil)
            } catch {
                NSLog("Cannot create library folder for user ...")
                fatalError()
            }
        }
        return (libPath as NSString).stringByAppendingPathComponent("last-searched-user-name.txt")
    }
    static var lastSearchedUserName: String? {
        get {
            do {
                return try NSString(contentsOfFile: StarredGithubRepoCollection.lastSearchedUserNameStoragePath,
                                    encoding: NSUTF8StringEncoding) as String?
            } catch {
                return nil
            }
        }
        set(newValue) {
            do {
                try newValue?.writeToFile(StarredGithubRepoCollection.lastSearchedUserNameStoragePath,
                                          atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
            }
        }
    }

}
