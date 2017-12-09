//
//  laceDetailVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/10/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import SafariServices
import MapKit

class PlaceDetailVC: UIViewController, UIScrollViewDelegate {

    //MARK:- Variables & Outlets
    @IBOutlet weak var pictureScrollView: UIScrollView!
    @IBOutlet weak var templeName: UILabel!
    @IBOutlet weak var templeSnippet: UILabel!
    @IBOutlet weak var templeImage: UIImageView!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var phoneNumber: UITextView!
    @IBOutlet weak var recordVisitBtn: UIButton!
    @IBOutlet weak var websiteBtn: UIButton!
    @IBOutlet weak var totalVisits: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var websiteBtn2: UIButton!
    

    var visitCount = 0
    var imageCount = 0
    var visitsAdded = false
    var stockImageAdded = false
    var originalPlace = String()
    var switchedPlaces = false
    var enlargePic = false
    
    //MARK: - ScrollView functions
    
    @IBAction func changePage(_ sender: UIPageControl) {
        let page = sender.currentPage
        var frame = pictureScrollView.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        pictureScrollView.setContentOffset(CGPoint(x:frame.origin.x, y:frame.origin.y), animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Test the offset and calculate the current page after scrolling ends
        let pageWidth:CGFloat = scrollView.frame.width
        let currentPage:CGFloat = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1
        // Change the indicator
        self.pageControl.currentPage = Int(currentPage)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Test the offset and calculate the current page after scrolling ends
    }
    
    //MARK: - CoreData
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    // Retrieve the Visits data from CoreData
    func getVisits (templeName: String, startInt: Int) {
//        print("getVisits")
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "holyPlace == %@", templeName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
        
        do {
            var x = startInt
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            // Check for the number of visits that have pictures
            fetchRequest.predicate = NSPredicate(format: "picture != nil && holyPlace == %@", templeName)
            let pictureResults = try getContext().fetch(fetchRequest)
            print("Number of visits with pictures: \(pictureResults.count)")
            
//            print ("num of results = \(searchResults.count)")
            visitCount = searchResults.count
            
            for visit in searchResults as [Visit] {
                // load image
                if let imageData = visit.picture {
                    var image = UIImage(data: imageData as Data)
                    
                    // Grab date of visit and attach to picture
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE, MMMM dd YYYY"
                    let point: CGPoint = CGPoint(x: 60, y: (image?.size.height)! - (image!.size.height/16) - 40)

                    image = textToImage(drawText: formatter.string(from: visit.dateVisited! as Date) as NSString, inImage: image!, atPoint: point)

                    let imageView = UIImageView()
                    imageView.contentMode = .scaleAspectFit

                    if image!.size.height > 1000 && pictureResults.count > 2 {
                        // reduce size of picture when there are more than 2 visits with pictures so the control is more responsive
                        let smallImage = self.imageWithImage(image: image!, scaledToSize: CGSize(width: image!.size.width/3, height: image!.size.height/3))
                        imageView.image = smallImage
                        print("reduced image to \(smallImage.size.height)")
                    } else {
                        imageView.image = image
                    }
                    
                    let xPosition = self.pictureScrollView.frame.width * CGFloat(x)
                    imageView.frame = CGRect(x: xPosition, y: 0, width: self.pictureScrollView.frame.width, height: self.pictureScrollView.frame.height)
                    pictureScrollView.contentSize.width = pictureScrollView.frame.width * CGFloat(x + 1)
                    let tap = UITapGestureRecognizer(target: self, action: #selector(PlaceDetailVC.imageClicked))
                    imageView.addGestureRecognizer(tap)
                    imageView.isUserInteractionEnabled = true
                    imageView.tag = x + 1
                    OperationQueue.main.addOperation() {
                        self.pictureScrollView.addSubview(imageView)
                    }
                    imageCount += 1
                    x += 1
                }
            }
            OperationQueue.main.addOperation() {
                if self.visitCount > 0 {
                    self.totalVisits.text = "Visits: \(self.visitCount)"
                    self.totalVisits.isHidden = false
                } else {
                    self.totalVisits.isHidden = true
                }
                if x > 1 {
                    self.pageControl.numberOfPages = x
                    self.pageControl.isHidden = false
//                    self.pageControl.layer.zPosition = 1
                    self.view.bringSubview(toFront: self.pageControl)
//                    self.view.setNeedsDisplay()
                    self.pageControl.pageIndicatorTintColor = UIColor.aluminium()
                    self.pageControl.currentPageIndicatorTintColor = UIColor.ocean()
                }
            }
        } catch {
            print("Error with request: \(error)")
        }
        visitsAdded = true
    }

    //MARK:- Standard Event Functions
    override func viewDidLoad() {
//        print("viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        pictureScrollView.delegate = self
        let button = UIBarButtonItem(title: "Map", style: .plain, target: self, action: #selector(goMap(_:)))
        self.navigationItem.rightBarButtonItem = button
        originalPlace = (detailItem?.templeName)!
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        print("viewWillAppear")
        if enlargePic == false {
            if originalPlace != detailItem?.templeName {
                stockImageAdded = false
                switchedPlaces = true
                pageControl.numberOfPages = 1
                pageControl.isHidden = true
            }
            self.configureView()
            visitsAdded = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if enlargePic == false {
            // Determine number of visits and add any pictures found to the image scrollView
            if stockImageAdded {
                self.getVisits(templeName: (detailItem?.templeName)!, startInt: 1)
            } else {
                downloadImage()
            }
            
            // Change the back button on the Record Visit VC to Cancel
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
        } else {
            enlargePic = false
        }

    }
    
    override func viewDidLayoutSubviews() {
//        print("viewDidLayoutSubviews")
        // Moved the stock picture download to this method so it isn't waiting for the visits to load
        if !(visitsAdded) {
            GetSavedImage()
        }
    }
    
    func imageWithImage(image:UIImage ,scaledToSize newSize:CGSize)-> UIImage
    {
        UIGraphicsBeginImageContext( newSize )
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        return newImage
    }
    
    @objc func imageClicked()
    {
//        print("Tapped on Image")
        // navigate to another
        self.performSegue(withIdentifier: "viewImage2", sender: self)
    }
    
    func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        
        // Setup the font specific variables
        let textColor = UIColor.white
        let textFont = UIFont(name: "Baskerville", size: image.size.height/20)!
        
//        print(image.size)
        // Setup the image context using the passed image
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSAttributedStringKey.font: textFont,
            NSAttributedStringKey.foregroundColor: textColor,
            ] as [NSAttributedStringKey : Any]
        
        // Put the image into a rectangle as large as the original image
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        // Create a point within the space that is as big as the image
        let rect = CGRect(origin: point, size: image.size)
        
        // Draw the text into an image
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                originalPlace = detail.templeName
                templeSnippet.text = detail.templeSnippet
                address.text = detail.templeAddress + "\n" + detail.templeCityState + "\n" + detail.templeCountry
                if detail.templePhone == "" {
                    phoneNumber.isHidden = true
                } else {
                    phoneNumber.text = detail.templePhone
                    phoneNumber.isHidden = false
                }
                
                if detail.infoURL == "" {
                    websiteBtn.isHidden = true
                } else {
                    websiteBtn.isHidden = false
                }
                
                if detail.templeType == "T" {
                    websiteBtn2.setTitle("Schedule", for: .normal)
                } else {
                    websiteBtn2.setTitle("Web Site", for: .normal)
                }
                
                switch detail.templeType {
                case "T":
                    templeName.textColor = UIColor.darkRed()
                case "H":
                    templeName.textColor = UIColor.darkLimeGreen()
                case "C":
                    templeName.textColor = UIColor.darkOrange()
                case "V":
                    templeName.textColor = UIColor.strongYellow()
                default:
                    templeName.textColor = UIColor.lead()
                }
            }
        }
    }
    
    func GetSavedImage() {
//        print("GetSavedImage")
        // Update the user interface for the detail item.
        let context = getContext()
        if let detail = detailItem {
            // Delete any previously configured imageviews
            self.pictureScrollView.subviews.forEach({ $0.removeFromSuperview() })
            
            // Check if Place picture is already saved locally
            let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", detail.templeName)
            do {
                let searchResults = try context.fetch(fetchRequest)
                if searchResults.count > 0 {
                    for picture in searchResults as [Place] {
                        if let imageData = picture.pictureData {
                            // Convert saved data to image and add to scrollview
                            let image = UIImage(data: imageData as Data)
//                            print("Stock Image saved size: \(image?.size as Any)")
                            let imageView = UIImageView()
                            imageView.contentMode = .scaleAspectFit
                            imageView.image = image
                            imageView.frame = CGRect(x: 0, y: 0, width: self.pictureScrollView.frame.width, height: self.pictureScrollView.frame.height)
                            self.pictureScrollView.contentSize.width = self.pictureScrollView.frame.width
                            let tap = UITapGestureRecognizer(target: self, action: #selector(PlaceDetailVC.imageClicked))
                            imageView.addGestureRecognizer(tap)
                            imageView.isUserInteractionEnabled = true
                            imageView.tag = 1
//                            print(imageView.tag)
                            self.pictureScrollView.addSubview(imageView)
                            stockImageAdded = true
                            imageCount = 1
                        }
                    }
                }
            } catch {
                print("Error with request: \(error)")
            }
        }
        return
    }
    
    func downloadImage() {
//        print("downloadImage")
        // Update the user interface for the detail item.
        let context = getContext()
        if let detail = detailItem {
            // Delete any previously configured imageviews
            self.pictureScrollView.subviews.forEach({ $0.removeFromSuperview() })
            
            // Get picture from URL and any pictures from Visits
            let pictureURL = URL(string: detail.templePictureURL)!
            URLSession.shared.dataTask(with: pictureURL) { (data, response, error) in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let image = UIImage(data: data)
                    else {
                        self.getVisits(templeName: detail.templeName, startInt: 0)
                        return
                }
                DispatchQueue.main.async() { () -> Void in
                    let imageView = UIImageView()
                    imageView.contentMode = .scaleAspectFit
                    imageView.image = image
//                    print("Stock Image downloaded size: \(image.size)")
                    // Save image data to Pictures
                    let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "name == %@", detail.templeName)
                    do {
                        let searchResults = try context.fetch(fetchRequest)
                        if searchResults.count > 0 {
                            for place in searchResults as [Place] {
                                place.pictureData = data as Data
                                do {
                                    try context.save()
                                } catch let error as NSError  {
                                    print("Could not save \(error), \(error.userInfo)")
                                } catch {}
//                                print("Saving Place picture completed")
                            }
                        }
                    } catch {
                        print("Error with request: \(error)")
                    }
                    
                    // Add image to Scrollview
                    imageView.frame = CGRect(x: 0, y: 0, width: self.pictureScrollView.frame.width, height: self.pictureScrollView.frame.height)
                    self.pictureScrollView.contentSize.width = self.pictureScrollView.frame.width
                    let tap = UITapGestureRecognizer(target: self, action: #selector(PlaceDetailVC.imageClicked))
                    imageView.addGestureRecognizer(tap)
                    imageView.isUserInteractionEnabled = true
                    imageView.tag = 1
                    self.pictureScrollView.addSubview(imageView)
                    // Get other pictures from Visits
                    self.getVisits(templeName: detail.templeName, startInt: 1)
                    self.stockImageAdded = true
                    self.imageCount = 1
                }
                }.resume()
        }
        return
    }
    
    
    //MARK: - Navigation
    
    @objc func goMap(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
        let coordinate = CLLocationCoordinate2D(latitude: (detailItem?.cllocation.coordinate.latitude)!, longitude: (detailItem?.cllocation.coordinate.longitude)!)
        mapPoint = MapPoint(title: (detailItem?.templeName)!, coordinate: coordinate, type: (detailItem?.templeType)!)
        if !switchedPlaces{
            // Set the map point just for this one place
            mapPoints.removeAll()
            mapPoints.append(mapPoint)
            mapZoomLevel = 4000
        }
        mapCenter = coordinate
        navigationController?.pushViewController(controller, animated: true)
        
        // Change the back button on the Map VC to Back
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: nil, action: nil)

    }
    @IBAction func LaunchWebsite2(_ sender: UIButton) {
        if let url = URL(string: (detailItem?.templeSiteURL)!) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: (detailItem?.readerView)!)
            present(vc, animated: true)
        }
    }
    
    @IBAction func launchWebsite(_ sender: Any) {
        if let url = URL(string: (detailItem?.infoURL)!) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            present(vc, animated: true)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "recordVisit" {
            let temple = detailItem
            let controller = (segue.destination as! RecordVisitVC)
            controller.detailItem = temple
        }
        if segue.identifier == "viewImage2" {
            
            let destViewController: VisitImageVC = segue.destination as! VisitImageVC
            var tagNo = 1
            if imageCount > 1 {
                tagNo = pageControl.currentPage + 1
            }
            enlargePic = true
            if let theImageView = self.pictureScrollView.viewWithTag(tagNo) as? UIImageView {
//                print("Found image")
                destViewController.img =  theImageView.image
            } 

        }
    }

}
