//
//  CoreDataStack.swift
//  Holy Places
//
//  Created by Derek Cordon on 2/27/23.
//  Copyright © 2023 Derek Cordon. All rights reserved.
//

import CoreData

class CoreDataStack {

  // MARK: Properties
  private let modelName = "HolyData"

  lazy var mainContext: NSManagedObjectContext = {
    return self.storeContainer.viewContext
  }()

  lazy var storeContainer: NSPersistentContainer = {

    let container = NSPersistentContainer(name: self.modelName)
    container.loadPersistentStores { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }

    return container
  }()

  // MARK: Initializers
  //init(modelName: String) {
  //  self.modelName = modelName
  //}
}

// MARK: Internal
extension CoreDataStack {

  func saveContext () {
    guard mainContext.hasChanges else { return }

    do {
      try mainContext.save()
    } catch let nserror as NSError {
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }
}
