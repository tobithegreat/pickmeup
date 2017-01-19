//
//  RiderOrderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/15/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderOrderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    var locationManager = CLLocationManager()
    
    var rideRequestActive = false
    
    var activityIndicator = UIActivityIndicatorView()
    
    var destinationPickerData = [String]()
    
    
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @IBOutlet weak var map: MKMapView!
    @IBAction func detailButton(_ sender: Any) {
        displayAlert(title: "What does \"When\" Mean?", message: "This is the amount of time you will need to get ready, once you accept a PickMeUp offer.")
    }
    
    @IBOutlet weak var detailButtonOutlet: UIButton!
 
    @IBOutlet weak var destinationPicker: UIPickerView!
    @IBOutlet weak var viewRideOffersOutlet: UIButton!
    
    func displayAlert(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    
    func displayConfirm(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
            self.call()
            
            
        }))
            
        alertcontroller.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    
    
    func hideInputs() {
        self.callButtonOutlet.setTitle("Cancel PickMeUp", for: [])
        destinationLabel.isHidden = true
        destinationPicker.isHidden = true
        timeLabel.isHidden = true
        rideTimeSelection.isHidden = true
        detailButtonOutlet.isHidden = true
    
    }
    
    func showInputs() {
        self.callButtonOutlet.setTitle("Order PickMeUp", for: [])
        destinationLabel.isHidden = false
        destinationPicker.isHidden = false
        timeLabel.isHidden = false
        rideTimeSelection.isHidden = false
        detailButtonOutlet.isHidden = false
        
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
    
    func call() {
        rideRequestActive = true
        hideInputs()
        
        
        let riderRequest = PFObject(className: "RiderRequest")
        
        riderRequest["username"] = PFUser.current()?.username
        
        riderRequest["destination"] = destinationLabel.text
        riderRequest["pickUpTime"] = rideTimeSelection.titleForSegment(at: rideTimeSelection.selectedSegmentIndex)
        riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        riderRequest["driverResponses"] = 0
        
        riderRequest["requestAccepted"] = false
        
        riderRequest["driver"] = ""
        
        riderRequest["tokenCharge"] = 0
        
        riderRequest["offerDriversList"] = [String]()
        
        riderRequest["offerDriverBids"] = [Int]()
        
        riderRequest["notifyDriver"] = false
        
        riderRequest["rideEnded"] = false
        
        riderRequest["rideCompleted"] = false
        
        riderRequest["driverEnded"] = false
        
        
        
        
        
        // Was planning on also sending profile pictures to drivers. But, for privacy reasons, will wait till rider accepts.
        
        let acl = PFACL()
        
        acl.getPublicReadAccess = true
        acl.getPublicWriteAccess = true
        
        riderRequest.acl = acl
        
        riderRequest.saveInBackground(block: { (success, error) in
            
            if success {
                self.displayAlert(title: "Ordered a PickMeUp!", message: "Please wait for a driver to respond.")
                
                
                
            } else {
                // Saving their request to database failed.
                self.showInputs()
                self.rideRequestActive = false
                
                self.displayAlert(title: "Could Not Order PickMeUp", message: "Sorry, please try again later.")
                
            }
        })
    }

    @IBAction func callPickMeUp(_ sender: Any) {
        pauseApp()
        if rideRequestActive {
            // Check if request already submitted. If not, submit a new request.
            showInputs()
            rideRequestActive = false
            
            // First, delete all active requests this user has made on the server
            
            let query = PFQuery(className: "RiderRequest")
           
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            query.whereKey("driver", equalTo: "")
            query.whereKey("rideEnded", equalTo: false)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                
                    for riderRequest in riderRequests {
                        
                        riderRequest.deleteInBackground()
                        self.viewRideOffersOutlet.isHidden = true
                    }
                }
            })
            
        displayAlert(title: "PickMeUp Canceled", message: "Your ride has been canceled.")

        } else {
            
            if let pick = destinationLabel.text! as? String {
                print(destinationLabel.text)
                if pick == "Select Destination" {
                displayAlert(title: "No Destination Selected", message: "Please enter a destination.")
            
                }
             else if userLocation.latitude != 0 && userLocation.longitude != 0 {
                
                displayConfirm(title: "PickMeUp Order Ready", message: "Are you sure all details are correct?")
            
                }
            else {
                
                // Could not process user's current location
                displayAlert(title: "Could Not Order PickMeUp", message: "Cannot detect your location.")
        
                }
            }
        }
        
        restoreApp()
    }
    @IBOutlet weak var callButtonOutlet: UIButton!
    //@IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var rideTimeSelection: UISegmentedControl!
    @IBOutlet weak var timeLabel: UILabel!

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToRiderProfileViewController" {
            locationManager.stopUpdatingLocation()
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.destinationPicker.delegate = self
        self.destinationPicker.dataSource = self
        
        destinationPickerData = ["Select Destination", "Walmart", "Pittsfield Bus Station", "Williams College"]
        pauseApp()
        
         // Do any additional setup after loading the view.
        //self.destinationTextField.delegate = self
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        
        // Load up the user's location on Map
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
       
        viewRideOffersOutlet.isHidden = true
        
        callButtonOutlet.isHidden = true
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        query.whereKey("driver", equalTo: "")
        query.whereKey("rideEnded", equalTo: false)
        
        query.findObjectsInBackground(block: { (objects, error) in
            if let riderRequests = objects {
                if riderRequests.count != 0 {
                    print("ATTENTION")
                    self.rideRequestActive = true
                    self.hideInputs()
                }
                for riderRequest in riderRequests {
                // Check if any offers available
                    if let drivers = riderRequest["offerDriversList"] as? [String] {
                    
                        if drivers.count > 0 {
                        
                            self.viewRideOffersOutlet.isHidden = false
                            self.displayAlert(title: "Current Offers!", message: "Please view the current PickMeUp offers you have!")
                            
                            
                        }
                    
                    }
                    
                
                }
            }
            self.callButtonOutlet.isHidden = false
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

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if PFUser.current()?.username != nil {
            if let location = manager.location?.coordinate {
                
                userLocation = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                
                let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpanMake(0.01, 0.01))
                
                self.map.setRegion(region, animated: true)
                
                self.map.removeAnnotations(self.map.annotations)
                
                let annotation = MKPointAnnotation()
                
                annotation.coordinate = userLocation
                annotation.title = "Your Location"
                
                self.map.addAnnotation(annotation)
                
                let query = PFQuery(className: "RiderRequest")
                
                query.whereKey("username", equalTo: (PFUser.current()?.username)!)
                
                query.findObjectsInBackground(block: { (objects, error) in
                    
                    if let riderRequests = objects {
                        
                        for riderRequest in riderRequests {
                            
                            riderRequest["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                            riderRequest.saveInBackground()
                        }
                    }
                })

                
            
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return destinationPickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return destinationPickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        destinationLabel.text = destinationPickerData[row]
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
