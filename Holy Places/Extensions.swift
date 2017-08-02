//
//  Extensions.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/12/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
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
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
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
        case "iPod5,1":
            return "iPod Touch 5"
        case "iPod7,1":
            return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":
            return "iPhone 4"
        case "iPhone4,1":
            return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":
            return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":
            return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":
            return "iPhone 5s"
        case "iPhone7,2":
            return "iPhone 6"
        case "iPhone7,1":
            return "iPhone 6 Plus"
        case "iPhone8,1":
            return "iPhone 6s"
        case "iPhone8,2":
            return "iPhone 6s Plus"
        case "iPhone8,4":
            return "iPhone SE"
        case "iPhone9,1", "iPhone9,3":
            return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":
            return "iPhone 7 Plus"
        case "iPhone8,4":
            return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":
            return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":
            return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":
            return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":
            return "iPad Air"
        case "iPad5,3", "iPad5,4":
            return "iPad Air 2"
        case "iPad6,11", "iPad6,12":
            return "iPad 5 (\(identifier))"
        case "iPad2,5", "iPad2,6", "iPad2,7":
            return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":
            return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":
            return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":
            return "iPad Mini 4"
        case "iPad6,7", "iPad6,8", "iPad7,1", "iPad7,2":
            return "iPad Pro 12.9 (\(identifier))"
        case "iPad6,3", "iPad6,4":
            return "iPad Pro 9.7 (\(identifier))"
        case "iPad7,3", "iPad7,4":
            return "iPad Pro 10.5 (\(identifier))"
        case "AppleTV5,3":
            return "Apple TV"
        case "i386", "x86_64":
            return "Simulator"
        default:
            return identifier
        }
    }
}

extension UIColor {
    
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
}
