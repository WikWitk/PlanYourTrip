//
//  ViewController.swift
//  PlanYourTrip
//
//  Created by Wiktor Witkowski on 03/11/2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    

    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var mapView: MKMapView!

    var locationManager = CLLocationManager()
    var chosenLongitude = Double()
    var chosenLatitude = Double()
    var chosenPlace = ""
    var chosenPlaceId : UUID?
    
    var annotationName = ""
    var annotationComment = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        //desiredAccuracy -> wymagana dokładność
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let gestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer1)
 
        
        if chosenPlace != "" {
            
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            let idString = chosenPlaceId!.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject]{
                        
                        if let name = result.value(forKey: "name") as? String{
                            annotationName = name
                            
                            if let comment = result.value(forKey: "comment") as? String{
                                annotationComment = comment
                                
                                
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationName
                                        annotation.subtitle = annotationComment
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameField.text = annotationName
                                        commentField.text = annotationComment
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
            }catch{
                print("error")
                
            }
            
            
            
            
        }else{

        }
        
      
    
        
    }
        
        
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
            
            if gestureRecognizer.state == .began {
                
                let touchedPoint = gestureRecognizer.location(in: self.mapView)
                let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                
                chosenLatitude = touchedCoordinates.latitude
                chosenLongitude = touchedCoordinates.longitude
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinates
                annotation.title = nameField.text
                annotation.subtitle = commentField.text
                
                self.mapView.addAnnotation(annotation)
                
               
            }
            

    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if chosenPlace == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            
        }else{
            
        }
        
        
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation{
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.red
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
            
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
        
        
    }
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chosenPlace != ""{
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                if let placemark = placemarks {
                    
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationName
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                    
                    
                }
            }
        }
    }
    
    

    
    @IBAction func saveBtn(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameField.text, forKey: "name")
        newPlace.setValue(commentField.text, forKey: "comment")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        
        
       
        
        do{
            try context.save()
            print("success")
            
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    

}

