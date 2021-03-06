//
//  hqMapViewController.swift
//  skyQuest
//
//  Created by Jessica M Cavazos Erhard on 9/29/16.
//  Copyright © 2016 itesm. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import MessageUI
import Alamofire

class hqMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate,  MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        mapView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(getData), userInfo: nil, repeats: true)
        print(timer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendLocationA(_ sender: AnyObject) {
        sendLocationSMS(sender: "1", point: user.pins["BalloonA"]!)
    }
    
    @IBAction func sendLocationB(_ sender: AnyObject) {
        sendLocationSMS(sender: "2", point: user.pins["BalloonB"]!)
    }
    
    //MARK: Sending Message
    /*
     If sender is a Ranger, you use 3 or 4 as id. -> Reciver has to be HQ.
     If sender is HQ, you use 1 or 2 depending on the balloon.
     */
    func sendLocationSMS(sender: String, point: MKPointAnnotation) {
        let messageVC = MFMessageComposeViewController()
        let myUrl = NSURL(string: "SQ://\(point.coordinate.latitude)//\(point.coordinate.longitude)//\(sender)") as! URL
        messageVC.addAttachmentURL(myUrl, withAlternateFilename: "Hello")
        messageVC.body = "SQ://\(point.coordinate.latitude)//\(point.coordinate.longitude)//\(sender)"
        messageVC.messageComposeDelegate = self
        
        self.present(messageVC, animated: false, completion: nil)
    }

    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        print(result)
        self.dismiss(animated: true, completion: nil)
    }
    
    //Drop pin
    func dropPin (location: CLLocationCoordinate2D, pinTitle: String) {
        let dropPin = CustomAnnotation()
        dropPin.coordinate = location
        dropPin.title = pinTitle
        mapView.addAnnotation(dropPin)
        user.pins[pinTitle] = dropPin
        centertoMidPoint()
    }
    
    //Center between x points
    func centertoMidPoint() {
        if mapView.annotations.count == 0 {
            return
        }
        var topLeftCoord: CLLocationCoordinate2D = CLLocationCoordinate2D()
        topLeftCoord.latitude = -90
        topLeftCoord.longitude = 180
        var bottomRightCoord: CLLocationCoordinate2D = CLLocationCoordinate2D()
        bottomRightCoord.latitude = 90
        bottomRightCoord.longitude = -180
        for annotation: MKAnnotation in mapView.annotations {
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude)
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude)
        }
        
        var region: MKCoordinateRegion = MKCoordinateRegion()
        region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5
        region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5
        region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.4
        region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.4
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "demo")
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "demo")
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        if annotation.title! == "BalloonA" {
            annotationView!.image = UIImage(named: "balloon-a")
        } else if annotation.title! == "BalloonB" {
            annotationView!.image = UIImage(named: "balloon-b")
        } else if annotation.title! == "RangerA" {
            annotationView!.image = UIImage(named: "worker-female")
        } else {
            annotationView!.image = UIImage(named: "worker-male")
        }
        
        return annotationView
    }

    
    //Get Information for pins
    func getData(){
        let todoEndpoint: String = "http://data.sparkfun.com/output/VGxEGjpqrxHaWvDLNLD6.json"
        Alamofire.request(todoEndpoint).responseJSON { response in
            //to get JSON return value
            if let result = response.result.value {
                var balA = false, balB = false, raA = false , raB = false
                let JSON = result as! NSArray
                
                //For every object in the response
                for object in JSON{
                    let newObject = object as! NSDictionary //Cast AnyObject to NSDictionary
                    
                    //Create Coordenates with data
                    
                    let latString = (newObject["lat"] as! String).trimmingCharacters(in: .whitespaces)
                    let lonString = (newObject["lon"] as! String).trimmingCharacters(in: .whitespaces)
                    let coor = CLLocationCoordinate2D(latitude: Double(latString)!, longitude: Double(lonString)!)
                    
                    //Get the first coordenate of every id.
                    if (newObject["id"] as! String == "1" && !balA){
                        balA = true
                        if user.pins["BalloonA"] == nil {
                            self.dropPin(location: coor, pinTitle: "BalloonA")
                        } else if user.pins["BalloonA"]?.coordinate.latitude != coor.latitude ||  user.pins["BalloonA"]?.coordinate.longitude != coor.longitude{
                            user.changepinLocation(pinTitle: "BalloonA", lat: "\(coor.latitude)", lon: "\(coor.longitude)")
                        }
                        print(object as! NSDictionary)
                    } else if (newObject["id"] as! String == "2" && !balB){
                        balB = true
                        if user.pins["BalloonB"] == nil {
                            self.dropPin(location: coor, pinTitle: "BalloonB")
                        } else if user.pins["BalloonA"]?.coordinate.latitude != coor.latitude ||  user.pins["BalloonB"]?.coordinate.longitude != coor.longitude{
                            user.changepinLocation(pinTitle: "BalloonB", lat: "\(coor.latitude)", lon: "\(coor.longitude)")
                        }
                        print(object as! NSDictionary)
                    } else if (newObject["id"] as! String == "3" && !raA){
                        raA = true
                        if user.pins["RangerA"] == nil {
                            self.dropPin(location: coor, pinTitle: "RangerA")
                        } else if user.pins["RangerA"]?.coordinate.latitude != coor.latitude ||  user.pins["RangerA"]?.coordinate.longitude != coor.longitude{
                            user.changepinLocation(pinTitle: "RangerA", lat: "\(coor.latitude)", lon: "\(coor.longitude)")
                        }
                        print(object as! NSDictionary)
                    } else if (newObject["id"] as! String == "4" && !raB){
                        raB = true
                        if user.pins["RangerB"] == nil {
                            self.dropPin(location: coor, pinTitle: "RangerB")
                        } else if user.pins["RangerB"]?.coordinate.latitude != coor.latitude ||  user.pins["RangerB"]?.coordinate.longitude != coor.longitude{
                            user.changepinLocation(pinTitle: "RangerB", lat: "\(coor.latitude)", lon: "\(coor.longitude)")
                        }
                        print(object as! NSDictionary)
                    }
                    
                    //If all pins are drop stop searching
                    if (balA && balB && raA && raB){
                        break
                    }
                }
            }
        }
    }
}


