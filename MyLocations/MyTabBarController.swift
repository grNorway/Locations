//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Panagiotis Siapkaras on 9/14/17.
//  Copyright © 2017 Panagiotis Siapkaras. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {

    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController?{
        return nil
    }
}
