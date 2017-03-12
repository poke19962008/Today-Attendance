//
//  ViewController.swift
//  Attendance
//
//  Created by Sayan Das on 10/03/17.
//  Copyright © 2017 Sayan Das. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let urlRoot = URL(string: "192.168.1.3:60000/")
    
    let groupDefaults = UserDefaults.init(suiteName: "group.TodayAccessTokenDefault")

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var accessToken: UITextField!
    @IBOutlet weak var loggedUser: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if(groupDefaults?.string(forKey: "Username") != nil) {
            loggedUser.isHidden = false
            loggedUser.text = "Logged in as "+(groupDefaults?.string(forKey: "Username"))!
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func submit(_ sender: Any) {
        let headers: [String: String] = [
            "Authorization": "Basic c2F5YW5fZGFzQHNybXVuaXYuZWR1LmluOmRwc2gyMDAwMDExMjIwMTE=",
            "Username": username.text!,
            "Password": password.text!
        ]
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = headers
        
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: urlRoot!, completionHandler: networkCallback)
        
        task.resume()
    }
    
    func networkCallback(data: Data?, resp: URLResponse?, error: Error?) -> Void {
        if(error == nil) {
            let accessToken: String = String(data: data!, encoding: String.Encoding.utf8)!
            groupDefaults?.set(accessToken, forKey: "AccessToken")
            groupDefaults?.set(username.text, forKey: "Username")
            groupDefaults?.synchronize()
            
            loggedUser.isHidden = false
            loggedUser.text = "Logged in as "+username.text!
            
            print("[SUCCESS] Logged in")
            
        }else {
            print(error ?? "Error!")
        }
    }

}

