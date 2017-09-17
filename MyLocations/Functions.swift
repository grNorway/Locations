//
//  Functions.swift
//  MyLocations
//
//  Created by Panagiotis Siapkaras on 9/11/17.
//  Copyright © 2017 Panagiotis Siapkaras. All rights reserved.
//

import Foundation
import Dispatch

func afterDelay(_ seconds: Double, closure : @escaping () -> ()){

    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
    
}

let applicationDocumentsDirectory : URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    return paths[0]
}()

let MyManagedObjectContextSaveDidFailNotification = Notification.Name(rawValue: "MyManagedObjectContextSaveDidFailNotification")

func fatalCoreDataError(_ error: Error){
    print("FatalError: \(error)")
    NotificationCenter.default.post(name: MyManagedObjectContextSaveDidFailNotification, object: nil)
}
