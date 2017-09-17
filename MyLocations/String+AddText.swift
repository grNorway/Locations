//
//  String+AddText.swift
//  MyLocations
//
//  Created by Panagiotis Siapkaras on 9/14/17.
//  Copyright © 2017 Panagiotis Siapkaras. All rights reserved.
//

import Foundation

extension String{
    
    mutating func add(text : String? , separatorBy separator: String = ""){
        if let text = text{
            if !text.isEmpty{
                self += separator
            }
            self += text
        }
    }
}
