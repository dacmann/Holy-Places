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
    var imageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var done: UIButton!
    
    @IBAction func doneButton(_ sender: Any) {
        scrollView.zoomScale = 1.0
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.backgroundColor = .black
        
        imageView = UIImageView(image: img)
        imageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerYAnchor).isActive = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
        
        view.bringSubviewToFront(done)

    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    
    @objc func doubleTapped(recognizer:  UITapGestureRecognizer) {
        if let scrollV = self.scrollView {
            if scrollV.zoomScale == 1 {
                let zoomRect = self.zoomRectForScale(scale: scrollV.maximumZoomScale, center: recognizer.location(in: recognizer.view))
                self.scrollView?.zoom(to: zoomRect, animated: true)
            } else {
                self.scrollView?.setZoomScale(1, animated: true)
            }
        }
    }
    
    @objc func zoomRectForScale(scale : CGFloat, center : CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        if let imageV = self.imageView {
            zoomRect.size.height = imageV.frame.size.height / scale
            zoomRect.size.width  = imageV.frame.size.width  / scale
            let newCenter = imageV.convert(center, from: imageV)
            zoomRect.origin.x = newCenter.x - ((zoomRect.size.width / 2.0))
            zoomRect.origin.y = newCenter.y - ((zoomRect.size.height / 2.0))
        }
        return zoomRect
    }

}
