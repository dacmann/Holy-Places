//
//  CustomButton.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/27/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

//@IBDesignable
class CustomButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews();
        
        // Set border to specific float
        self.layer.cornerRadius = 6.0;
        
    }
    
}
