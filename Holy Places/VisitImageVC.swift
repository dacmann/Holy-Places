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
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBAction func done(_ sender: Any) {
        scrollView.zoomScale = minScale
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        scrollView.delegate = self
        scrollView.backgroundColor = .black
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
    }
    
    fileprivate func updateMinZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateMinZoomScaleForSize(scrollView.bounds.size)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(scrollView.bounds.size)
    }
    
    fileprivate func updateConstraintsForSize(_ size: CGSize) {
        
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    
    @objc override func viewDidLayoutSubviews() {
        // Configure the Image view
        if img != nil {
            imageView.image = img
        }
    }
    
    @objc func doubleTapped(recognizer:  UITapGestureRecognizer) {
        if let scrollV = self.scrollView {
            if scrollV.zoomScale > scrollV.minimumZoomScale {
                scrollV.setZoomScale(scrollV.minimumZoomScale, animated: true)
            }
            else {
                //(I divide by 3.0 since I don't wan't to zoom to the max upon the double tap)
                let zoomRect = self.zoomRectForScale(scale: scrollV.maximumZoomScale / 3.0, center: recognizer.location(in: recognizer.view))
                self.scrollView?.zoom(to: zoomRect, animated: true)
            }
        }
    }
    
    @objc func zoomRectForScale(scale : CGFloat, center : CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        if let imageV = self.imageView {
            zoomRect.size.height = imageV.frame.size.height / scale
            zoomRect.size.width  = imageV.frame.size.width  / scale
            let newCenter = imageV.convert(center, from: self.scrollView)
            zoomRect.origin.x = newCenter.x - ((zoomRect.size.width / 2.0))
            zoomRect.origin.y = newCenter.y - ((zoomRect.size.height / 2.0))
        }
        return zoomRect
    }

}
