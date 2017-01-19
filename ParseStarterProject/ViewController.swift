/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse
import MessageUI

class ViewController: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {
    
    
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
    let when = DispatchTime.now() + 0.7

    var signUpMode = false
    var verified = false
    var signUpError = false
    
    
    var activityIndicator = UIActivityIndicatorView()
    
    func createUser() {
        
        self.pauseApp()
        
        
        let user = PFUser()
        
        user.username = self.usernameTextField.text
        user.password = self.passwordTextField.text
        
        user["isDriver"] = self.rideOrDriveSwitch.isOn
        
        
        
        user.signUpInBackground(block: { (success, error) in
            
            if let error = error {
                // Sign Up Error, likely no Internet access
                
                var displayedErrorMessage = "Sorry, there seems to be an error siging you up now. Please try again later."
                
                if let parseError = (error as NSError).userInfo["error"] as? String {
                    
                    displayedErrorMessage = parseError
                }
                
                self.displayAlert(title: "Sign Up Failed", message: displayedErrorMessage)
                
            } else {
                // Creating a pending sign up request. So that I can manually approve all users.
                
                
                /*
                 // Sign up and log in
                 
                 print("Sign Up Successful")
                 
                 if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                 
                 if isDriver {
                 // log in as a driver
                 self.performSegue(withIdentifier: "showDriverProfile", sender: self)
                 
                 } else {
                 // log in as a rider
                 self.performSegue(withIdentifier: "showRiderProfileViewController", sender: self)
                 }
                 
                 }
                 */
            }
            
        })
        
        
        self.restoreApp()
        
        

        
    
        let newUser = PFObject(className: "Users")
        
        newUser["username"] = self.usernameTextField.text
        newUser["isVerified"] = false
        newUser["fullName"] = "BLANK"
        newUser["classYear"] = "BLANK"
        newUser["unix"] = "BLANK"
        newUser["contactNum"] = "BLANK"
        newUser["isDriver"] = self.rideOrDriveSwitch.isOn
        
        let myPic = "pcar"
        let pic = UIImage(named: myPic)
        let imageData = UIImageJPEGRepresentation(pic!, 0.5)
        
        let imageFile = PFFile(name: "profPic.png", data: imageData!)
        
        newUser["profilePic"] = imageFile
        newUser["tokens"] = 0
        
        if self.rideOrDriveSwitch.isOn {
        
            newUser["carMakeAndModel"] = "BLANK"
        
        }
        
        let acl = PFACL()
        
        acl.getPublicReadAccess = true
        acl.getPublicWriteAccess = true
        
        newUser.acl = acl

        
        newUser.saveInBackground(block: { (success, error) in
            
            
            if let error = error {
                //print(error)
                self.signUpError = true
                if (PFErrorCode.errorInvalidSessionToken.rawValue == 209) {
                    PFUser.logOut()
                    //Necessary pop of view controllers after executing the previous code.
                }
                
            } else {
                //print(success)
                self.signUpError = false
                
                
                
            }
            
        })
    
    }
    
    func displaySignUpRequest(title: String, message: String) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "I Agree", style: .default, handler: { (action) in
            
            if !self.rideOrDriveSwitch.isOn {
                
                self.sendEmail(subject: "SIGN UP REQUEST", body: "I would like to sign up for Pickmeup as a rider. I have read the Terms and Conditions and by signing up, I directly agree to them. My required personal information is as follows:\nName:____ \nClass Year:______ \nUnix:_____ \nContact #:_______")
                
            } else {
                
                self.sendEmail(subject: "SIGN UP REQUEST", body: "I would like to sign up for Pickmeup as a driver. I have read the Terms and Conditions and by signing up, I directly agree to them. My required personal information is as follows:\nName:_____ \nClass Year:_____ \nUnix:_____ \nContact #:_____ \nCar Make and Model:_____")
                
            }

            
        }))
        
        alertcontroller.addAction(UIAlertAction(title: "Decline", style: .default, handler: nil))
        
        self.present(alertcontroller, animated:true, completion: nil)
    }

    
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var rideOrDriveSwitch: UISwitch!
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: self.when) {
            if self.signUpError {
                DispatchQueue.main.asyncAfter(deadline: self.when) {
                    
                    self.displayAlert(title: "Error Occured", message: "Sorry, please try again later.")
                    
                    
                }
            
            } else {
                if result == MFMailComposeResult.sent {
                    self.createUser()
                    self.displayAlert(title: "Sign Up Request Successful", message: "Please wait for your account to be verified!")
                }
            }
        }
    }
    
    func pauseApp() {
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        activityIndicator.center = self.view.center
        
        activityIndicator.hidesWhenStopped = true
        
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        
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
    @IBAction func signUpOrLogInButton(_ sender: Any) {
        // Check if null values in textfields
        
        if usernameTextField.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Error in Fields", message: "Please enter a username and password!")
         
        } else {
            
            
            if signUpMode == false {
                
                
                // Check if session already 
                if  1 == 2 {//(PFErrorCode.errorInvalidSessionToken.rawValue == 209) {
                    print("Had session")
                    PFUser.logOut()
                    //Necessary pop of view controllers after executing the previous code.
                } else {
                // Log the user in
                    print("Logging in now")
                    print(self.usernameTextField.text!)
                    print(self.passwordTextField.text!)
                    pauseApp()
                    let query = PFQuery(className: "Users")
                    query.whereKey("username", equalTo: self.usernameTextField.text!)
                    
                    query.findObjectsInBackground(block: { (objects, error) in
                        
                        if let objects = objects {
                            if objects.count == 0 {
                                self.displayAlert(title: "No Account Found", message: "Sorry! No account exists with those credentials.")
                            }
                            for object in objects {
                            
                                if object["isVerified"] as? Bool == true {
                                    self.verified = true
                                    PFUser.logInWithUsername(inBackground: self.usernameTextField.text!, password: self.passwordTextField.text!, block: { (user, error) in
                                        
                                        if let error = error {
                                            
                                            var displayedErrorMessage = "Sorry, there seems to be an error logging you in now. Please try again later."
                                            
                                            if let parseError = (error as NSError).userInfo["error"] as? String {
                                                
                                                displayedErrorMessage = parseError
                                            }
                                            
                                            self.displayAlert(title: "Log In Failed", message: displayedErrorMessage)
                                            
                                        } else {
                                            
                                            print("Log In Successful")
                                            
                                            if let isDriver = object["isDriver"] as? Bool {
                                                if isDriver {
                                                
                                                    self.performSegue(withIdentifier: "showDriverProfile", sender: self)
                                                 
                                                } else {
                                                
                                                    self.performSegue(withIdentifier: "showRiderProfileViewController", sender: self)
                                                
                                                }
                                            }
                                            
                                        }
                                        
                                    })

                                    
                                
                                } else {
                                    self.displayAlert(title: "Account Not Verified", message: "Please wait for your student information to be verified. Sorry for the inconvenience!")
                                }
                            object.saveInBackground()
                            }
                            
                        
                        }
                        else {
                            self.displayAlert(title: "No Account Found", message: "Sorry! No account exists with those credentials.")
                        }
                        
                    })
                    
                   self.restoreApp()
                }
            }else {
                // Sign the user up
                if self.confirmPasswordTextField.text != self.passwordTextField.text {
                    displayAlert(title: "Passwords Error", message: "The passwords entered do not match!")
                } else {
                    self.displaySignUpRequest(title: "Signing You Up!", message: "Thanks for signing up for PickMeUp! Please read the Terms and Conditions, and agree here.")
                }
                
            }
            
        
        }
        
        
        
        
    }
    @IBOutlet weak var signUpOrLoginCheckOutlet: UIButton!
    @IBOutlet weak var rideLabelOutlet: UILabel!
    @IBOutlet weak var driveLabelOutlet: UILabel!
    @IBOutlet weak var switchSignUpModeOutlet: UIButton!
    
    func signUpStuff() {
        // Show all the Sign Up essentials
        rideOrDriveSwitch.isHidden = false
        rideLabelOutlet.isHidden = false
        driveLabelOutlet.isHidden = false
        confirmPasswordTextField.isHidden = false
    
    }
    
    func logInStuff() {
        // Hide the Sign Up Stuff
        rideOrDriveSwitch.isHidden = true
        rideLabelOutlet.isHidden = true
        driveLabelOutlet.isHidden = true
        confirmPasswordTextField.isHidden = true
    }
    @IBAction func switchSignUpMode(_ sender: Any) {
        
        if signUpMode {
            logInStuff()
            
            signUpOrLoginCheckOutlet.setTitle("Log In", for: [])
            
            switchSignUpModeOutlet.setTitle("Want to Sign Up?", for: [])
            
            signUpMode = false
    
        } else {
            signUpStuff()

            signUpOrLoginCheckOutlet.setTitle("Sign Up", for: [])
            
            switchSignUpModeOutlet.setTitle("Want to Log In?", for: [])
            
            signUpMode = true

            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Log in automatically when returning to the app, without logging out.
        logInStuff()
        if PFUser.current()?.username != nil {
            let loginQuery = PFQuery(className: "Users")
            loginQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
            loginQuery.whereKey("isVerified", equalTo: true)
            
            loginQuery.findObjectsInBackground { (objects, error) in
                
                if let users = objects {
                
                    for user in users {
                    
                        if let isDriver = user["isDriver"] as? Bool {
                        
                            if isDriver {
                                
                                //self.performSegue(withIdentifier: "showDriverProfile", sender: self)
                                
                            } else {
                            
                              //  self.performSegue(withIdentifier: "showRiderProfileViewController", sender: self)
                            
                            }
                            
                        }
                    
                    }
                
                }
                
            }
    
        }
    }

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
        self.confirmPasswordTextField.delegate = self
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
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
}
