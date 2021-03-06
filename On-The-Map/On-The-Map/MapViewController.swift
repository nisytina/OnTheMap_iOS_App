//
//  MapViewController.swift
//  On-The-Map
//
//  Created by Tina Ni on 23/7/2016.
//  Copyright © 2016 TinaNi. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    //MARK: Properties
   
    var message: String! = nil
    //loading overlay
    var overlay : UIView?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getLoc()
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    func getLoc() {
        
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.blackColor()
        overlay!.alpha = 0.4
        view.addSubview(overlay!)
        let seconds = 1.5
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        activityIndicatorView.startAnimating()
        ParseClient.sharedInstance().getStudentLocations { (locations, error) in
            if let locations = locations {
               StudentLocation.locations = locations
                performUIUpdatesOnMain {
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                    
                    self.removeAllpins()
                    self.displayStudentLocations(StudentLocation.locations)
                    self.activityIndicatorView.stopAnimating()
                    self.overlay?.removeFromSuperview()
                    })
                }
            } else {
                performUIUpdatesOnMain {
                    self.activityIndicatorView.stopAnimating()
                    self.overlay?.removeFromSuperview()
                    Convenience.alert(self, title: "Error", message: "Can't get location info. Try again later", actionTitle: "OK")
                }
                print(error)
            }
        }
    }
    
    
    @IBAction func refresh(sender: AnyObject) {
        getLoc()
    }
    
    private func removeAllpins() {
        let annotations = mapView.annotations
        for annotation in annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    @IBAction func addNew(sender: AnyObject) {
        
        ParseClient.sharedInstance().getUserStudentLocation { (result, error) in
            
            if let error = error {
                performUIUpdatesOnMain {
                    var errorMessage: String
                    if error.code == -1009 {
                        errorMessage = "connection fails. Can't add new location now. Try again later."
                    } else {
                        errorMessage = error.domain
                    }
                    Convenience.alert(self, title: "Error", message: errorMessage, actionTitle: "Dismiss")
                }
                print(error)
                return
            }
            
            if let _ = result {
                // need to update
                let alertController = UIAlertController(title: nil, message:
                    "User " + "\(UdacityClient.sharedInstance().firstName!) " + "\(UdacityClient.sharedInstance().lastName!) Has Already Posted a Student Location. Would you Like to Overwrite Their Location?", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel,handler: nil))
                alertController.addAction(UIAlertAction(title: "Overwrite", style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction!) in
                    performUIUpdatesOnMain{
                        UdacityClient.sharedInstance().updateLoaction = true
                        self.performSegueWithIdentifier("AddNew", sender: self)
                    }
                }))
                performUIUpdatesOnMain{
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            } else {
                performUIUpdatesOnMain{
                    self.performSegueWithIdentifier("AddNew", sender: self)
                }
            }
        }
    }
    
    // MARK: Logout
    
    @IBAction func logout(sender: AnyObject) {
        UdacityClient.sharedInstance().destroySession {(result, error) in
            if let error = error {
                print(error)
                performUIUpdatesOnMain {
                    Convenience.alert(self, title: "Error", message: "Can't logout. Try again later", actionTitle: "Dismiss")
                }
            } else {
                if let _ = result {
                    performUIUpdatesOnMain {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            }
        }
    }

    func displayStudentLocations(results: [StudentLocation]) {
        
        for result in results {
            let location = CLLocationCoordinate2DMake(result.latitude, result.longitude)
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = location
            dropPin.title = result.firstName + " " + result.lastName
            dropPin.subtitle = result.mediaURL
            mapView.addAnnotation(dropPin)
        }
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "locations"
        let buttonType = UIButtonType.InfoDark
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        
        pinView.canShowCallout = true
        pinView.rightCalloutAccessoryView = UIButton(type: buttonType)
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        
        if control == view.rightCalloutAccessoryView {
            
            let link = ((view.annotation?.subtitle)!)! as String
            
            if let requestUrl = NSURL(string: link) {
                if UIApplication.sharedApplication().canOpenURL(requestUrl) {
                    UIApplication.sharedApplication().openURL(requestUrl)
                } else {
                    
                    Convenience.alert(self, title: "Error", message: "invalid link", actionTitle: "Dismiss")
                }
            } else {
                Convenience.alert(self, title: "Error", message: "invalid link", actionTitle: "Dismiss")
            }
        }
    }

}
