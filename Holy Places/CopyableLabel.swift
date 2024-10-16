//
//  CopyableLabel.swift
//
//  Created by Lech H. Conde on 01/11/16.
//  Copyright © 2016 Mavels Software & Consulting. All rights reserved.
//
import UIKit

class CopyableLabel: UILabel {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    func sharedInit() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showMenu)))
    }
    
    @objc func showMenu(sender: AnyObject?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.showMenu(from: self, rect: bounds)
        }
    }

    
    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        board.string = text
        
        let menu = UIMenuController.shared
        if menu.isMenuVisible {
            menu.hideMenu()
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}
