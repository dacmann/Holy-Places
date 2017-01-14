//
//  TableViewController.swift
//  Holy Places
//
//  Created by Derek Cordon on 1/7/17.
//  Copyright © 2017 Derek Cordon. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    
    var sections : [(index: Int, length :Int, title: String)] = Array()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sort by
        //temples.sort { $0.templeOrder < $1.templeOrder }
        
        //create index for array
        var index = 0
        var commonPrefix = ""
        for i in (0 ..< (temples.count + 1) ) {
            if (temples.count != i){
                commonPrefix = temples[i].templeName.commonPrefix(with: temples[index].templeName, options: .caseInsensitive)
            }
            //print(temples.count)
            if ( commonPrefix.isEmpty || temples.count == i) {
                let string = temples[index].templeName.uppercased();
                let firstCharacter = string[string.startIndex]
                let title = "\(firstCharacter)"
                let newSection = (index: index, length: i - index, title: title)
                sections.append(newSection)
                index = i;
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].length
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let temple = temples[sections[indexPath.section].index + indexPath.row]
        
        cell.textLabel?.text = temple.templeName
        cell.detailTextLabel?.text = temple.templeSnippet

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections.map {$0.title}
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let temple = temples[sections[indexPath.section].index + indexPath.row]
                let controller = (segue.destination as! DetailViewController)
                controller.detailItem = temple
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

}
