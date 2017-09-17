//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Panagiotis Siapkaras on 9/10/17.
//  Copyright © 2017 Panagiotis Siapkaras. All rights reserved.
//

import UIKit
import CoreLocation
import Dispatch
import CoreData

private let dateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailsViewController: UITableViewController {

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var date = Date()
    var managedObjectContext : NSManagedObjectContext!
    
    var image : UIImage?
    
    var locationToEdit: Location? {
        didSet{
            if let location = locationToEdit{
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                placemark = location.placemark
            }
        }
    }
    var descriptionText = ""
    
    var observer: Any!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        tableView.backgroundColor = UIColor.black
        tableView.separatorColor = UIColor(white: 10.0, alpha: 0.2)
        tableView.indicatorStyle = .white
        
        descriptionTextView.textColor = UIColor.white
        descriptionTextView.backgroundColor = UIColor.black
        
        addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
        addressLabel.highlightedTextColor = addressLabel.textColor
        
        addPhotoLabel.textColor = UIColor.white
        addPhotoLabel.highlightedTextColor = addPhotoLabel.textColor
        
        listenForBackgroundNotification()
        
        if let location = locationToEdit{
            title = "Edit Location"
            if location.hasPhoto{
                if let theImage = location.photoImage{
                    show(image: theImage)
                }
            }
        }
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark{
            addressLabel.text = string(from: placemark)
        }else{
            addressLabel.text = "No Address"
        }
        
        dateLabel.text = format(date:date)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func done(){
        
        let hudView = HudView.hud(inView: navigationController!.view, animated: true)
        
        let location : Location
        if let temp = locationToEdit{
            hudView.text = "Updated"
            location = temp
        }else{
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
            location.photoID = nil
        }
        
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        
        if let image = image {
            
            if !location.hasPhoto{
                location.photoID = Location.nextPhotoID() as NSNumber
            }
            
            if let data = UIImageJPEGRepresentation(image, 0.5){
                do {
                    try data.write(to: location.photoURL, options: .atomic)
                }catch{
                    print("error writing file : \(error)")
                }
            }
        }
        
        do{
            try managedObjectContext.save()
            afterDelay(0.6) {
                self.dismiss(animated: true, completion: nil)
            }
        }catch{
            fatalCoreDataError(error)
        }
        
        
       
    }
    
    @IBAction func cancel(){
        dismiss(animated: true, completion: nil)
    }
    
    func string(from placemark: CLPlacemark) -> String{
        
        var line = ""
        
        line.add(text: placemark.subThoroughfare)
        line.add(text: placemark.thoroughfare, separatorBy: " ")
        line.add(text: placemark.locality, separatorBy: ", ")
        line.add(text: placemark.administrativeArea, separatorBy: ",")
        line.add(text: placemark.postalCode, separatorBy: " ")
        line.add(text: placemark.country, separatorBy: ", ")
        return line
        
    }
    
    func format(date: Date) -> String{
        return dateFormatter.string(from:date)
    }
    
    func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer){
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0{
            return
        }
        
        descriptionTextView.resignFirstResponder()
    }

    //MARK: TableView delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            return 88
        }else if indexPath.section == 2 && indexPath.row == 2{
            addressLabel.frame.size = CGSize(width: view.bounds.width - 115, height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
        }else if indexPath.section == 1 && indexPath.row == 0 {
            if imageView.isHidden {
                return 44
            }else{
                return 280
            }
        }else{
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1{
            return indexPath
        }else{
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        }else if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
        }
        
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.black
        
        if let textLabel = cell.textLabel {
            textLabel.textColor = UIColor.white
            textLabel.highlightedTextColor = textLabel.textColor
        }
        
        if let detailLabel = cell.detailTextLabel {
            detailLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
            detailLabel.highlightedTextColor = detailLabel.textColor
        }
        
        let selectionView = UIView(frame: CGRect.zero)
        selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        cell.selectedBackgroundView = selectionView
        
        if indexPath.row == 2 {
            let addressLabel = cell.viewWithTag(100) as! UILabel
            addressLabel.textColor = UIColor.white
            addressLabel.highlightedTextColor = addressLabel.textColor
        }
    }
    
    //MARK: Photo fucntions
    
    func pickPhoto(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            showPhotoMenu()
        }else{
            choosePhotoLibrary()
        }
    }
    
    func showPhotoMenu(){
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in self.choosePhotoLibrary() } )
        alert.addAction(cancelAction)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default) { (_) in
            self.takePhotoWithCamera()
        }
        alert.addAction(takePhotoAction)
        let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .default) { (_) in
            self.choosePhotoLibrary()
        }
        alert.addAction(chooseFromLibraryAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func show(image:UIImage) {
        imageView.image = image
        imageView.isHidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.isHidden = true
    }
    
    
    //MARK: Check for background
    
    func listenForBackgroundNotification(){
        
        observer = NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { [weak self] notification in
            
            if let strongSelf = self{
            if strongSelf.presentedViewController != nil{
                strongSelf.dismiss(animated: false, completion: nil)
            }
            
            strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
        
    }
    
    deinit {
        print("*** deinit \(self)")
        NotificationCenter.default.removeObserver(observer)
    }
    
    
    //MARK: - Unwind Segue
    
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue){
        let fromDestination = segue.source as! CategoryPickerViewController
        categoryName = fromDestination.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory"{
            let destinationController = segue.destination as! CategoryPickerViewController
            destinationController.selectedCategoryName = categoryName
        }
    }
    

}


extension LocationDetailsViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    
    func choosePhotoLibrary(){
        
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func takePhotoWithCamera(){
        
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if let theImage = image{
            show(image: theImage)
        }
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}











































