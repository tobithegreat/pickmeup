//
//  RiderProfileViewController.swift
//  ParseStarterProject-Swift
//
//  Created by asc on 12/15/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MessageUI

class RiderProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MFMailComposeViewControllerDelegate {
    
    var activityIndicator = UIActivityIndicatorView()
    
    func displayAlert(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }
    
    func sendEmail(subject: String, body: String) {
    
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.setToRecipients(["omp1@williams.edu"])
        mailVC.setSubject(subject)
        mailVC.setMessageBody(body, isHTML: false)
        
        present(mailVC, animated: true, completion: nil)
    
    }
    
    
    func displayHelpCenter(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "Purchase Tokens", style: .default, handler: { (action) in
            
                self.sendEmail(subject: "TOKEN PURCHASE FOR: \((PFUser.current()?.username!)!)", body: "I would like to purchase __ tokens. I have sent $__ in Venmo, and my venmo ID is __.  ")
            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Request Assistance", style: .default, handler: { (action) in
            
                self.sendEmail(subject: "HELP REQUEST FOR: \((PFUser.current()?.username!)!)", body: "I would like assistance with the following: ")
            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Report User", style: .default, handler: { (action) in
            
                self.sendEmail(subject: "REPORT USER FOR: \((PFUser.current()?.username!)!)", body: "I would like to submit an anonymous report on a user, whose username is ___:")
            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }

    @IBAction func helpCenterButton(_ sender: Any) {
        displayHelpCenter(title: "Help Center", message: "Please choose an option below.")
        
    }
    @IBOutlet weak var tokenCountLabel: UILabel!
    
    @IBAction func callorCheckButton(_ sender: Any) {
        if callOrCheckOutlet.titleLabel?.text == "View PickmeUp Progress" {
        
            self.performSegue(withIdentifier: "goToNavigation", sender: self)
            
        } else {
        
            self.performSegue(withIdentifier: "showRiderOrderViewController", sender: self)
        
        }
    }
    
    
    
    @IBOutlet weak var callOrCheckOutlet: UIButton!

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
    
    @IBAction func savePicture(_ sender: Any) {
        // Delete the old user info, and replace with new
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
        
        
        
        //restoreApp()
    }
    
    

    @IBOutlet weak var profileImageView: UIImageView!
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logOutSegue" {
            PFUser.logOut()
        
        } 
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pauseApp()
        

        // Do any additional setup after loading the view.
        
       
            
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        query.whereKey("rideEnded", equalTo: false)

        
        
        query.findObjectsInBackground(block: { (objects, error) in
            if let riderRequests = objects {
             
                if riderRequests.count > 0 {
                    for riderRequest in riderRequests {
                    if riderRequest["driver"] as? String == "" {
                    self.callOrCheckOutlet.setTitle("Check PickMeUpStatus", for: [])
                    } else if riderRequest["driver"] as? String != "" {
                        self.callOrCheckOutlet.setTitle("View PickmeUp Progress", for: [])
                    }
                    }
                }
                
                
            }
        })
        
       
        
        
        

        let query2 = PFQuery(className: "Users")
        query2.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        query2.findObjectsInBackground(block: { (objects, error) in
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
                            } else if let error = error {
                                
                                var displayedErrorMessage = "Sorry, there seems to be an error logging you in now. Please try again later."
                                
                                if let parseError = (error as NSError).userInfo["error"] as? String {
                                    
                                    displayedErrorMessage = parseError
                                }
                            }
                            
                        })
                    
                    }
                    
                    if let tokens = object["tokens"] as? Int {
                    
                        self.tokenCountLabel.text = "Current Tokens: \(tokens)"
                    
                    }
                
                }
                
            }
            
        let clearQuery = PFQuery(className: "PickMeUpRideSession")
            query.whereKey("rider", equalTo: (PFUser.current()?.username)!)
            query.whereKey("rideEnded", equalTo: true)
            // I want to delete the objects here, since ride is finished.
            query.findObjectsInBackground(block: { (objects, error) in
                if let objects = objects {
                
                    for object in objects {
                    
                        object.deleteInBackground()
                    
                    }
                
                }
            })
            
            self.restoreApp()

        })
        
        /*
        let rideQuery = PFQuery(className: "RiderRequest")
        rideQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        rideQuery.findObjectsInBackground { (objects, error) in
            
            if let objects = objects {
            
                for object in objects {
                
                    if let driver = object["driver"] as? String {
                    
                        
                    
                    }
                
                }
            
            }
            
        } */
        restoreApp()
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
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
