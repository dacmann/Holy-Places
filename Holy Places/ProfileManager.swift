//
//  ProfileManager.swift
//  Holy Places
//
//  Created by Derek Cordon on 3/14/26.
//

import Foundation
import CoreData
import WidgetKit

class ProfileManager {
    
    static let shared = ProfileManager()
    static let profileMaxCount = 10
    
    static let availableIcons = [
        "person.fill",
        "tree.fill",
        "star.fill",
        "heart.fill",
        "leaf.fill",
        "sun.max.fill",
        "moon.fill",
        "flame.fill",
        "bolt.fill",
        "crown.fill",
        "bird.fill",
        "fish.fill",
        "globe.americas.fill",
        "hands.sparkles.fill",
        "book.fill",
        "mountain.2.fill",
        "sparkles",
        "shield.fill"
    ]
    
    static let profileDidChangeNotification = Notification.Name("ProfileDidChange")
    
    private var context: NSManagedObjectContext {
        return ad.persistentContainer.viewContext
    }
    
    // MARK: - CRUD
    
    func createProfile(name: String, iconName: String = "person.fill") -> NSManagedObject? {
        let allProfiles = allProfiles()
        guard allProfiles.count < ProfileManager.profileMaxCount else {
            print("Profile limit of \(ProfileManager.profileMaxCount) reached")
            return nil
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Profile", in: context) else { return nil }
        let profile = NSManagedObject(entity: entity, insertInto: context)
        let newId = UUID().uuidString
        profile.setValue(newId, forKey: "profileId")
        profile.setValue(name, forKey: "name")
        profile.setValue(false, forKey: "isDefault")
        profile.setValue(iconName, forKey: "iconName")
        profile.setValue(Date(), forKey: "createdDate")
        profile.setValue(Int16(0), forKey: "annualVisitGoal")
        profile.setValue(Int16(0), forKey: "annualBaptismGoal")
        profile.setValue(Int16(0), forKey: "annualInitiatoryGoal")
        profile.setValue(Int16(0), forKey: "annualEndowmentGoal")
        profile.setValue(Int16(0), forKey: "annualSealingGoal")
        profile.setValue(false, forKey: "excludeNonOrdinanceVisits")
        
        do {
            try context.save()
            return profile
        } catch {
            print("Error creating profile: \(error)")
            context.rollback()
            return nil
        }
    }
    
    func renameProfile(_ profile: NSManagedObject, to newName: String) {
        profile.setValue(newName, forKey: "name")
        saveContext()
    }
    
    func updateProfileIcon(_ profile: NSManagedObject, iconName: String) {
        profile.setValue(iconName, forKey: "iconName")
        saveContext()
    }
    
    func deleteProfile(_ profile: NSManagedObject) {
        guard let profileId = profile.value(forKey: "profileId") as? String else { return }
        let isDefault = profile.value(forKey: "isDefault") as? Bool ?? false
        if isDefault { return }
        
        // Delete all visits for this profile
        let visitFetch: NSFetchRequest<Visit> = Visit.fetchRequest()
        visitFetch.predicate = NSPredicate(format: "profileId == %@", profileId)
        
        do {
            let visits = try context.fetch(visitFetch)
            for visit in visits {
                context.delete(visit)
            }
            context.delete(profile)
            try context.save()
            
            // If the deleted profile was active, switch to default
            if activeProfileId == profileId {
                if let defaultProfile = defaultProfile() {
                    setActiveProfile(defaultProfile)
                }
            }
        } catch {
            print("Error deleting profile: \(error)")
            context.rollback()
        }
    }
    
    // MARK: - Queries
    
    func allProfiles() -> [NSManagedObject] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Profile")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "isDefault", ascending: false),
            NSSortDescriptor(key: "createdDate", ascending: true)
        ]
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching profiles: \(error)")
            return []
        }
    }
    
    func defaultProfile() -> NSManagedObject? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Profile")
        fetchRequest.predicate = NSPredicate(format: "isDefault == YES")
        fetchRequest.fetchLimit = 1
        return try? context.fetch(fetchRequest).first
    }
    
    func activeProfile() -> NSManagedObject? {
        guard let profileId = activeProfileId else {
            return defaultProfile()
        }
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Profile")
        fetchRequest.predicate = NSPredicate(format: "profileId == %@", profileId)
        fetchRequest.fetchLimit = 1
        if let profile = try? context.fetch(fetchRequest).first {
            return profile
        }
        return defaultProfile()
    }
    
    func activeProfileName() -> String {
        return activeProfile()?.value(forKey: "name") as? String ?? "Me"
    }
    
    func activeProfileIconName() -> String {
        return activeProfile()?.value(forKey: "iconName") as? String ?? "person.fill"
    }
    
    func profileById(_ profileId: String) -> NSManagedObject? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Profile")
        fetchRequest.predicate = NSPredicate(format: "profileId == %@", profileId)
        fetchRequest.fetchLimit = 1
        return try? context.fetch(fetchRequest).first
    }
    
    // MARK: - Active Profile
    
    func setActiveProfile(_ profile: NSManagedObject) {
        guard let profileId = profile.value(forKey: "profileId") as? String else { return }
        activeProfileId = profileId
        UserDefaults.standard.set(profileId, forKey: "activeProfileId")
        
        // Load goals from this profile
        ad.loadGoalsFromActiveProfile()
        
        // Refresh visit data
        ad.needsVisitRefresh = true
        ad.getVisits()
        
        NotificationCenter.default.post(name: ProfileManager.profileDidChangeNotification, object: nil)
    }
    
    func saveGoalsToActiveProfile() {
        guard let profile = activeProfile() else { return }
        profile.setValue(Int16(annualVisitGoal), forKey: "annualVisitGoal")
        profile.setValue(Int16(annualBaptismGoal), forKey: "annualBaptismGoal")
        profile.setValue(Int16(annualInitiatoryGoal), forKey: "annualInitiatoryGoal")
        profile.setValue(Int16(annualEndowmentGoal), forKey: "annualEndowmentGoal")
        profile.setValue(Int16(annualSealingGoal), forKey: "annualSealingGoal")
        profile.setValue(excludeNonOrdinanceVisits, forKey: "excludeNonOrdinanceVisits")
        saveContext()
    }
    
    // MARK: - Visit Count
    
    func visitCount(for profile: NSManagedObject) -> Int {
        guard let profileId = profile.value(forKey: "profileId") as? String else { return 0 }
        let fetchRequest: NSFetchRequest<Visit> = Visit.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profileId == %@", profileId)
        return (try? context.count(for: fetchRequest)) ?? 0
    }
    
    // MARK: - Helpers
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
