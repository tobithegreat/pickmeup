//
//  RiderPickMeUpViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/25/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit
import CoreLocation

class RiderPickMeUpViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()
    var reachedRider = false
    var destination = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var riderLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var driverLoc = PFGeoPoint(latitude: 0, longitude: 0)
    
    // Walmart Location: Latitude:42.664442° Longitude:-73.11068°
    let walmartLocation = CLLocationCoordinate2D(latitude: 42.664442, longitude: -73.11068)
    
    let pittsFieldBusStationLocation = CLLocationCoordinate2D(latitude: 42.451416, longitude: -73.253956)
    
    let williamsCollegeLocation = CLLocationCoordinate2D(latitude: 42.712804, longitude: -73.203021)
    
    // Pittsfield Bus Station Location: Latitude:42.451416° Longitude:-73.253956°
    
    // Williams College Location: Latitude:42.712804° Longitude:-73.203021°
    
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var driverDistanceLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()


        // Do any additional setup after loading the view.
    }
    
    func displayAlert(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    var activityIndicator = UIActivityIndicatorView()
    
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

    
    // For picking up rider
    
    func displayConfirm(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            self.pauseApp()
            self.reachedRider = true
            
            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Decline", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    // For Arriving at Destination
    func displayConfirm2(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            
            let riderQuery = PFQuery(className: "RiderRequest")
            
            riderQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
            riderQuery.whereKey("rideEnded", equalTo: false)
            //cancelQuery.whereKey("rideCanceled", notEqualTo: true)
            
            riderQuery.findObjectsInBackground(block: { (objects, error) in
                
                if let objects = objects {
                    for object in objects {
                        object["rideCompleted"] = true
                        object["rideEnded"] = true
                        object.saveInBackground()
                    }
                    
                }
                
                
            })

            let clearQuery = PFQuery(className: "PickMeUpRideSession")
            
            clearQuery.whereKey("rider", equalTo: (PFUser.current()?.username)!)
            
            //cancelQuery.whereKey("rideCanceled", notEqualTo: true)
            
            riderQuery.findObjectsInBackground(block: { (objects, error) in
                
                if let objects = objects {
                    for object in objects {
                        object.deleteInBackground()
                    }
                    
                }
                
                
            })

            self.performSegue(withIdentifier: "endRideSegue", sender: self)
            
            

            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Decline", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    func displayCancel(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            self.pauseApp()
            let cancelQuery = PFQuery(className: "PickMeUpRideSession")
            
            cancelQuery.whereKey("rider", equalTo: (PFUser.current()?.username)!)
            //cancelQuery.whereKey("rideCanceled", notEqualTo: true)
            
            cancelQuery.findObjectsInBackground(block: { (objects, error) in
                
                if let objects = objects {
                print("casted")
                    for object in objects {
                    object["riderCanceled"] = true
                    object.saveInBackground()
                    
                    }
                
                }
                
                
            })
            
            let riderQuery = PFQuery(className: "RiderRequest")
            
            riderQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
            riderQuery.whereKey("rideEnded", equalTo: false)
            //cancelQuery.whereKey("rideCanceled", notEqualTo: true)
            
            riderQuery.findObjectsInBackground(block: { (objects, error) in
                
                if let objects = objects {
                    print("casted")
                    for object in objects {
                        object["rideEnded"] = true
                        object.saveInBackground()
                    }
                    
                }
                
                
            })
            self.restoreApp()
            self.performSegue(withIdentifier: "endRideSegue", sender: self)

            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    @IBAction func cancelRide(_ sender: Any) {
        displayCancel(title: "Sure You Want To Cancel Ride?", message: "Please communicate with your driver if there are any issues first. Do you want to cancel your PickMeUp?")
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if PFUser.current()?.username != nil {
            if let location = manager.location?.coordinate {
                riderLocation = location
                let region = MKCoordinateRegion(center: riderLocation, span: MKCoordinateSpanMake(0.01, 0.01))
                
                self.map.setRegion(region, animated: true)
                
                self.map.removeAnnotations(self.map.annotations)
                
                let annotation = MKPointAnnotation()
                
                
                annotation.coordinate = riderLocation
                annotation.title = "Your Location"
                
                self.map.addAnnotation(annotation)
                
                
                let reachedQuery = PFQuery(className: "RiderRequest")
                reachedQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
                reachedQuery.whereKey("rideEnded", equalTo: false)
                
                reachedQuery.findObjectsInBackground(block: { (objects, error) in
                    
                    if let objects = objects {
                    
                        for object in objects {
                        
                            if let reached = object["reachedRider"] as? Bool {
                            
                                object["reachedRider"] = self.reachedRider
                                
                                if let destinationRider = object["destination"] as? String {
                                
                                    if destinationRider == "Pittsfield Bus Station" {
                                        self.destination = self.pittsFieldBusStationLocation
                                        
                                    } else if destinationRider == "Walmart" {
                                        self.destination = self.walmartLocation
                                    
                                    } else if destinationRider == "Williams College" {
                                    
                                        self.destination = self.williamsCollegeLocation
                                    
                                    }
                                
                                
                                }
                                if self.driverLoc.latitude != 0 && self.riderLocation.latitude != 0 && reached == false {
                                    
                                    //print(abs(self.riderLocation.latitude - self.driverLoc.latitude))
                                    //print(abs(self.riderLocation.longitude - self.driverLoc.longitude))
                                    if abs(self.riderLocation.latitude - self.driverLoc.latitude) <= 0.0002 && abs(self.riderLocation.longitude - self.driverLoc.longitude) <= 0.0002 {
                                        
                                        self.displayConfirm(title: "Has Your PickMeUp Arrived?", message: "It appears that your driver is either nearby, or has picked you up already. If so, please confirm to navigate to your destination. If they're not there yet, please decline.")
                                    
                                    }
                                
                                }
                            }
                        
                        object.saveInBackground()
                        }
                    
                    }
                    
                })

                
                let query = PFQuery(className: "PickMeUpRideSession")
                query.whereKey("rider", equalTo: (PFUser.current()?.username)!)
                //query.whereKey("rideCanceled", notEqualTo: true)
                
                query.findObjectsInBackground(block: { (objects, error) in
                    
                    if let objects = objects {
                        print("Got his location")
                        for object in objects {
                            print("Found")
                        
                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                if self.reachedRider {
                                // GO to destination now
                                    
                                    let riderCLLocation = CLLocation(latitude: self.riderLocation.latitude, longitude: self.riderLocation.longitude)
                                    
                                    let destinationCLLocation = CLLocation(latitude: self.destination.latitude, longitude: self.destination.longitude)
                                    
                                    let distance = riderCLLocation.distance(from: destinationCLLocation) / 1000
                                    
                                    let roundedDistance = round(distance * 100) / 100
                                    
                                    self.driverDistanceLabel.text = "Your destination is \(roundedDistance) km away!"
                                    
                                    let latDelta = abs(self.destination.latitude - self.riderLocation.latitude) * 2 + 0.005
                                    
                                    let lonDelta = abs(self.destination.longitude - self.riderLocation.longitude) * 2 + 0.005
                                    
                                    let region = MKCoordinateRegion(center: self.riderLocation, span: MKCoordinateSpanMake(latDelta, lonDelta))
                                    
                                    self.map.setRegion(region, animated: true)
                                    
                                    let riderLocationAnnotation = MKPointAnnotation()
                                    
                                    riderLocationAnnotation.coordinate = self.riderLocation
                                    
                                    riderLocationAnnotation.title = "Your Location"
                                    
                                    self.map.addAnnotation(riderLocationAnnotation)
                                    
                                    let destinationLocationAnnotation = MKPointAnnotation()
                                    
                                    destinationLocationAnnotation.coordinate = CLLocationCoordinate2D(latitude: self.destination.latitude, longitude: self.destination.longitude)
                                    destinationLocationAnnotation.title = "Your Destination"
                                    
                                    self.map.addAnnotation(destinationLocationAnnotation)
                                    
                                    self.restoreApp()
                                    
                                    // Find out if near the destination
                                    
                                    if self.riderLocation.latitude != 0 && self.riderLocation.longitude != 0 && self.reachedRider == true {
                                        
                                        
                                        if abs(self.riderLocation.latitude - self.destination.latitude) <= 0.0002 && abs(self.riderLocation.longitude - self.destination.longitude) <= 0.0002 {
                                            
                                            self.displayConfirm2(title: "Have You Arrived At Your Destination Yet?", message: "It appears that your destination is either nearby, or you have already arrived. If so, please confirm to end your trip. If not, please decline.")
                                            
                                        }
                                        
                                    }

                                    
                                
                                } else {
                            
                                    // Go to Rider now
                                
                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                
                                self.driverLoc = driverLocation
                                let riderCLLocation = CLLocation(latitude: self.riderLocation.latitude, longitude: self.riderLocation.longitude)
                                
                                let distance = riderCLLocation.distance(from: driverCLLocation) / 1000
                                
                                let roundedDistance = round(distance * 100) / 100
                                
                                self.driverDistanceLabel.text = "Your Driver is \(roundedDistance) km away!"
                            
                                let latDelta = abs(driverLocation.latitude - self.riderLocation.latitude) * 2 + 0.005
                                
                                let lonDelta = abs(driverLocation.longitude - self.riderLocation.longitude) * 2 + 0.005
                                
                                let region = MKCoordinateRegion(center: self.riderLocation, span: MKCoordinateSpanMake(latDelta, lonDelta))
                                
                                self.map.setRegion(region, animated: true)
                                
                                let riderLocationAnnotation = MKPointAnnotation()
                                
                                riderLocationAnnotation.coordinate = self.riderLocation
                                
                                riderLocationAnnotation.title = "Your Location"
                                
                                self.map.addAnnotation(riderLocationAnnotation)
                                
                                let driverLocationAnnotation = MKPointAnnotation()
                                
                                driverLocationAnnotation.coordinate = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                driverLocationAnnotation.title = "Your Driver's Location"
                                
                                self.map.addAnnotation(driverLocationAnnotation)


                                }
                            }
                        }
                    
                    } else {
                        print("Please wait for driver to begin their trip to you!")
                    
                    }
                    
                })
                
            
            }
            
        }
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
        
        if segue.identifier == "endRideSegue" {
            self.navigationController?.navigationBar.isHidden = true
            locationManager.stopUpdatingLocation()
            PFUser.logOut()

            
            
        } else if segue.identifier == "rideToProfileSegue" {
        
            self.navigationController?.navigationBar.isHidden = true
            locationManager.stopUpdatingLocation()
        
        }
    }
    

}
