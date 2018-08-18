//
//  ViewController.swift
//  WebSocketsChat
//
//  Created by Bogdan Nikolaev on 17.08.2018.
//  Copyright © 2018 Bogdan Nikolaev. All rights reserved.
//

import UIKit

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tblUserList: UITableView!
    
    
    var users = [[String: AnyObject]]()
    
    var nickname: String!
    
    var configurationOK = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                NotificationCenter.default.addObserver(self, selector: #selector(handleDisconnectedUserUpdateNotification(notification:)), name: Notification.Name(rawValue: "userWasDisconnectedNotification"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        if !configurationOK {
            configureNavigationBar()
            configureTableView()
            configurationOK = true
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if nickname == nil {
            askForNickname()
        }
    }
    
    @objc func handleDisconnectedUserUpdateNotification(notification: Notification) {
        let disconnectedUserNickname = notification.object as! String
        var index: Int = 0
        for item in users {
            if (item["nickname"] as? String) == disconnectedUserNickname {
                break
            }
            index += 1
        }
        var newArray = users
        newArray[index]["isConnected"] = false as AnyObject
        users.removeAll()
        users = newArray
        self.tblUserList.reloadData()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "idSegueJoinChat" {
                let chatViewController = segue.destination as! ChatViewController
                chatViewController.nickname = nickname
            }
        }
    }
    
    
    // MARK: IBAction Methods
    
    @IBAction func exitChat(sender: Any?) {
        SocketIOManager.sharedInstance.exitChatWithNickname(nickname: nickname) { () -> Void in
            DispatchQueue.main.async {
                self.nickname = nil
                //self.users.removeAll()
                self.tblUserList.isHidden = true
                self.askForNickname()
            }
        }
    }
    
    
    
    // MARK: Custom Methods
    
    func configureNavigationBar() {
        navigationItem.title = "SocketChat"
    }
    
    
    func configureTableView() {
        tblUserList.delegate = self
        tblUserList.dataSource = self
        tblUserList.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "idCellUser")
        tblUserList.isHidden = true
        tblUserList.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func askForNickname() {
        let alertController = UIAlertController(title: "SocketChat", message: "Please enter a nickname:", preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addTextField(configurationHandler: nil)
        
        let OKAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action) -> Void in
            guard let textfield = alertController.textFields?[0] else {
                return
            }
            if (textfield.text?.isEmpty)! {
                self.askForNickname()
            }
            else {
                self.nickname = textfield.text
                
                SocketIOManager.sharedInstance.connectToServerWithNickname(nickname: self.nickname, completionHandler: { (userList) -> Void in
                    DispatchQueue.main.async {
                        if !userList.isEmpty {
                            self.users = userList
                            self.tblUserList.reloadData()
                            self.tblUserList.isHidden = false
                        }
                    }
                })
            }
        }
        
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: UITableView Delegate and Datasource methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellUser", for: indexPath) as! UserCell
        
        cell.textLabel?.text = users[indexPath.row]["nickname"] as? String
        cell.detailTextLabel?.text = (users[indexPath.row]["isConnected"] as! Bool) ? "Online" : "Offline"
        cell.detailTextLabel?.textColor = (users[indexPath.row]["isConnected"] as! Bool) ? UIColor.green : UIColor.red
        
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
}
