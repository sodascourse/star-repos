//
//  StarredReposViewController.swift
//  StarRepos
//
//  Created by sodas on 5/2/16.
//  Copyright © 2016 sodas. All rights reserved.
//

import UIKit
import SafariServices

class StarredReposViewController: UITableViewController, UITextFieldDelegate {

    var repos: [GithubRepo] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    var repoCollection: StarredGithubRepoCollection? {
        didSet {
            // Check the existence of newRepos
            guard let repoCollection = self.repoCollection else {
                self.tableView.reloadData()
                return
            }
            // Ask the newRepos to fetch new data
            repoCollection.fetch { (resultRepos: [GithubRepo]?) in
                // Clear the loading indicator
                defer {
                    self.navigationItem.titleView = nil
                }
                // Check data
                guard let repos = resultRepos else {
                    // Prompt an alert
                    let message = "Failed to fetch starred repos for user: \(repoCollection.username)"
                    let alertController = UIAlertController(title: message, message: nil, preferredStyle: .Alert)
                    let alertOK = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alertController.addAction(alertOK)
                    self.presentViewController(alertController, animated: true, completion: nil)
                    // Bye
                    return
                }
                // Update data
                self.repos = repos
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.repos.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let githubRepo = self.repos[indexPath.row]

        cell.textLabel!.text = githubRepo.name
        cell.detailTextLabel!.text = githubRepo.owner

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let githubRepo = self.repos[indexPath.row]
        guard let url = NSURL(string: githubRepo.urlString) else { return }

        // Show detail web page with SFSafariViewController
        let safariViewController = SFSafariViewController(URL: url)
        safariViewController.title = "\(githubRepo.owner)/\(githubRepo.name)"
        self.showViewController(safariViewController, sender: nil)

        // Ask OS to open this URL (since this is a webpage URL, iOS opens it with Mobile Safari)
        /*
         * UIApplication.sharedApplication().openURL(url)
         */
    }

    // MARK: - Username search text field

    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var searchingIndicator: UIActivityIndicatorView!

    @IBAction func changeSearchUsername(sender: AnyObject) {
        // Set the title view to search text field
        self.navigationItem.titleView = self.searchTextField
        // Highlight the textfield
        self.searchTextField.becomeFirstResponder()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === self.searchTextField {
            // Reset the title view back
            self.navigationItem.titleView = nil
            // Update the title of this view controller and the model
            if let searchUsername = textField.text where textField.text?.characters.count > 0 {
                self.navigationItem.title = "Starred by \(searchUsername)"
                self.navigationItem.titleView = self.searchingIndicator
                self.repoCollection = StarredGithubRepoCollection(username: searchUsername)
            } else {
                self.navigationItem.title = "Starred Repos"
                self.repoCollection = nil
            }
        }
        return true
    }
}
