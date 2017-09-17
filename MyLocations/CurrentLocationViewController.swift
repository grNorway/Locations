//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Panagiotis Siapkaras on 9/10/17.
//  Copyright © 2017 Panagiotis Siapkaras. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore

class CurrentLocationViewController: UIViewController,CLLocationManagerDelegate , CAAnimationDelegate {

    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    var logoVisible = false
    
    lazy var logoButton : UIButton = {
       let button = UIButton(type: .custom)
        button.setBackgroundImage( UIImage(named:"Logo"), for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(getLocation(_:)), for: .touchUpInside)
        
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
    }()
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError : Error?
    
    var geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    var timer: Timer?
    
    var managedObjectContext : NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
        tagButton.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func getLocation(_ sender: UIButton) {
        
        //get permission
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
        }
        
        if authStatus == .denied || authStatus == .restricted{
            showLocationServicesDeniedAlert()
        }
        
        if logoVisible{
            hideLogoView()
        }
        
        if updatingLocation{
            stopLocationManager()
        }else{
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
        
        
    }
    
    func startLocationManager(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager(){
        
        if updatingLocation{
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            
            if let timer = timer{
                timer.invalidate()
            }
            
        }
        
        
    }
    
    func didTimeOut(){
        
        print("*** Time Out")
        
        if location == nil{
            stopLocationManager()
            
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
            configureGetButton()
        }
    }
    
    func showLocationServicesDeniedAlert(){
        
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    func updateLabels(){
        
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isEnabled = true
            messageLabel.text = " "
            
            
            if let placemark = placemark{
                addressLabel.text = string(from:placemark)
            }else if performingReverseGeocoding{
                addressLabel.text = "Searching for address"
            }else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            }else {
                addressLabel.text = "No Address Found"
            }
            latitudeTextLabel.isHidden = false
            longitudeTextLabel.isHidden = false
            
        }else{
            latitudeLabel.text = " "
            longitudeLabel.text = " "
            addressLabel.text = " "
            tagButton.isEnabled = false
            messageLabel.text = "Tap 'Get My Location' to start"
            
            let statusMessage : String
            if let error = lastLocationError as NSError?{
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue{
                    statusMessage = "Location Services Disabled"
                }else{
                    statusMessage = "Error Getting Location"
                }
            }else if !CLLocationManager.locationServicesEnabled(){
                statusMessage = "Location Services Disabled"
            }else if updatingLocation{
                statusMessage = "Searching...."
            }else{
                statusMessage = ""
                showLogoView()
            }
            
            messageLabel.text = statusMessage
        }
        latitudeTextLabel.isHidden = false
        longitudeTextLabel.isHidden = false
        
    }
    
    func configureGetButton(){
        
        let spinnerTag = 1000
        
        
        
        if updatingLocation{
            getButton.setTitle("Stop", for: .normal)
            
            if view.viewWithTag(spinnerTag) == nil{
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
                spinner.center = messageLabel.center
                spinner.center.y += spinner.bounds.size.height / 2 + 20
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        }else{
            getButton.setTitle("Get My Location", for: .normal)
            
            if let spinner = view.viewWithTag(spinnerTag){
                spinner.removeFromSuperview()
            }
        }
    }
    
    //MARK: ....string func
    
    func string(from placemark: CLPlacemark) -> String{
        
        var line1 = ""
        
        line1.add(text: placemark.subThoroughfare)
        line1.add(text: placemark.thoroughfare, separatorBy: " ")
        
        var line2 = ""
        
        line2 = add(text: placemark.locality, toLine: line2, separatedBy: "")
        line2 = add(text: placemark.administrativeArea, toLine: line2, separatedBy: " ")
        line2 = add(text: placemark.postalCode, toLine: line2, separatedBy: " ")
        
        line1.add(text: line2, separatorBy: "\n")
        return line1
        
    }
    
    func add(text:String?,toLine line:String,separatedBy separator: String) -> String{
        var result = line
        if let text = text {
            if !line.isEmpty{
                result += separator
            }
            result += text
        }
        return result
    }
    
    //MARK: CLLocationManagerDelegate functions
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("DidFailWithError : \(error)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue{
            return
        }
        
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location{
            distance = newLocation.distance(from: location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy{
            
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                print("You are done!")
                stopLocationManager()
                configureGetButton()
            
            
            if distance > 0 {
                performingReverseGeocoding = false
            }
            }
            if !performingReverseGeocoding{
                print("Going To Perform Geocode")
                
                performingReverseGeocoding = true
                
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: { (placemarks, error) in
                    
                   // print("*** Found placemarks : \(placemarks) , error: \(error)")
                    
                    self.lastLocationError = error
                    
                    if error == nil , let p = placemarks , !p.isEmpty {
                        self.placemark = p.last
                    }else{
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                    
                })
            }
        }else if distance < 1{
            let timeInterval = newLocation.timestamp.timeIntervalSince((location?.timestamp)!)
            
            if timeInterval > 10{
                print("*** Forced Done!")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
        
    }
    
    //MARK : Logo View
    
    func showLogoView(){
        if !logoVisible{
            logoVisible = true
            containerView.isHidden = true
            view.addSubview(logoButton)
            
        }
    }
    
    func hideLogoView(){
//        logoVisible = false
//        containerView.isHidden = false
//        logoButton.removeFromSuperview()
//        tagButton.isHidden = false
        if !logoVisible{ return }
        
        logoVisible = false
        containerView.isHidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        let centerX = view.bounds.midX
        
        let panelMover = CABasicAnimation(keyPath: "Position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = kCAFillModeForwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(cgPoint: containerView.center)
        panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: containerView.center.y))
        
        panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        panelMover.delegate = self
        containerView.layer.add(panelMover, forKey: "paneMover")
        
        let logoMover = CABasicAnimation(keyPath: "position")
        
        logoMover.isRemovedOnCompletion = false
        logoMover.fillMode = kCAFillModeForwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        
        logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.add(logoMover, forKey: "logoMover")
        
        let logoRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotation.isRemovedOnCompletion = false
        logoRotation.fillMode = kCAFillModeForwards
        logoRotation.duration = 0.5
        logoRotation.fromValue = 0.0
        logoRotation.toValue = -2 * M_PI
        logoRotation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        logoButton.layer.add(logoRotation, forKey: "logoRotator")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool){
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
    
    
    
    
    
    
    
    //NAVIGATION
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            let navigationController = segue.destination as! UINavigationController
            let destinationController = navigationController.topViewController as! LocationDetailsViewController
            destinationController.placemark = placemark
            destinationController.coordinate = location!.coordinate
            destinationController.managedObjectContext = managedObjectContext
        }
    }
    
}


































