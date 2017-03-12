//
//  TodayViewController.swift
//  Today Attendance
//
//  Created by Sayan Das on 10/03/17.
//  Copyright © 2017 Sayan Das. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegate {
    
//    Global Configs
    let timerInterval: Double = 3*60*60
    let urlRoot: String = "http://192.168.1.3:60000" // Bind with external IP
    var accessToken: String = "<ACCESS-TOKEN>"
    
    var timer: Timer?
    let defaults = UserDefaults.standard
    let groupDefaults = UserDefaults.init(suiteName: "group.TodayAccessTokenDefault")
    let reuseIdentifier = "Cell"
    var items = [Array<String>]()
    let subMap: [String:String] = [  // To avoid text overflow
        "IC1053": "Control System",
        "MA1006A": "Maths",
        "CS1014": "Compiler",
        "CS1036": "Lab",
        "MB1209": "Entrepreneurship",
        "CS1114": "Pattern Recog.",
        "CS1012": "Software"
    ]
    
    @IBOutlet weak var CollectionView: UICollectionView!
    @IBOutlet weak var updateTime: UILabel!
    @IBOutlet weak var loader: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        // If user has logged in from app
        if(groupDefaults?.string(forKey: "AccessToken") != nil) {
            accessToken = (groupDefaults?.string(forKey: "AccessToken"))!
            
            // Expand view and check data existence
            self.extensionContext?.widgetLargestAvailableDisplayMode = NCWidgetDisplayMode.expanded
            if(self.items.count == 0) {
                CollectionView.isHidden = true
                loader.isHidden = false
            }else {
                CollectionView.isHidden = false
                loader.isHidden = true
            }
            
            // Refresh at every timerInterval
            timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(TodayViewController.fetchDetails), userInfo: nil, repeats: true)
            self.fetchDetails()
        }else {
            loader.text = "Access Token not found"
            print("[FAIL] Access Token not Found")
        }
    }
    
    // Adjust extension height
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if (activeDisplayMode == NCWidgetDisplayMode.compact) {
            self.preferredContentSize = maxSize
        }
        else {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 255)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath)
        
        let subCode = cell.viewWithTag(3) as! UILabel
        subCode.text =  items[indexPath.row][0] as String
        subCode.text = String(subCode.text!.characters.dropLast(7))
        
        let subName = cell.viewWithTag(2) as! UILabel
        subName.text = (self.subMap[subCode.text!] != nil) ? self.subMap[subCode.text!]!: items[indexPath.row][1]
        
        let attn = cell.viewWithTag(1) as! UILabel
        attn.text = (items[indexPath.row][8] as String) + "%"
        
        return cell
    }
    
    
    // API Call Method
    func fetchDetails() {
        let url = URL(string: urlRoot+"/attendance/"+accessToken)
        
        let session = URLSession.shared
        let task = session.dataTask(with: url!, completionHandler: fetchDetailsCB)
        task.resume()
        
    }
    
    // API Call CallBack
    func fetchDetailsCB(data: Data?, resp: URLResponse?, error: Error?) -> Void {
        if (error == nil) {
            do {
                let data = try JSONSerialization.jsonObject(with: data!, options:[])
                DispatchQueue.main.async() {
                    self.items = data as! [Array<String>]
                    self.items.remove(at: 0) // First element is irrelevant
                    self.loader.isHidden = true
                    self.CollectionView.isHidden = false
                    self.CollectionView.reloadData()
                    
                    let format = DateFormatter()
                    format.dateFormat = "MMM d, h:mm a"
                    let time = format.string(from: Date())
                    self.updateTime.text = "Last updated: " + time + " | RefreshCycles: 3Hr."
                    
                    self.saveDefaults(data: self.items, time: time )
                    
                    print("Item Loaded." + " | Time: "+time)
                }
            }
            catch {
                print("Error Serializing JSON")
            }
            
        }else {
            print("Failed Request. | Fetching Defaults")
            let defaults = fetchDefaults()
            
            DispatchQueue.main.async() {
                self.items = defaults.0
                self.loader.isHidden = true
                self.CollectionView.isHidden = false
                self.CollectionView.reloadData()
                
                let time = defaults.1
                self.updateTime.text = "Last updated: " + time + " | RefreshCycles: 3Hr."
            }
        }
    }
    
    func saveDefaults(data: [Array<String>], time: String) {
        defaults.set(data, forKey: "attendance")
        defaults.setValue(time, forKey: "lastUpdate")
    }
    
    func fetchDefaults() -> ([Array<String>], String) {
        let attn = defaults.array(forKey: "attendance") as! [Array<String>]
        let lUpd = defaults.string(forKey: "lastUpdate")
        
        return (attn, lUpd!)
    }
    
}
