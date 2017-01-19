//
//  DriverSeeRequestViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/17/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit


class DriverSeeRequestViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var map: MKMapView!
    
    var acceptRide = false
    var offerActive = false
    var tokenCost = 0
    var tokenExchangeRate = 0.8
    
    var name : String = (PFUser.current()?.username!)! as String
    
    
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestUsername = ""
    
    var activityIndicator = UIActivityIndicatorView()
    
    func displayAlert(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    

    @IBOutlet weak var tokenChargeTextField: UITextField!
    
    func displayConfirm(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
            self.makeOffer()
            
            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    

    
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
    
    func makeOffer() {
    
        
        pauseApp()
        offerActive = true
        sendOfferOutlet.setTitle("Cancel Offer", for: [])
        tokenChargeTextField.isHidden = true
        driverBidLabel.text = "\(tokenChargeTextField.text!) tokens"
        driverBidLabel.isHidden = false
        
        
        
        
        /* Run heavy code in background thread. Still Learning about thread
         DispatchQueue.global(qos: .userInitiated).async(execute: {
         
         
         })
         */
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("username", equalTo: requestUsername)
        query.whereKey("rideEnded", equalTo: false)
        
        query.findObjectsInBackground { (objects, error) in
            
            if let riderRequests = objects {
                
                for riderRequest in riderRequests {
                    
                    if (riderRequest["driverResponses"] as? Int) != nil {
                        riderRequest.incrementKey("driverResponses", byAmount: 1)
                        riderRequest.saveInBackground()
                    }
                    
                    if (riderRequest["offerDriversList"] as? [String]) != nil {
                        
                        riderRequest.add((PFUser.current()?.username!)!, forKey: "offerDriversList")
                        riderRequest.saveInBackground()
                    }
                    
                    if (riderRequest["offerDriverBids"] as? [Int]) != nil {
                        riderRequest.add(Int(self.tokenChargeTextField.text!)!, forKey: "offerDriverBids")
                        
                        riderRequest.saveInBackground()
                    }
                    
                    // Add Driver Pic to RiderRequest
                    // Just learned cannot add PFFiles in an array. No worries though, will
                    // execute seperate query to retrieve it from Users class
                    
                }
                
                
                
                
            } else {
                
                self.displayAlert(title: "System Error", message: "Sorry about this. Please try again in a moment!")
            }
            
        }
        
        restoreApp()
        self.displayAlert(title: "Offer Sent!", message: "Please wait for your rider to respond!")
    
    }

    @IBAction func sendOfferButton(_ sender: Any) {
        
        if offerActive {
            pauseApp()
            // Driver canceled offer. Have to reset and delete their info from riderRequest.
            sendOfferOutlet.setTitle("Send Offer", for: [])
            
            tokenChargeTextField.text = ""
            tokenChargeTextField.isHidden = false
            driverBidLabel.isHidden = true
            driverBidLabel.text = ""
            offerActive = false
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: requestUsername)
            query.whereKey("rideEnded", equalTo: false)
            
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                        if var drivers = riderRequest["offerDriversList"] as? [String] {
                            let driverIndex = drivers.index(of: self.name)
                            print(driverIndex!)
                            drivers.remove(at: driverIndex!)
                            riderRequest["offerDriversList"] = drivers
                            if (riderRequest["driverResponses"] as? Int) != nil {
                                riderRequest.incrementKey("driverResponses", byAmount: -1)
                            }
                            if var bids = riderRequest["offerDriverBids"] as? [Int] {
                                bids.remove(at: driverIndex!)
                                riderRequest["offerDriverBids"] = bids
                               
                            }

                            
                        
                        }
                        
                        riderRequest.saveInBackground()
                        
                       
                    }
                }
                self.displayAlert(title: "Offer Canceled.", message: "Your Offer to \(self.requestUsername) has been canceled.")
            })
            restoreApp()
        } else {
            // Rider must enter valid whole number amounts in token field
        if tokenChargeTextField.text! == "" || Int(tokenChargeTextField.text!) == nil {
            displayAlert(title: "Token Bid Field Error", message: "Please enter a valid token charge in the field below!")
        } else {
            }
        
            displayConfirm(title: "PickMeUp Offer Pending", message: "Please make sure all PickmeUp details are understood, your token bid is accurate, and you are ready to pick your rider up at the specified time and location if they accept!")
        
        }
        
         //restoreApp()
    }
    @IBOutlet weak var riderUsernameLabel: UILabel!
    @IBOutlet weak var riderDestinationLabel: UILabel!
    @IBOutlet weak var riderPickUpTimeLabel: UILabel!
    @IBOutlet weak var driverBidLabel: UILabel!

    
    
   
    
    @IBOutlet weak var sendOfferOutlet: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        driverBidLabel.isHidden = true
        pauseApp()
        
        riderUsernameLabel.text = requestUsername
        
        self.tokenChargeTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpanMake(0.01, 0.01))
        
        map.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = requestLocation

        annotation.title = requestUsername
        
        map.addAnnotation(annotation)
        // Do any additional setup after loading the view.
        
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("username", equalTo: requestUsername)
        query.whereKey("rideEnded", equalTo: false)
        
        
        query.findObjectsInBackground(block: { (objects, error) in
            if let riderRequests = objects {
                for riderRequest in riderRequests {
                  var driverIndex = 0
                    if let drivers = riderRequest["offerDriversList"] as? [String] {
                        
                        if drivers.contains(self.name) {
                            self.offerActive = true
                            driverIndex = drivers.index(of: self.name)!
                            self.sendOfferOutlet.setTitle("Cancel Offer", for: [])
                            
                            self.tokenChargeTextField.isHidden = true
                            
                            if let tokenCharges = riderRequest["offerDriverBids"] as? [Int] {
                                self.tokenCost = tokenCharges[driverIndex]
                                self.driverBidLabel.text = "\(self.tokenCost) tokens ($\(Double(self.tokenCost)*0.8) for you.)"
                                self.driverBidLabel.isHidden = false
                                
                                
                            }
     
                        }
                        self.riderDestinationLabel.text = riderRequest["destination"] as! String?
                        
                        self.riderPickUpTimeLabel.text = riderRequest["pickUpTime"] as! String?

                        self.riderDestinationLabel.isHidden = false
                        self.riderPickUpTimeLabel.isHidden = false
                    }
                    
                    
                
                    
                    if let driver = riderRequest["driver"] as? String {
                        
                        // PUSH NOTIFY
                        /*
                            if let reachedRider = riderRequest["reachedRider"] as? Bool {
                            if driver == self.name && reachedRider == false {
                                
                                // Have the driver find the rider
                                 
                                 let requestCLLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                                 
                                 CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) in
                                 
                                 if let placemarks = placemarks {
                                 
                                 if placemarks.count > 0 {
                                 
                                 let mKPlacemark = MKPlacemark(placemark: placemarks[0])
                                 
                                 let mapItem = MKMapItem(placemark: mKPlacemark)
                                 
                                 mapItem.name = self.requestUsername
                                 
                                 let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                                 
                                 mapItem.openInMaps(launchOptions: launchOptions)
                                 
                                 
                                 
                                 }
                                 
                                 
                                 }
                                 
                                 })
     

                                
                            }
                        
                    }
                        */
                }
                
                
                }
                
                }
        })
        
         restoreApp()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
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
        
            }
 

}
