//
//  DriverPreferencesViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/22/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse

class DriverPreferencesViewController: UIViewController {

    @IBOutlet weak var driverAcceptOfferOutlet: UISwitch!
    @IBOutlet weak var driverDeclineOfferOutlet: UISwitch!

    @IBOutlet weak var tokenDealsOutlet: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "fromDriverPreferencesSegue" {
            
            let query = PFQuery(className: "Users")
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let profiles = objects {
                    
                    for profile in profiles {
                        
                        profile["notifyDriverOffer"] = self.driverAcceptOfferOutlet.isOn
                        
                        profile["notifyRiderCancelOffer"] = self.driverDeclineOfferOutlet.isOn
                        
                        profile["notifyTokenDeals"] = self.tokenDealsOutlet.isOn
                        
                        profile.saveInBackground()
                        print("yayboi")
                        
                    }
                    
                }
                
            })
            
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
