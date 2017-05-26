//
//  DetailViewController.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/10/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UIScrollViewDelegate {

    //MARK:- Variables & Outlets
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var pictureScrollView: UIScrollView!
    @IBOutlet weak var templeName: UILabel!
    @IBOutlet weak var templeSnippet: UILabel!
    @IBOutlet weak var templeImage: UIImageView!
    @IBOutlet weak var address: UITextView!
    @IBOutlet weak var phoneNumber: UITextView!
    @IBOutlet weak var recordVisitBtn: UIButton!
    @IBOutlet weak var websiteBtn: UIButton!
    @IBOutlet weak var totalVisits: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    

    var visitCount = 0
    var imageCount = 0
    var visitsAdded = false
    var stockImageAdded = false
    
    //MARK: - ScrollView functions
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: true)]
        
        do {
            var x = startInt
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            
            //I like to check the size of the returned results!
//            print ("num of results = \(searchResults.count)")
            visitCount = searchResults.count
            
            //You need to convert to NSManagedObject to use 'for' loops
            for visit in searchResults as [Visit] {
                // load image
                if let imageData = visit.picture {
                    var image = UIImage(data: imageData as Data)
                    
                    // Grab date of visit and attach to picture
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE, MMMM dd YYYY"
                    let point: CGPoint = CGPoint(x: 60, y: (image?.size.height)! - (image!.size.height/16) - 40)
//                    let point: CGPoint = CGPoint(x: 20, y: 60)
                    image = textToImage(drawText: formatter.string(from: visit.dateVisited! as Date) as NSString, inImage: image!, atPoint: point)

                    let imageView = UIImageView()
                    imageView.contentMode = .scaleAspectFit
                    imageView.image = image
                    let xPosition = self.pictureScrollView.frame.width * CGFloat(x)
                    imageView.frame = CGRect(x: xPosition, y: 0, width: self.pictureScrollView.frame.width, height: self.pictureScrollView.frame.height)
                    pictureScrollView.contentSize.width = pictureScrollView.frame.width * CGFloat(x + 1)
                    OperationQueue.main.addOperation() {
                        self.pictureScrollView.addSubview(imageView)
                    }
                    
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
                    self.pageControl.layer.zPosition = 2
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        print("viewWillAppear")
        self.configureView()
        visitsAdded = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        print("viewDidAppear")
        // Determine number of visits and add any pictures found to the image scrollView
        if stockImageAdded {
            self.getVisits(templeName: (detailItem?.templeName)!, startInt: 1)
        } else {
            downloadImage()
        }
    }
    
    override func viewDidLayoutSubviews() {
//        print("viewDidLayoutSubviews")
        // Moved the stock picture download to this method so it isn't waiting for the visits to load
        if !(visitsAdded) {
            GetSavedImage()
        }
    }
    
    //MARK: - Populate the view
    var detailItem: Temple? {
        didSet {
            // Update the view.
            self.configureView()
        }
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
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        
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
        if let detail = self.detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                templeSnippet.text = detail.templeSnippet
                address.text = detail.templeAddress + "\n" + detail.templeCityState + "\n" + detail.templeCountry
                phoneNumber.text = detail.templePhone
                recordVisitBtn.contentHorizontalAlignment = .center
                websiteBtn.contentHorizontalAlignment = .center
                if detail.templeType == "C" {
                    recordVisitBtn.isHidden = true
                }
            }
        }
    }
    
    func GetSavedImage() {
//        print("GetSavedImage")
        // Update the user interface for the detail item.
        let context = getContext()
        if let detail = self.detailItem {
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
                            self.pictureScrollView.addSubview(imageView)
                            stockImageAdded = true
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
        if let detail = self.detailItem {
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
                    print("Stock Image downloaded size: \(image.size)")
                    // Save image data to Pictures
                    let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "name == %@", detail.templeName)
                    do {
                        let searchResults = try context.fetch(fetchRequest)
                        if searchResults.count > 0 {
                            for place in searchResults as [Place] {
                                place.pictureData = data as NSData
                                do {
                                    try context.save()
                                } catch let error as NSError  {
                                    print("Could not save \(error), \(error.userInfo)")
                                } catch {}
                                print("Saving Place picture completed")
                            }
                        }
                    } catch {
                        print("Error with request: \(error)")
                    }
                    
                    // Add image to Scrollview
                    imageView.frame = CGRect(x: 0, y: 0, width: self.pictureScrollView.frame.width, height: self.pictureScrollView.frame.height)
                    self.pictureScrollView.contentSize.width = self.pictureScrollView.frame.width
                    self.pictureScrollView.addSubview(imageView)
                    // Get other pictures from Visits
                    self.getVisits(templeName: detail.templeName, startInt: 1)
                    self.stockImageAdded = true
                }
                }.resume()
        }
        return
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "recordVisit" {
            let temple = self.detailItem
            let controller = (segue.destination as! RecordVisitVC)
            controller.detailItem = temple
        }
        if segue.identifier == "showWebsite" {
            let controller = (segue.destination as! WebsiteVC)
            controller.urlPlace = self.detailItem?.templeSiteURL
        }
    }

}
