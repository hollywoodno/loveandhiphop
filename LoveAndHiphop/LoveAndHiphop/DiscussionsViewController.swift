//
//  SecondViewController.swift
//  LoveAndHiphop
//
//  Created by Mogulla, Naveen on 4/25/17.
//  Copyright © 2017 Mogulla, Naveen. All rights reserved.
//

import UIKit
import Parse

class DiscussionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ComposeCellDelegate, UITextFieldDelegate {
  
  // MARK: Properties
  @IBOutlet var tableView: UITableView!
  var messages: [PFObject]?
  
  // MARK: ViewDidLoad
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // LOG ME IN (This is only here temporarily to allow posting to discussions
    PFUser.logInWithUsername(inBackground: "hollywoodno", password: "password") { (user: PFUser?, error: Error?) in
      if user != nil {
      } else {
        print("Error logging hollywoodno in, error: \(error?.localizedDescription)")
      }
    }
    
    // MARK: Set Up TableView
    tableView.dataSource = self
    tableView.estimatedRowHeight = 100
    tableView.rowHeight = UITableViewAutomaticDimension
    
    // Tap on navigation bar to dismiss composing a message (consider proper place to put this)
    let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
    self.navigationController?.navigationBar.addGestureRecognizer(tap)
    
    // MARK: Fetch Messages From Parse
    let query = PFQuery(className: "Message")
    query.order(byDescending: "createdAt")
    query.findObjectsInBackground { (messages: [PFObject]?, error: Error?) in
      if error == nil {
        self.messages = messages
        self.tableView.reloadData()
      } else {
        print("Error getting messages from Parse, error: \(error?.localizedDescription)")
      }
    }
    
    // MARK: Set Up Refresh Data
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refreshControlAction), for: UIControlEvents.valueChanged)
    tableView.insertSubview(refreshControl, at: 0)
    
  }
  
  // Currently there are two sections.
  // Section 0 is for composing a message, Section 1 are messages returned from Parse.
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "ComposeCell", for: indexPath) as! ComposeCell
      cell.delegate = self
      return cell
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
    cell.message = messages?[indexPath.row]
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    }
    
    return messages?.count ?? 0
  }
  
  func refreshControlAction(_ refreshControl: UIRefreshControl) {
    
    // Query Parse for latest chat messages
    let query = PFQuery(className: "Message")
    query.order(byDescending: "createdAt")
    
    query.findObjectsInBackground { (messages: [PFObject]?, error: Error?) in
      if error == nil {
        self.messages = messages!
        self.tableView.reloadData()
        
        // Tell the refreshControl to stop spinning
        refreshControl.endRefreshing()
      } else {
        print("Error retrieving new messages from Parse, error: \(error?.localizedDescription)")
      }
    }
  }
  
  // Compose cell alerting that user wants to send a message
  func ComposeCell(composeCell: ComposeCell, didTapSend value: Bool) {
    if let text = composeCell.composeText.text {
      if text != "" {
        // Save message to parse
        let newMessage = PFObject(className: "Message")
        newMessage["text"] = text
        newMessage.saveInBackground(block: { (success: Bool, error: Error?) in
          if success {
            // Reset text field and hide keyboard
            composeCell.composeText.text = ""
            composeCell.composeText.resignFirstResponder()
            
            // Update UI to include new message
            self.messages?.insert(newMessage, at: 0)
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
            self.tableView.endUpdates()
            
          } else {
            print("Error saving message to parse, error: \(error?.localizedDescription)")
          }
        })
      }
    }
  }
  
  func onTap(_ sender: UITapGestureRecognizer) {
    self.view.endEditing(true)
  }
  
  
  /* TODO:
   
   a. Handle composed text better before sending to Parse
   func textFieldDidEndEditing(_ textField: UITextField) {
   view.endEditing(true)
   
   b. Add timer to refresh new messages as Parse is not real time
   
   c. Pin compose text field to top on scroll or use a custom chat UI.
   } 
   
   d. Add loading messaging view
   
  */
  
}
