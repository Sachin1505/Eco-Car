//
//  ViewController.swift
//  Eco Car
//
//  Created by Sachin Bhandari on 23/06/20.
//  Copyright © 2020 Sachin Bhandari. All rights reserved.
//

import UIKit
import SmartDeviceLink

class ViewController: UIViewController {
    
    @IBOutlet weak var engineStatus: UILabel!
    @IBOutlet weak var odometer: UILabel!
    @IBOutlet weak var remainingFuel: UILabel!
    @IBOutlet weak var vinLbl: UILabel!
    @IBOutlet weak var finalResult: UILabel!

    
    var startO = Double()
    var endO = Double()
    
    var startF = Double()
    var endF = Double()
    
    var fuelValue = Double()
    var odoValue = Double()
    

//    fileprivate var sdlManager: SDLManager!
    
    let pm = ProxyManager.self


    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Started")
        
//        self.odometer.text = "\(pm.sharedManager.odometerValue) mile(s)"
        
//        perform(#selector(showAlert), with: self, afterDelay: 3.0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.uiInfoUpdate), name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil)


    }
    
    
    @objc func uiInfoUpdate(notification: NSNotification) {

        if let info = notification.userInfo as? [String : Any] {

            DispatchQueue.main.async {

                if let odoVal = info["odometer"] as? Double {
                    
                    self.odometer.text = "\(odoVal) mile(s)"
                    self.odoValue = odoVal
                    
                }
                                
                if let fuel = info["fuel"] as? Double {
                    
                    self.remainingFuel.text = "\(fuel) gallon(s)"
                    self.fuelValue = fuel
                    
                }
                
                if let engineStatus = info["engineStatus"] as? String {
                
                    self.engineStatus.text = "\(engineStatus)"
                    if self.engineStatus.text == "START" {
                        self.startO = self.odoValue
                        self.startF = self.fuelValue
                    } else if self.engineStatus.text == "OFF" {
                        self.endO = self.odoValue
                        self.endF = self.fuelValue
                        self.finalCalulations()
                    }

                }
                
                if let vin = info["vin"] as? String {
                    print("Vin : \(vin)")
                    self.vinLbl.text = "\(vin)"
                    
                }
                
                if let vehicleInfo = info["vehicleInfo"] as? SDLVehicleType {
                    print("vehicleInfo: \(vehicleInfo)")
//                    print("vehicleInfo: \(vehicleInfo.make!)") // Name of Manufacturer
//                    print("vehicleInfo: \(vehicleInfo.model!)") // Model Name
//                    print("vehicleInfo: \(vehicleInfo.modelYear!)") // Moder Year
//                    print("vehicleInfo: \(vehicleInfo.trim!)") // trim of the vehicle
                    
                    // TODO:- Display Vehicle Information here
                    
                }

                print("info: \(info)")
            }
        }
        
    }
    
    
    func finalCalulations() {
        
        print("""
            finalOdo : \(endO) - \(startO)
            finalFuel : \(startF) - \(endF)
            """)
        let finalOdo = endO - startO
        let finalFuel = startF - endF
        print("finalOdo : \(finalOdo)\nfinalFuel : \(finalFuel)")
        
        let result = "Car has run : \(Float(finalOdo)) mile(s) in \(Float(finalFuel)) gallon(s)\nAverage is : \(finalOdo/finalFuel) mpg"
        DispatchQueue.main.async {
            
            self.showAlert(msg: result)
            
        }
    }
    
    
    
    @objc func showAlert(msg: String) {
        let alert = UIAlertController(title: "Alert", message: msg, preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "Dismiss", style: .default) { (action) in
            self.finalResult.isHidden = false
            self.finalResult.text = msg

        }
        alert.addAction(dismiss)
        self.present(alert, animated: true, completion: nil)
    }
}

