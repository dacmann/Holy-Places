//
//  ProfileManagementVC.swift
//  Holy Places
//
//  Created by Derek Cordon on 3/14/26.
//

import UIKit
import CoreData

class ProfileManagementVC: UITableViewController {
    
    private var profiles: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manage Profiles"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileCell")
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProfileTapped))
        navigationItem.rightBarButtonItem = addButton
        
        reloadProfiles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadProfiles()
    }
    
    private func reloadProfiles() {
        profiles = ProfileManager.shared.allProfiles()
        navigationItem.rightBarButtonItem?.isEnabled = profiles.count < ProfileManager.profileMaxCount
        tableView.reloadData()
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        let profile = profiles[indexPath.row]
        let name = profile.value(forKey: "name") as? String ?? ""
        let iconName = profile.value(forKey: "iconName") as? String ?? "person.fill"
        let isDefault = profile.value(forKey: "isDefault") as? Bool ?? false
        let visitCount = ProfileManager.shared.visitCount(for: profile)
        let profileId = profile.value(forKey: "profileId") as? String ?? ""
        
        var config = cell.defaultContentConfiguration()
        config.text = name
        config.textProperties.font = UIFont(name: "Baskerville", size: 17) ?? .systemFont(ofSize: 17)
        config.secondaryText = "\(visitCount) visit\(visitCount == 1 ? "" : "s")\(isDefault ? " · Default" : "")"
        config.secondaryTextProperties.font = UIFont(name: "Baskerville", size: 13) ?? .systemFont(ofSize: 13)
        config.secondaryTextProperties.color = .secondaryLabel
        config.image = UIImage(systemName: iconName)
        config.imageProperties.tintColor = UIColor(named: "BaptismsBlue") ?? .systemBlue
        
        cell.contentConfiguration = config
        cell.accessoryType = (profileId == activeProfileId) ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEditAlert(for: profiles[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let isDefault = profiles[indexPath.row].value(forKey: "isDefault") as? Bool ?? false
        return !isDefault
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let profile = profiles[indexPath.row]
        let isDefault = profile.value(forKey: "isDefault") as? Bool ?? false
        if isDefault { return nil }
        
        let name = profile.value(forKey: "name") as? String ?? "this profile"
        let visitCount = ProfileManager.shared.visitCount(for: profile)
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            let alert = UIAlertController(
                title: "Delete \(name)?",
                message: "This will permanently remove \(name) and all \(visitCount) of their visits. Consider exporting their visits first as a backup.\n\nThis cannot be undone.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                ProfileManager.shared.deleteProfile(profile)
                self?.reloadProfiles()
                completion(true)
            })
            self?.present(alert, animated: true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    // MARK: - Add Profile
    
    @objc private func addProfileTapped() {
        guard profiles.count < ProfileManager.profileMaxCount else {
            let alert = UIAlertController(title: "Limit Reached", message: "You can have up to \(ProfileManager.profileMaxCount) profiles.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        showProfileEditor(name: "", iconName: "star.fill", isNew: true, profile: nil)
    }
    
    // MARK: - Edit Profile
    
    private func showEditAlert(for profile: NSManagedObject) {
        let name = profile.value(forKey: "name") as? String ?? ""
        let iconName = profile.value(forKey: "iconName") as? String ?? "person.fill"
        showProfileEditor(name: name, iconName: iconName, isNew: false, profile: profile)
    }
    
    private func showProfileEditor(name: String, iconName: String, isNew: Bool, profile: NSManagedObject?) {
        let editorVC = ProfileEditorVC(name: name, iconName: iconName, isNew: isNew)
        editorVC.onSave = { [weak self] newName, newIcon in
            if isNew {
                _ = ProfileManager.shared.createProfile(name: newName, iconName: newIcon)
            } else if let profile = profile {
                ProfileManager.shared.renameProfile(profile, to: newName)
                ProfileManager.shared.updateProfileIcon(profile, iconName: newIcon)
            }
            self?.reloadProfiles()
        }
        let nav = UINavigationController(rootViewController: editorVC)
        present(nav, animated: true)
    }
}

// MARK: - Profile Editor (name + icon picker)

class ProfileEditorVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var onSave: ((String, String) -> Void)?
    
    private let nameField = UITextField()
    private var selectedIcon: String
    private let isNew: Bool
    private var collectionView: UICollectionView!
    
    init(name: String, iconName: String, isNew: Bool) {
        self.selectedIcon = iconName
        self.isNew = isNew
        super.init(nibName: nil, bundle: nil)
        nameField.text = name
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = isNew ? "New Profile" : "Edit Profile"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        
        setupUI()
    }
    
    private func setupUI() {
        nameField.placeholder = "Profile Name"
        nameField.font = UIFont(name: "Baskerville", size: 17) ?? .systemFont(ofSize: 17)
        nameField.borderStyle = .roundedRect
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.becomeFirstResponder()
        
        let nameLabel = UILabel()
        nameLabel.text = "Name"
        nameLabel.font = UIFont(name: "Baskerville", size: 15) ?? .systemFont(ofSize: 15)
        nameLabel.textColor = .secondaryLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = "Icon"
        iconLabel.font = UIFont(name: "Baskerville", size: 15) ?? .systemFont(ofSize: 15)
        iconLabel.textColor = .secondaryLabel
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .secondarySystemGroupedBackground
        collectionView.layer.cornerRadius = 10
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(IconCell.self, forCellWithReuseIdentifier: "IconCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(nameLabel)
        view.addSubview(nameField)
        view.addSubview(iconLabel)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            nameField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 44),
            
            iconLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 24),
            iconLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            collectionView.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ProfileManager.availableIcons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IconCell", for: indexPath) as! IconCell
        let icon = ProfileManager.availableIcons[indexPath.item]
        cell.configure(iconName: icon, isSelected: icon == selectedIcon)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIcon = ProfileManager.availableIcons[indexPath.item]
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            let alert = UIAlertController(title: "Name Required", message: "Please enter a name for this profile.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        onSave?(name, selectedIcon)
        dismiss(animated: true)
    }
}

// MARK: - Icon Cell

private class IconCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(named: "BaptismsBlue") ?? .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        contentView.layer.cornerRadius = 8
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(iconName: String, isSelected: Bool) {
        imageView.image = UIImage(systemName: iconName)
        contentView.backgroundColor = isSelected
            ? UIColor(named: "BaptismsBlue")?.withAlphaComponent(0.2) ?? UIColor.systemBlue.withAlphaComponent(0.2)
            : .clear
        contentView.layer.borderWidth = isSelected ? 2 : 0
        contentView.layer.borderColor = (UIColor(named: "BaptismsBlue") ?? UIColor.systemBlue).cgColor
    }
}
