//
//  Extensions.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/12/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let reload = Notification.Name("reload")
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}

extension Date {
    func daysBetweenDate(toDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: toDate)
        return components.day ?? 0
    }
}

extension CGSize {
    
    func resizeFill(toSize: CGSize) -> CGSize {
        
        let scale : CGFloat = (self.height / self.width) < (toSize.height / toSize.width) ? (self.height / toSize.height) : (self.width / toSize.width)
        return CGSize(width: (self.width / scale), height: (self.height / scale))
        
    }
}

extension UIImage {
    
    func scale(toSize newSize:CGSize) -> UIImage {
        
        // make sure the new size has the correct aspect ratio
        let aspectFill = self.size.resizeFill(toSize: newSize)
        
        UIGraphicsBeginImageContextWithOptions(aspectFill, false, 0.0)
        self.draw(in: CGRect(x:0, y:0, width:aspectFill.width, height:aspectFill.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}

// Utility to lock the orientation of the device when called
struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        
        self.lockOrientation(orientation)
        
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
    
}

extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else { return false }
        return !window.frame.equalTo(window.screen.bounds)
    }
}

public extension NSLayoutConstraint {
    
    func changeMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {
        let newConstraint = NSLayoutConstraint(
            item: firstItem!,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        newConstraint.priority = priority
        
        NSLayoutConstraint.deactivate([self])
        NSLayoutConstraint.activate([newConstraint])
        
        return newConstraint
    }
}

public extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        // iPhone (iOS 15+ supported)
        case "iPhone8,4": return "iPhone SE"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1": return "iPhone 8"
        case "iPhone10,2": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd Gen)"
        case "iPhone13,1": return "iPhone 12 Mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 Mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd Gen)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
            
        // iPhone 16 Series
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,5": return "iPhone 16e"

        // iPad (iOS 15+ supported)
        case "iPad6,11", "iPad6,12": return "iPad 5th Gen"
        case "iPad7,5", "iPad7,6": return "iPad 6th Gen"
        case "iPad7,11", "iPad7,12": return "iPad 7th Gen"
        case "iPad11,6", "iPad11,7": return "iPad 8th Gen"
        case "iPad12,1", "iPad12,2": return "iPad 9th Gen"
        case "iPad13,18", "iPad13,19": return "iPad 10th Gen"

        case "iPad11,1", "iPad11,2": return "iPad Mini 5"
        case "iPad14,1", "iPad14,2": return "iPad Mini 6"

        case "iPad11,3", "iPad11,4": return "iPad Air 3rd Gen"
        case "iPad13,1", "iPad13,2": return "iPad Air 4th Gen"
        case "iPad13,16", "iPad13,17": return "iPad Air 5th Gen"

        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro 11-inch (1st Gen)"
        case "iPad8,9", "iPad8,10": return "iPad Pro 11-inch (2nd Gen)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (3rd Gen)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-inch (4th Gen)"

        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro 12.9-inch (3rd Gen)"
        case "iPad8,11", "iPad8,12": return "iPad Pro 12.9-inch (4th Gen)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (5th Gen)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (6th Gen)"

        // Simulator
        case "i386", "x86_64", "arm64":
            return "Simulator"

        default:
            return identifier
        }
    }
}


extension UIColor {
    
    // home screen font color
    class func home() -> UIColor {
        if homeTextColor == 0 {
            return UIColor.white
        } else {
            return UIColor.black
        }
    }
    
    class func cantaloupe() -> UIColor {
        return UIColor(red:255/255, green:204/255, blue:102/255, alpha:1.0)
    }
    class func honeydew() -> UIColor {
        return UIColor(red:204/255, green:255/255, blue:102/255, alpha:1.0)
    }
    class func spindrift() -> UIColor {
        return UIColor(red:102/255, green:255/255, blue:204/255, alpha:1.0)
    }
    class func sky() -> UIColor {
        return UIColor(red:102/255, green:204/255, blue:255/255, alpha:1.0)
    }
    class func lavender() -> UIColor {
        return UIColor(red:204/255, green:102/255, blue:255/255, alpha:1.0)
    }
    class func carnation() -> UIColor {
        return UIColor(red:255/255, green:111/255, blue:207/255, alpha:1.0)
    }
    class func licorice() -> UIColor {
        return UIColor(red:0/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func snow() -> UIColor {
        return UIColor(red:255/255, green:255/255, blue:255/255, alpha:1.0)
    }
    class func salmon() -> UIColor {
        return UIColor(red:255/255, green:102/255, blue:102/255, alpha:1.0)
    }
    class func banana() -> UIColor {
        return UIColor(red:255/255, green:255/255, blue:102/255, alpha:1.0)
    }
    class func flora() -> UIColor {
        return UIColor(red:102/255, green:255/255, blue:102/255, alpha:1.0)
    }
    class func ice() -> UIColor {
        return UIColor(red:102/255, green:255/255, blue:255/255, alpha:1.0)
    }
    class func orchid() -> UIColor {
        return UIColor(red:102/255, green:102/255, blue:255/255, alpha:1.0)
    }
    class func bubblegum() -> UIColor {
        return UIColor(red:255/255, green:102/255, blue:255/255, alpha:1.0)
    }
    class func lead() -> UIColor {
        return UIColor(red:25/255, green:25/255, blue:25/255, alpha:1.0)
    }
    class func mercury() -> UIColor {
        return UIColor(red:230/255, green:230/255, blue:230/255, alpha:1.0)
    }
    class func tangerine() -> UIColor {
        return UIColor(red:255/255, green:128/255, blue:0/255, alpha:1.0)
    }
    class func lime() -> UIColor {
        return UIColor(red:128/255, green:255/255, blue:0/255, alpha:1.0)
    }
    class func seafoam() -> UIColor {
        return UIColor(red:0/255, green:255/255, blue:128/255, alpha:1.0)
    }
    class func aqua() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:255/255, alpha:1.0)
    }
    class func grape() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:255/255, alpha:1.0)
    }
    class func strawberry() -> UIColor {
        return UIColor(red:255/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func tungsten() -> UIColor {
        return UIColor(red:51/255, green:51/255, blue:51/255, alpha:1.0)
    }
    class func silver() -> UIColor {
        return UIColor(red:204/255, green:204/255, blue:204/255, alpha:1.0)
    }
    class func maraschino() -> UIColor {
        return UIColor(red:255/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func lemon() -> UIColor {
        return UIColor(red:255/255, green:255/255, blue:0/255, alpha:1.0)
    }
    class func spring() -> UIColor {
        return UIColor(red:0/255, green:255/255, blue:0/255, alpha:1.0)
    }
    class func turquoise() -> UIColor {
        return UIColor(red:0/255, green:255/255, blue:255/255, alpha:1.0)
    }
    class func blueberry() -> UIColor {
        return UIColor(red:0/255, green:0/255, blue:255/255, alpha:1.0)
    }
    class func magenta() -> UIColor {
        return UIColor(red:255/255, green:0/255, blue:255/255, alpha:1.0)
    }
    class func iron() -> UIColor {
        return UIColor(red:76/255, green:76/255, blue:76/255, alpha:1.0)
    }
    class func magnesium() -> UIColor {
        return UIColor(red:179/255, green:179/255, blue:179/255, alpha:1.0)
    }
    class func mocha() -> UIColor {
        return UIColor(red:128/255, green:64/255, blue:0/255, alpha:1.0)
    }
    class func fern() -> UIColor {
        return UIColor(red:64/255, green:128/255, blue:0/255, alpha:1.0)
    }
    class func moss() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:64/255, alpha:1.0)
    }
    class func ocean() -> UIColor {
        return UIColor(red:0/255, green:64/255, blue:128/255, alpha:1.0)
    }
    class func eggplant() -> UIColor {
        return UIColor(red:64/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func maroon() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:64/255, alpha:1.0)
    }
    class func steel() -> UIColor {
        return UIColor(red:102/255, green:102/255, blue:102/255, alpha:1.0)
    }
    class func aluminium() -> UIColor {
        return UIColor(red:153/255, green:153/255, blue:153/255, alpha:1.0)
    }
    class func cayenne() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func asparagus() -> UIColor {
        return UIColor(red:128/255, green:120/255, blue:0/255, alpha:1.0)
    }
    class func clover() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:0/255, alpha:1.0)
    }
    class func teal() -> UIColor {
        return UIColor(red:0/255, green:128/255, blue:128/255, alpha:1.0)
    }
    class func midnight() -> UIColor {
        return UIColor(red:0/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func plum() -> UIColor {
        return UIColor(red:128/255, green:0/255, blue:128/255, alpha:1.0)
    }
    class func tin() -> UIColor {
        return UIColor(red:127/255, green:127/255, blue:127/255, alpha:1.0)
    }
    class func nickel() -> UIColor {
        return UIColor(red:128/255, green:128/255, blue:128/255, alpha:1.0)
    }
    class func royalPurple() -> UIColor {
        return UIColor(red:83/255, green:56/255, blue:117/255, alpha:1.0)
    }
    class func darkRed() -> UIColor {
        return UIColor(red:114/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class func strongYellow() -> UIColor {
        return UIColor(red:179/255, green:151/255, blue:0/255, alpha:1.0)
    }
    class func pureYellow() -> UIColor {
        return UIColor(red:230/255, green:194/255, blue:0/255, alpha:1.0)
    }
    class func darkOrange() -> UIColor {
        return UIColor(red:166/255, green:83/255, blue:0/255, alpha:1.0)
    }
    class func darkLimeGreen() -> UIColor {
        return UIColor(red:0/255, green:114/255, blue:0/255, alpha:1.0)
    }
    class func darkTangerine() -> UIColor {
        return UIColor(red:255/255, green:168/255, blue:18/255, alpha:1.0)
    }
    class func olive() -> UIColor {
        return UIColor(red:50/255, green:50/255, blue:0/255, alpha:1.0)
    }
    class func flame() -> UIColor {
        return UIColor(red:226/255, green:88/255, blue:34/255, alpha:1.0)
    }
}
