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
    @IBOutlet weak var addressWidth: NSLayoutConstraint!
    @IBOutlet weak var snippetBottom: NSLayoutConstraint!
    @IBOutlet weak var snippetLeading: NSLayoutConstraint!
    @IBOutlet weak var snippetTrailing: NSLayoutConstraint!
    @IBOutlet weak var snippetTop: NSLayoutConstraint!
    @IBOutlet weak var templeNameTop: NSLayoutConstraint!
    @IBOutlet weak var templeOrdinal: UILabel!
    @IBOutlet weak var pictureHeight: NSLayoutConstraint!
    @IBOutlet weak var fhCode: UILabel!
    
    
    var visitCount = 0
    var imageCount = 0
    var visitImageCount = 0
    var visitsAdded = false
    var stockImageAdded = false
    var originalPlace = String()
    var switchedPlaces = false
    var reloadPics = true
    var picsLoading = true
    var webViewPresented = false
    var reloadSavedImage = false
    var wasSplitView = false
    var swiping = false
    
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
    
    //MARK: - Thread management functions
    func BG(_ block: @escaping ()->Void) {
        DispatchQueue.global(qos: .default).async(execute: block)
    }
    
    func UI(_ block: @escaping ()->Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    //MARK: - CoreData
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    // Retrieve the Visits data from CoreData
    func getVisits (templeName: String, startInt: Int) {
//        print("getVisits")
        processVisits: do {
            let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "holyPlace == %@", templeName)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateVisited", ascending: false)]
            
            var images = [(Date, UIImage)]()
            
            var imageCounter = startInt
            //go get the results
            let searchResults = try getContext().fetch(fetchRequest)
            visitCount = searchResults.count
            
            if !swiping {
                // Check for the number of visits that have pictures
                fetchRequest.predicate = NSPredicate(format: "picture != nil && holyPlace == %@", templeName)
                let pictureResults = try getContext().fetch(fetchRequest)
                
                //  when returning from recording a visit and no new images have been added, don't continue with image processing
                if originalPlace == detailItem?.templeName {
                    if visitImageCount == pictureResults.count {
                        break processVisits
                    } else {
                        // Reset scrollview
                        GetSavedImage()
                    }
                }
                visitImageCount = pictureResults.count
                print("Number of visits with pictures: \(visitImageCount)")
                
                //            print ("num of results = \(searchResults.count)")
                
                // needed to move BG process to the for loop since the concurrent processing of images resulted in crashes when many pictures were attached
                BG { for visit in pictureResults as [Visit] {
                    // load image
                    if let imageData = visit.picture {
                        var image = UIImage(data: imageData as Data)
                        
                        // Grab date of visit and attach to picture
                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEEE, MMMM dd YYYY"
                        let point: CGPoint = CGPoint(x: 60, y: (image?.size.height)! - (image!.size.height/16) - 40)
                        
                        // embed date of visit in picture
                        if let imageWithDate = self.textToImage(drawText: formatter.string(from: visit.dateVisited! as Date) as NSString, inImage: image!, atPoint: point) {
                            image = imageWithDate
                        }
                        
                        print(image!.size.height)
                        if image!.size.height > 2000 {
                            // reduce size of picture so the scroll view control is more responsive
                            var scale = 2.0 as CGFloat
                            // reduce by a larger amount when very big
                            if image!.size.height > 3000 {
                                scale = 3.0
                            }
                            do {
                                if let smallImage = try self.imageWithImage(image: image!, scaledToSize: CGSize(width: image!.size.width/scale, height: image!.size.height/scale)) {
                                    images.append((visit.dateVisited!, smallImage))
                                    print("reduced image to \(smallImage.size.height)")
                                } else {
                                    print("failed to reduce image")
                                }
                            } catch {
                                print("failed to reduce image - throw")
                            }
                        } else {
                            images.append((visit.dateVisited!, image!))
                        }}
                    if images.count == self.visitImageCount {
                        // all pictures have been processed, go ahead and update the UI
                        if let navigationController = self.navigationController {
                            print(navigationController.viewControllers.description)
                            // if we have moved on to another controller then don't bother updating the UI
                            if navigationController.viewControllers.count == 2 && !self.webViewPresented {
                                self.UI {
                                    if let pictureView = self.pictureScrollView {
                                        print("Add pictures to pictureScrollView")
                                        // first reorder the images by date
                                        let sortedImages = images.sorted(by: { $0.0 > $1.0 })
                                        for (_, image) in sortedImages {
                                            let imageView = UIImageView()
                                            imageView.contentMode = .scaleAspectFit
                                            imageView.image = image
                                            let xPosition = pictureView.frame.width * CGFloat(imageCounter)
                                            imageView.frame = CGRect(x: xPosition, y: 0, width: pictureView.frame.width, height: pictureView.frame.height)
                                            pictureView.contentSize.width = pictureView.frame.width * CGFloat(imageCounter + 1)
                                            let tap = UITapGestureRecognizer(target: self, action: #selector(PlaceDetailVC.imageClicked))
                                            imageView.addGestureRecognizer(tap)
                                            imageView.isUserInteractionEnabled = true
                                            imageView.tag = imageCounter + 1
                                            self.imageCount += 1
                                            imageCounter += 1
                                            pictureView.addSubview(imageView)
                                        }
                                        self.pageControl.numberOfPages = imageCounter
                                        self.pageControl.isHidden = false
                                        self.view.bringSubviewToFront(self.pageControl)
                                        self.pageControl.pageIndicatorTintColor = UIColor.aluminium()
                                        self.pageControl.currentPageIndicatorTintColor = UIColor.ocean()
                                        self.picsLoading = false
                                    } else {
                                        print("Unable to access pictureScrollView")
                                    }
                                }
                            } else {
                                self.visitImageCount = 0
                            }
                        }
                    }
                    }
                }
            }
        } catch {
            print("Error with request: \(error)")
        }
        UI {
            if self.visitCount > 0 {
                self.totalVisits.text = "Visits: \(self.visitCount)"
                self.totalVisits.isHidden = false
            } else {
                self.totalVisits.isHidden = true
            }}
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
        
        // Add swipe gestures to navigate to other places
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
    }
    
    fileprivate func setUpView() {
        
        if originalPlace != detailItem?.templeName {
            stockImageAdded = false
            if !swiping {
                switchedPlaces = true
            }
            pageControl.numberOfPages = 1
            pageControl.isHidden = true
            reloadPics = true
        }
        
        configureView()
        visitsAdded = false
        webViewPresented = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            pictureHeight.constant = view.frame.height * 0.60
        } else {
            pictureHeight.constant = view.frame.height * 0.40
        }
        setUpView()
    }
    
    fileprivate func pictures() {
        if reloadPics {
            // Determine number of visits and add any pictures found to the image scrollView
            if stockImageAdded {
                getVisits(templeName: (detailItem?.templeName)!, startInt: 1)
            } else {
                downloadImage()
            }
        } else {
            reloadPics = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        pictures()
        // Change the back button on the Record Visit VC to Cancel
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: nil, action: nil)
    }
    
    override func viewWillLayoutSubviews() {
        if UIApplication.shared.isSplitOrSlideOver {
            wasSplitView = true
        }
        
        if UIApplication.shared.statusBarOrientation.isLandscape && !UIApplication.shared.isSplitOrSlideOver {
            configureForLandscape(landscape: true)
        } else {
            configureForLandscape(landscape: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Moved the stock picture download to this method so it isn't waiting for the visits to load
        if !(visitsAdded) {
            GetSavedImage()
        }

        if UIApplication.shared.isSplitOrSlideOver || reloadSavedImage || wasSplitView {
            GetSavedImage()
            self.pageControl.isHidden = true
            reloadSavedImage = false
            if !UIApplication.shared.isSplitOrSlideOver {
                wasSplitView = false
            }
        }

    }

    fileprivate func configureForLandscape(landscape: Bool) {
        if landscape {
            // move snippet down
            snippetBottom.isActive = false
            snippetLeading.constant = 240
            snippetTrailing.constant = 240
            addressWidth.constant = 200
            templeNameTop.isActive = true
        } else {
            // move snippet back up
            snippetBottom.isActive = true
            snippetLeading.constant = 10
            snippetTrailing.constant = 10
            addressWidth.constant = 400
            templeNameTop.isActive = false
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        reloadSavedImage = true
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        reloadSavedImage = true
        if fromInterfaceOrientation.isPortrait && !UIApplication.shared.isSplitOrSlideOver {
            configureForLandscape(landscape: true)
        } else {
            configureForLandscape(landscape: false)
        }
    }
    
    func imageWithImage(image:UIImage? ,scaledToSize newSize:CGSize) throws -> UIImage?
    {
        if self.navigationController?.viewControllers.count == 2 && !self.webViewPresented {
            UIGraphicsBeginImageContext( newSize )
            image?.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            
            if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                return newImage
            } else {
                UIGraphicsEndImageContext()
                return nil
            }
        } else {
            return nil
        }
    }
    
    @objc func imageClicked()
    {
//        print("Tapped on Image")
        // navigate to another
        self.performSegue(withIdentifier: "viewImage2", sender: self)
    }
    
    func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage? {
        
        // Setup the font specific variables
        let textColor = UIColor.white
        let textFont = UIFont(name: "Baskerville", size: image.size.height/20)!
        
//        print(image.size)
        // Setup the image context using the passed image
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        
        // Put the image into a rectangle as large as the original image
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        // Create a point within the space that is as big as the image
        let rect = CGRect(origin: point, size: image.size)
        
        // Draw the text into an image
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return newImage
        } else {
            UIGraphicsEndImageContext()
            return nil
        }
    }

    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        swiping = true
        if gesture.direction == UISwipeGestureRecognizer.Direction.up {
//            print("Swipe Up")
//            print(selectedPlaceRow)
            if selectedPlaceRow < places.count - 1 {
                selectedPlaceRow += 1
                detailItem = places[selectedPlaceRow]
                setUpView()
                GetSavedImage()
                pictures()
            }
        }
        else if gesture.direction == UISwipeGestureRecognizer.Direction.down {
//            print("Swipe Down")
//            print(selectedPlaceRow)
            if selectedPlaceRow > 0 {
                selectedPlaceRow -= 1
                detailItem = places[selectedPlaceRow]
                setUpView()
                GetSavedImage()
                pictures()
            }
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = self.templeName {
                label.text = detail.templeName
                originalPlace = detail.templeName
                
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
                
                if detail.fhCode == "" {
                    fhCode.isHidden = true
                } else {
                    fhCode.isHidden = false
                    fhCode.text = detail.fhCode
                }
                
                if detail.templeType == "T" {
                    websiteBtn2.setTitle("Schedule", for: .normal)
                } else {
                    websiteBtn2.setTitle("Web Site", for: .normal)
                }
                
                if detail.templeType == "T" || detail.templeType == "C" {
                    let snippetArr = detail.templeSnippet.components(separatedBy: " - ")
                    templeOrdinal.text = snippetArr[0]
                    templeSnippet.text = detail.templeSnippet.replacingOccurrences(of: "\(snippetArr[0]) - ", with: "")
                    templeOrdinal.isHidden = false
                    snippetTop.constant = 25
                } else {
                    templeSnippet.text = detail.templeSnippet
                    templeOrdinal.isHidden = true
                    snippetTop.constant = 0
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
        print(mapPoint.name)
        if !switchedPlaces {
            // Set the map point just for this one place
            mapPoints.removeAll()
            mapPoints.append(mapPoint)
            mapZoomLevel = 4000
        }
        reloadPics = picsLoading
        mapCenter = coordinate
        navigationController?.pushViewController(controller, animated: true)
        
        // Change the back button on the Map VC to Back
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: nil, action: nil)

    }
    @IBAction func LaunchWebsite2(_ sender: UIButton) {
        if let url = URL(string: (detailItem?.templeSiteURL)!) {
            webViewPresented = true
            reloadPics = picsLoading
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: (detailItem?.readerView)!)
            present(vc, animated: true)
        }
    }
    
    @IBAction func launchWebsite(_ sender: Any) {
        if let url = URL(string: (detailItem?.infoURL)!) {
            webViewPresented = true
            reloadPics = picsLoading
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
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
            reloadPics = picsLoading
            if let theImageView = self.pictureScrollView.viewWithTag(tagNo) as? UIImageView {
//                print("Found image")
                destViewController.img =  theImageView.image
            } 

        }
    }

}
