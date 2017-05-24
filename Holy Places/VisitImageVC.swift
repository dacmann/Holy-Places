//
//  VisitImageVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 5/23/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class VisitImageVC: UIViewController, UIScrollViewDelegate {

    var img: UIImage!
    var minScale = CGFloat()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func done(_ sender: Any) {
        scrollView.zoomScale = minScale
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        scrollView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
    }

    override func viewDidLayoutSubviews() {
        // Configure the Image view
        imageView.image = img
        imageView.frame = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        scrollView.contentSize = img!.size
        print(scrollView.contentSize)
        print(scrollView.frame.size)
        scrollView.clipsToBounds = false
        let scrollViewFrame = scrollView.frame
        let scaleWidth = scrollViewFrame.size.width / scrollView.contentSize.width
        let scaleHeight = scrollViewFrame.size.height / scrollView.contentSize.height
        minScale = min(scaleWidth, scaleHeight);
        scrollView.minimumZoomScale = minScale;
        print(minScale)
        scrollView.maximumZoomScale = 2.0
        scrollView.zoomScale = minScale
        centerImage()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func doubleTapped(recognizer:  UITapGestureRecognizer) {
        if let scrollV = self.scrollView {
            if (scrollV.zoomScale > scrollV.minimumZoomScale) {
                scrollV.setZoomScale(scrollV.minimumZoomScale, animated: true)
            }
            else {
                //(I divide by 3.0 since I don't wan't to zoom to the max upon the double tap)
                let zoomRect = self.zoomRectForScale(scale: scrollV.maximumZoomScale / 2.0, center: recognizer.location(in: recognizer.view))
                self.scrollView?.zoom(to: zoomRect, animated: true)
            }
        }
    }
    
    func zoomRectForScale(scale : CGFloat, center : CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        if let imageV = self.imageView {
            zoomRect.size.height = imageV.frame.size.height / scale
            zoomRect.size.width  = imageV.frame.size.width  / scale
            let newCenter = imageV.convert(center, from: self.scrollView)
            zoomRect.origin.x = newCenter.x - ((zoomRect.size.width / 2.0))
            zoomRect.origin.y = newCenter.y - ((zoomRect.size.height / 2.0))
        }
        return zoomRect;
    }
    
    func centerImage() {
        if let image = imageView.image {
            
            let ratioW = imageView.frame.width / image.size.width
            let ratioH = imageView.frame.height / image.size.height
            
            let ratio = ratioW < ratioH ? ratioW:ratioH
            
            let newWidth = image.size.width*ratio
            let newHeight = image.size.height*ratio
            
            let left = 0.5 * (newWidth * scrollView.zoomScale > imageView.frame.width ? (newWidth - imageView.frame.width) : (scrollView.frame.width - scrollView.contentSize.width))
            let top = 0.5 * (newHeight * scrollView.zoomScale > imageView.frame.height ? (newHeight - imageView.frame.height) : (scrollView.frame.height - scrollView.contentSize.height))
            
            scrollView.contentInset = UIEdgeInsetsMake(top, left, top, left)
        }
    }
    

}
