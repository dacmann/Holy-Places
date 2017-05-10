//
//  AppDelegate.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import StoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {

    var window: UIWindow?
    var settings: Settings?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        SKPaymentQueue.default().add(self)
        
        // Change the font and color for the navigation Bar text
        let navbarFont = UIFont(name: "Baskerville", size: 20) ?? UIFont.systemFont(ofSize: 20)
        let barbuttonFont = UIFont(name: "Baskerville", size: 17) ?? UIFont.systemFont(ofSize: 17)
        
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: navbarFont, NSForegroundColorAttributeName:UIColor.ocean()]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: barbuttonFont, NSForegroundColorAttributeName:UIColor.ocean()], for: UIControlState.normal)
        UINavigationBar.appearance().tintColor = UIColor.ocean()
        UITabBar.appearance().tintColor = UIColor.ocean()
        
        //Load any saved settings
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        
        do {
            //go get the results
            let searchResults = try context.fetch(fetchRequest)
            
            if searchResults.count > 0 {
                
                for setting in searchResults as [Settings] {
                    settings = setting
                    altLocStreet = (settings?.altLocStreet)!
                    altLocCity = (settings?.altLocCity)!
                    altLocState = (settings?.altLocState)!
                    altLocPostalCode = (settings?.altLocPostalCode)!
                    locationSpecific = (settings?.altLocation)!
                    coordAltLocation = CLLocation(latitude: (settings?.altLocLatitude)!, longitude: (settings?.altLocLongitude)!)
                    placeSortRow = Int((settings?.placeSortRow)!)
                    placeFilterRow = Int((settings?.placeFilterRow)!)
                    visitSortRow = Int((settings?.visitSortRow)!)
                    visitFilterRow = Int((settings?.visitFilterRow)!)
                    annualVisitGoal = Int((settings?.annualVisitGoal)!)
                }
            } else {
                annualVisitGoal = 0
                // nothing to do here
            }
        } catch {
            print("Error with request: \(error)")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // Save settings
        if settings == nil {
            settings = NSEntityDescription.insertNewObject(forEntityName: "Settings", into: persistentContainer.viewContext) as? Settings
        }
        settings?.altLocation = locationSpecific
        settings?.altLocStreet = altLocStreet
        settings?.altLocCity = altLocCity
        settings?.altLocState = altLocState
        settings?.altLocPostalCode = altLocPostalCode
        if coordAltLocation != nil {
            settings?.altLocLatitude = coordAltLocation.coordinate.latitude
            settings?.altLocLongitude = coordAltLocation.coordinate.longitude
        }
        settings?.annualVisitGoal = Int16(annualVisitGoal)
        settings?.placeFilterRow = Int16(placeFilterRow)
        settings?.placeSortRow = Int16(placeSortRow)
        settings?.visitFilterRow = Int16(visitFilterRow)
        settings?.visitSortRow = Int16(visitSortRow)
        
        SKPaymentQueue.default().remove(self)
        self.saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        

    }
    
    //MARK:- Payment function
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Remove transaction from queue
                SKPaymentQueue.default().finishTransaction(transaction)
                // Alert the user
                let topWindow: UIWindow = UIWindow(frame: UIScreen.main.bounds)
                topWindow.rootViewController = UIViewController()
                topWindow.windowLevel = UIWindowLevelAlert + 1
                let alert: UIAlertController =  UIAlertController(title: "Thanks for tip!", message: "I really appreciate your support.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(action: UIAlertAction) -> Void in
                    topWindow.isHidden = true
                }))
                topWindow.makeKeyAndVisible()
                topWindow.rootViewController?.present(alert, animated: true, completion: { _ in })
                break
            case .failed:
                // Determine reason for failure
                let message = transaction.error?.localizedDescription
                // Remove transaction from queue
                SKPaymentQueue.default().finishTransaction(transaction)
                // Alert the user
                let topWindow: UIWindow = UIWindow(frame: UIScreen.main.bounds)
                topWindow.rootViewController = UIViewController()
                topWindow.windowLevel = UIWindowLevelAlert + 1
                let alert: UIAlertController =  UIAlertController(title: "Purchase Failed", message: (message)!, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(action: UIAlertAction) -> Void in
                    topWindow.isHidden = true
                }))
                topWindow.makeKeyAndVisible()
                topWindow.rootViewController?.present(alert, animated: true, completion: { _ in })
                break
            default:
                break
            }
        }
        
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "HolyData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

