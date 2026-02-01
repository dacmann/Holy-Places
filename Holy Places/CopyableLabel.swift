//
//  CopyableLabel.swift
//
//  Created by Lech H. Conde on 01/11/16.
//  Copyright © 2016 Mavels Software & Consulting. All rights reserved.
//
import UIKit

class CopyableLabel: UILabel {
    
    private var editMenuInteraction: UIEditMenuInteraction?
    
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
        
        // Set up UIEditMenuInteraction
        editMenuInteraction = UIEditMenuInteraction(delegate: self)
        if let interaction = editMenuInteraction {
            addInteraction(interaction)
        }
        
        // Add long press gesture to show menu
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showMenu(_:))))
    }
    
    @objc func showMenu(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        becomeFirstResponder()
        
        let location = sender.location(in: self)
        let configuration = UIEditMenuConfiguration(identifier: nil, sourcePoint: location)
        editMenuInteraction?.presentEditMenu(with: configuration)
    }
    
    private func copyText() {
        UIPasteboard.general.string = text
    }
}

// MARK: - UIEditMenuInteractionDelegate
extension CopyableLabel: UIEditMenuInteractionDelegate {
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            self?.copyText()
        }
        return UIMenu(children: [copyAction])
    }
}
