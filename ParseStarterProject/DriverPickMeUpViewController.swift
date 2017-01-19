//
//  DriverPickMeUpViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/24/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DriverPickMeUpViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var requestUsername = ""
    var name = ""
    var rideStarted = false
    var cancelRide = false
    var pickedUpRider = false
    var destination = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestLocation = CLLocationCoordinate2D()
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    // Walmart Location: Latitude:42.664442° Longitude:-73.11068°
    let walmartLocation = CLLocationCoordinate2D(latitude: 42.664442, longitude: -73.11068)
    
    let pittsFieldBusStationLocation = CLLocationCoordinate2D(latitude: 42.451416, longitude: -73.253956)
    
    let williamsCollegeLocation = CLLocationCoordinate2D(latitude: 42.712804, longitude: -73.203021)
    
    // Pittsfield Bus Station Location: Latitude:42.451416° Longitude:-73.253956°
    
    // Williams College Location: Latitude:42.712804° Longitude:-73.203021°

    
    override func viewDidLoad() {
        super.viewDidLoad()
        name = (PFUser.current()?.username)!
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
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if PFUser.current()?.username != nil {
            print("FIRST CHECK")
            if let location = manager.location?.coordinate {
                userLocation = location
                
            }
            
            if PFUser.current()?.username == nil {
                print("THIS SHOULD STOP NOW")
            }
            if PFUser.current()?.username != nil {
                print("USER IS  NOT NIL")
                if pickedUpRider == false {
                    let driverQuery = PFQuery(className: "PickMeUpRideSession")
                    driverQuery.whereKey("driver", equalTo: (PFUser.current()?.username)!)
                    //driverQuery.whereKey("rideCanceled", notEqualTo: true)
                    driverQuery.findObjectsInBackground(block: { (objects, error) in
                        
                        if let objects = objects {
                            if objects.count > 0 {
                           
                                for object in objects {
                                
                                    object["driverLocation"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                    let when = DispatchTime.now() + 0.7
                                    DispatchQueue.main.asyncAfter(deadline: when) {

                                    object.deleteInBackground()
                                    print("Deleting Now")
                                    }
                                    let cancelQuery = PFQuery(className: "RiderRequest")
                                    cancelQuery.whereKey("driver", equalTo: (PFUser.current()?.username)!)
                                    cancelQuery.whereKey("driverEnded", equalTo: false)
                                    cancelQuery.findObjectsInBackground(block: { (objects, error) in
                                        
                                        if let objects = objects {
                                        
                                            for object in objects {
                                            
                                                if object["rideEnded"] as? Bool == true {
                                                    self.cancelRide = true
                                                    self.displayAlert(title: "Ride Has Ended", message: "You can be logged  out now. Thanks!")
                                                    object["driverEnded"] = true
                                                    
                                                    object.saveInBackground()
                                                    //self.performSegue(withIdentifier: "logOutDriverFromPickMeUp", sender: self)
                                                    //self.locationManager.stopUpdatingLocation()
                                                    //PFUser.logOut()
                                                    
                                                }
                                            
                                            }
                                        
                                        }
                                        
                                    })
                                    
                                
                                }
                                
                                
                            
                            } else {
                                if self.cancelRide == false {
                                    let when = DispatchTime.now() + 1
                                    DispatchQueue.main.asyncAfter(deadline: when) {

                                    print("Creating session")
                                    let rideSession = PFObject(className: "PickMeUpRideSession")
                                    rideSession["driver"] = PFUser.current()?.username
                                    rideSession["rider"] = self.requestUsername
                                    rideSession["driverLocation"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                    //rideSession["rideCanceled"] = false
                                    rideSession["headingToDestination"] = self.pickedUpRider
                                    rideSession["riderCanceled"] = false
                                    
                                    let acl = PFACL()
                                    
                                    acl.getPublicReadAccess = true
                                    acl.getPublicWriteAccess = true
                                    
                                    rideSession.acl = acl
                                    rideSession.saveInBackground()
                                    print("Session made")
                                    self.rideStarted = true
                                
                                }
                                
                                }
                            }

                        }
                        
                      
                    
                        
                        
                    })
                    
                    let query = PFQuery(className: "RiderRequest")
                    
                    query.whereKey("username", equalTo: requestUsername)
                    
                    query.findObjectsInBackground(block: { (objects, error) in
                        
                        if let riderRequests = objects {
                            
                            for riderRequest in riderRequests {
                                
                                if riderRequest["reachedRider"] as? Bool == true && riderRequest["headingToDestination"] as? Bool == false {
                                    
                                    self.displayAlert(title: "Picked Up Rider!", message: "You can now click on the Navigation button to navigate to the requested destination. Thanks!")
                                    riderRequest["headingToDestination"] = true
                                    riderRequest.saveInBackground()
                                    
                                    
                                }
                                
                            }
                            
                        }
                        
                    })
                    
                }
            }
        }
    }
    
    
    
    @IBAction func openNavigation(_ sender: Any) {
        let query = PFQuery(className: "RiderRequest")
        print(requestUsername)
        query.whereKey("username", equalTo: requestUsername)
        
        query.findObjectsInBackground(block: { (objects, error) in
            if let riderRequests = objects {
                for riderRequest in riderRequests {
                    
                    if let driver = riderRequest["driver"] as? String {
                        
                        if let reachedRider = riderRequest["reachedRider"] as? Bool {
                            if driver == self.name {
                                if reachedRider {
                                    // Go to destination
                                    self.pickedUpRider = true
                                    if let destinationRider = riderRequest["destination"] as? String {
                                        
                                        if destinationRider == "Pittsfield Bus Station" {
                                            self.destination = self.pittsFieldBusStationLocation
                                            
                                        } else if destinationRider == "Walmart" {
                                            self.destination = self.walmartLocation
                                            
                                        } else if destinationRider == "Williams College" {
                                            
                                            self.destination = self.williamsCollegeLocation
                                            
                                        }
                                        
                                        
                                    }
                                    if self.destination.latitude != 0 {
                                        let destinationCLLocation = CLLocation(latitude: self.destination.latitude, longitude: self.destination.longitude)
                                        
                                        CLGeocoder().reverseGeocodeLocation(destinationCLLocation, completionHandler: { (placemarks, error) in
                                            
                                            if let placemarks = placemarks {
                                                
                                                if placemarks.count > 0 {
                                                    
                                                    let mKPlacemark = MKPlacemark(placemark: placemarks[0])
                                                    
                                                    let mapItem = MKMapItem(placemark: mKPlacemark)
                                                    
                                                    mapItem.name = "Destination"
                                                    
                                                    let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                                                    
                                                    mapItem.openInMaps(launchOptions: launchOptions)
                                                    
                                                    
                                                    
                                                }
                                                
                                                
                                            }

                                            
                                        })
                                    
                                    }
                               
                                    
                                    
                                } else {
                                self.requestLocation.latitude = (riderRequest["location"] as AnyObject).latitude
                                self.requestLocation.longitude = (riderRequest["location"] as AnyObject).longitude
                                
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
                                
                                
                                
                            } //
                            }
                        }
                    }
                    
                    
                }
                
            }
        })
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
        
        if segue.identifier == "logOutDriverFromPickMeUp" {
            locationManager.stopUpdatingLocation()
            PFUser.logOut()
        }
    }
    

}
