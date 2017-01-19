//
//  RiderViewOfferViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/20/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse


class RiderViewOfferViewController: UIViewController {
    
    var driver = ""
    var tokenCharge = 0
    var riderTokens = 0
    var activityIndicator = UIActivityIndicatorView()
    
    func displayConfirm(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
            self.pickMeUpAccepted()
            
            
            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    func displayAlert(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }

    @IBOutlet weak var acceptOrViewOutlet: UIButton!
    @IBOutlet weak var driverName: UILabel!
    @IBOutlet weak var driverClassYear: UILabel!
    @IBOutlet weak var driverUnix: UILabel!
    @IBOutlet weak var driverNumber: UILabel!
    
    @IBAction func acceptOffer(_ sender: Any) {
        if acceptOrViewOutlet.titleLabel?.text == "Accept Offer" {
            
            if riderTokens < tokenCharge {
                displayAlert(title: "Not Enough Tokens!", message: "Your driver is charging \(tokenCharge) tokens, but you currently have \(riderTokens) tokens. If you would like to purchase more tokens, please visit the Help Center in the profile page.")
            } else {
            displayConfirm(title: "Ready to Accept?", message: "Please make sure all details of your PickmeUp offer are understood, and you'll be ready for your driver!")
            }
            
        } else {
        
            self.performSegue(withIdentifier: "goToRiderPickMeUp", sender: self)

        
        }
    }
    
    func pickMeUpAccepted() {
        
        
    
        //Make this driver the designated one. Also hides this request from popping up on other driver screens. I don't want to delete the entire riderRequest object, better to save for records.
        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        query.findObjectsInBackground { (objects, error) in
            
            if let error = error {
                // Sign Up Error, likely no Internet access
                var displayedErrorMessage = "Sorry, there seems to be an error siging you up now. Please try again later."
                
                if let parseError = (error as NSError).userInfo["error"] as? String {
                    
                    displayedErrorMessage = parseError
                }
                
                self.displayAlert(title: "Accepting Offer Failed", message: displayedErrorMessage)
                
            } else if let objects = objects {
            
                for object in objects {
                    if object["driver"] as? String == "" {
                        
                    
                    object["driver"] = self.driver
                    object["requestAccepted"] = true
                    object["reachedRider"] = false
                    object["reachedDestination"] = false
                    object.saveInBackground()
                        
                    
                    self.performSegue(withIdentifier: "goToRiderPickMeUp", sender: self)
                    }
                
                }
            
            }
        }
        
        
        let riderTokenQuery = PFQuery(className: "Users")
        riderTokenQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        riderTokenQuery.findObjectsInBackground { (objects, error) in
            
            if let objects = objects {
            
                for object in objects {
                
                    if let tokens = object["tokens"] as? Int {
                
                        let minusTokens = self.tokenCharge
                        print("Token Charge is \(self.tokenCharge)")
                        self.riderTokens -= minusTokens
                        object["tokens"] = self.riderTokens
                        
                    
                    }
                    object.saveInBackground()
                }
                
            
            }
            
        }
        
        
        let driverTokenQuery = PFQuery(className: "Users")
        driverTokenQuery.whereKey("username", equalTo: driver)
        print(driver)
        driverTokenQuery.findObjectsInBackground { (objects, error) in
            
            if let objects = objects {
                
                for object in objects {
                    
                    if var tokensCount = object["tokens"] as? Int {
                        var newTokensCount = tokensCount
                        newTokensCount += self.tokenCharge
                        print("Driver now has \(newTokensCount)")
                        object["tokens"] = newTokensCount
                        
                    }
                    object.saveInBackground()
                }
                
                
            }
            
        }
        
    }
    
    @IBOutlet weak var profilePic: UIImageView!
    func pauseApp() {
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        activityIndicator.center = self.view.center
        
        activityIndicator.hidesWhenStopped = true
        
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        
        view.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func restoreApp() {
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            // Your code with delay
            
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
        
    }

    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pauseApp()
        
        
        let query = PFQuery(className: "Users")
        query.whereKey("username", equalTo: driver)
        
        query.findObjectsInBackground { (objects, error) in
            
            if let objects = objects {
            print(self.driver)
                for object in objects {
                print("a")
                    if let profPic = object["profilePic"] as? PFFile {
                    print("i")
                        profPic.getDataInBackground(block: { (imageData, error) in
                            
                            if error == nil {
                            print("l")
                                let image = UIImage(data: imageData!)
                                self.profilePic.image = image
                                print("e")
                            } else {
                            
                                print("Failed")
                            }
                            
                        })
                        
                    }
                    
                    self.driverName.text = object["fullName"] as? String
                    self.driverClassYear.text = object["classYear"] as? String
                    self.driverNumber.text = object["contactNum"] as? String
                    self.driverUnix.text = object["unix"] as? String
                    
                    
                    
                
                }
            
            }
            
        }
        
        let rideQuery = PFQuery(className: "RiderRequest")
        rideQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
        rideQuery.whereKey("rideEnded", equalTo: false)
        
        rideQuery.findObjectsInBackground { (objects, error) in
            
            if let objects = objects {
            
                for object in objects {
                
                    if object["driver"] as? String != "" {
                    
                       self.acceptOrViewOutlet.setTitle("View PickMeUp Progress", for: [])
                        
                    
                    }
                    
                    print(object["rideEnded"])
                
                }
                
            }
            
        }
        
        
        let riderTokenQuery = PFQuery(className: "Users")
        riderTokenQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        riderTokenQuery.findObjectsInBackground { (objects, error) in
            
            if let objects = objects {
            
                for object in objects {
                
                    self.riderTokens = object["tokens"] as! Int
                    print("riderTokens is \(self.riderTokens)")
                    print("Cost of ride is \(self.tokenCharge)")
                }
            
            }
            
        }

        

        // Do any additional setup after loading the view.
        restoreApp()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "goToRiderPickMeUp" {
        
            if let destination = segue.destination as? RiderPickMeUpViewController {
            
                destination.navigationController?.navigationBar.isHidden = true
            
            }
        
        }
    }
 

}
