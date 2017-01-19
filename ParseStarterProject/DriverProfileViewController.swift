//
//  DriverProfileViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/17/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse


class DriverProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var activityIndicator = UIActivityIndicatorView()
    
    var requestUsername = ""
    
    @IBOutlet weak var driverTokensCountLabel: UILabel!
    func displayAlert(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            profileImageView.image = image
            
        } else {
            
            print("There was an error uploading your picture. Please try again later")
        }
        
        
        
        
        self.dismiss(animated: true, completion: nil)
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

    
    @IBAction func importImage(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        
        imagePickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        imagePickerController.allowsEditing = false
        
        self.present(imagePickerController, animated: true, completion: nil)
        
        
        
    }
    
    @IBAction func saveDetails(_ sender: Any) {
        // Deleter the old user info, and replace with new
        pauseApp()
        
        let query = PFQuery(className: "Users")
        
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        query.findObjectsInBackground(block: { (objects, error) in
            
            if let profiles = objects {
                
                for profile in profiles {
                    
                    let imageData = UIImageJPEGRepresentation(self.profileImageView.image!, 0.5)
                    
                    let imageFile = PFFile(name: "profPic.jpeg", data: imageData!)
                    
                    profile["profilePic"] = imageFile
                    
                    profile.saveInBackground { (success, error) in
                        
                        if success {
                            self.restoreApp()
                            self.displayAlert(title: "Profile Updated!", message: "Your profile has now been updated!")
                            
                        } else if let error = error {
                            
                            var displayedErrorMessage = "Sorry, there seems to be an error logging you in now. Please try again later."
                            
                            if let parseError = (error as NSError).userInfo["error"] as? String {
                                
                                displayedErrorMessage = parseError
                            }
                            
                            self.restoreApp()
                            self.displayAlert(title: "Profile Issue", message: displayedErrorMessage)
                            
                        }
                    }
                    
                }
            }
        })
    }
    
    
    
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logDriverOutSegue" {
            PFUser.logOut()
            
        } else if segue.identifier == "getToNavigation" {
            
            if let destination = segue.destination as? DriverPickMeUpViewController {
                
                destination.requestUsername = requestUsername
                
            }
            
        }

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        pauseApp()
        let query = PFQuery(className: "Users")
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        query.findObjectsInBackground(block: { (objects, error) in
            if let objects = objects {
                print("fa")
                for object in objects {
                    print("fai")
                    if let pic = object["profilePic"] as? PFFile {
                        pic.getDataInBackground(block: { (imageData, error) in
                            
                            if error == nil {
                                
                                let image = UIImage(data: imageData!)
                                self.profileImageView.image = image
                                print("yay")
                            }
                            
                        })
                        
                    }
                   
                    if let tokens = object["tokens"] as? Int {
                    
                        self.driverTokensCountLabel.text = "Current Tokens: \(tokens)"
                    
                    }
                }
                
            }
        })

        let query2 = PFQuery(className: "RiderRequest")
        query2.whereKey("driver", equalTo: (PFUser.current()?.username)!)
        query2.whereKey("rideEnded", equalTo: false)
        print((PFUser.current()?.username)!)
        query2.findObjectsInBackground(block: { (objects, error) in
            if let objects = objects {
                print(objects)
                for object in objects {
                    
                    if let rider = object["username"] as? String {
                    
                        self.requestUsername = rider
                        //self.performSegue(withIdentifier: "getToNavigation", sender: self)
                    
                    }
                    if object["rideEnded"] as? Bool == false {
                        self.performSegue(withIdentifier: "getToNavigation", sender: self)
                    
                    }
                    
                }
                
            }
        })
        
        let clearQuery = PFQuery(className: "PickMeUpRideSession")
        clearQuery.whereKey("driver", equalTo: (PFUser.current()?.username)!)
        clearQuery.whereKey("rideEnded", equalTo: true)
        // I want to delete the objects here, since ride is finished.
        clearQuery.findObjectsInBackground(block: { (objects, error) in
            if let objects = objects {
                
                for object in objects {
                    
                    object.deleteInBackground()
                    
                }
                
            }
        })

        // Do any additional setup after loading the view.
        restoreApp()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
