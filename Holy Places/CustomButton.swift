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
        super.layoutSubviews()
        
        // Set border to specific float
        self.layer.cornerRadius = 6.0
        
    }
    
}

class ShadowButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add gray Shadow
//        self.tintColor = UIColor.home()
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 1.0
    }
}

class ShadowLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add gray Shadow
//        self.tintColor = UIColor.home()
        self.shadowColor = UIColor.gray
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 1.0
    }
}
