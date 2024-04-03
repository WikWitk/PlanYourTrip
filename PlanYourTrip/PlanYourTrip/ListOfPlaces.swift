//
//  ListOfPlaces.swift
//  PlanYourTrip
//
//  Created by Wiktor Witkowski on 04/11/2023.
//

import UIKit
import CoreData


class ListOfPlaces: UIViewController, UITableViewDelegate, UITableViewDataSource {
  

    @IBOutlet weak var listOfPlaces: UITableView!
    var placeArray = [String]()
    var placeIdArray = [UUID]()
    var selectedPlace = ""
    var selectedPlaceId : UUID?

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addPlace))
        
        
        listOfPlaces.delegate = self
        listOfPlaces.dataSource = self
        
        
        getData()
    }
    
   
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    
    @objc func getData(){
        

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetch.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetch)
            
            if results.count > 0{
                
                self.placeArray.removeAll(keepingCapacity: false)
                self.placeIdArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject]{
                    if let name = result.value(forKey: "name")  as? String{
                        self.placeArray.append(name)
                    }
                    
                    if let id = result.value(forKey: "id")  as? UUID{
                        self.placeIdArray.append(id)
                    }


                    listOfPlaces.reloadData()
                    
                    
                }
            }
            
        }catch{
            print("error")
        }
        
    }
    
    @objc func addPlace(){
        selectedPlace = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = placeArray[indexPath.row]
        return cell
        
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPlace = placeArray[indexPath.row]
        selectedPlaceId = placeIdArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let  destinationVC = segue.destination as! ViewController
            destinationVC.chosenPlace = selectedPlace
            destinationVC.chosenPlaceId = selectedPlaceId
            
        } 
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
           
            
            let idString = placeIdArray[indexPath.row].uuidString
            
            fetch.predicate = NSPredicate(format: "id = %@", idString)
            fetch.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetch)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let id = result.value(forKey: "id") as? UUID{
                            if id == placeIdArray[indexPath.row]{
                                context.delete(result)
                                self.placeArray.remove(at: indexPath.row)
                                self.placeIdArray.remove(at: indexPath.row)
                                self.listOfPlaces.reloadData()
                                do{
                                    try context.save()
                                }catch{
                                    print("Error")
                                }
                                break
                            }
                            
                        }
                    }
                }
                
            }catch{
                print("Error")
            }
            
            
            
            
            
            
        }
    }
    
  
    

}
