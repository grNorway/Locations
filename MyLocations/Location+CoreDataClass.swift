//
//  Location+CoreDataClass.swift
//  MyLocations
//
//  Created by Panagiotis Siapkaras on 9/11/17.
//  Copyright © 2017 Panagiotis Siapkaras. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    public var title: String? {
        if locationDescription.isEmpty {
            return "(No Description)"
        }else{
            return locationDescription
        }
    }
    
    public var subtitle: String? {
        return category
    }
    
    //MARK: photo saving
    
    var hasPhoto : Bool {
        return photoID != nil
    }
    
    var photoURL : URL {
        assert(photoID != nil, "No photo ID set")
        let filename = "Photo - \(photoID!.intValue).jpg"
        return applicationDocumentsDirectory.appendingPathComponent(filename)
    }
    
    var photoImage : UIImage? {
        return UIImage(contentsOfFile: photoURL.path)
    }
    
    class func nextPhotoID() -> Int {
        let currentID = UserDefaults.standard.integer(forKey: "PhotoID")
        UserDefaults.standard.set(currentID + 1, forKey: "PhotoID")
        UserDefaults.standard.synchronize()
        return currentID
    }
    
    func removePhotoFile(){
        if hasPhoto{
            do{
                try FileManager.default.removeItem(at: photoURL)
            }catch{
                print("Error removing photo file : \(error)")
            }
        }
    }
    
}
