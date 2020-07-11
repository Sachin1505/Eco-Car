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
    
    let pm = ProxyManager.sharedManager
    
    @IBOutlet weak var engineStatus: UILabel!
    @IBOutlet weak var odometer: UILabel!
    @IBOutlet weak var remainingFuel: UILabel!
    @IBOutlet weak var vinLbl: UILabel!
    @IBOutlet weak var finalResult: UILabel!

    var startTime = String()
    var endTime = String()
    
    var startO = Double()
    var endO = Double()
    
    var startF = Double()
    var endF = Double()
    
    var fuelValue = Double()
    var odoValue = Double()
    
    var vinNum = String()
    var vehicleInfo = SDLVehicleType()
    
    let api = ApiSupporter()
        

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Started")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.uiInfoUpdate), name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil)
        

    }
    
    
    @objc func uiInfoUpdate(notification: NSNotification) {

        guard let info = notification.userInfo as? [String : Any] else { return }

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
                    
                    self.startTime = self.getCurrentDateTime()
                    
                } else if self.engineStatus.text == "OFF" {
                    self.endO = self.odoValue
                    self.endF = self.fuelValue
                    self.finalCalulations()
                    
                    self.endTime = self.getCurrentDateTime()
                }

            }
            
            if let vin = info["vin"] as? String {

                self.vinLbl.text = "\(vin)"
                self.vinNum = vin
                
            }
            
            if let vehicleInfo = info["vehicleInfo"] as? SDLVehicleType {
                print("vehicleInfo: \(vehicleInfo)")
                
                // TODO:- Display Vehicle Information here
                
                self.vehicleInfo = vehicleInfo
                

                
            }

            print("info: \(info)")
        }
        
        
    }
    
    
    func finalCalulations() {
        
        print("""
            finalOdo : \(endO) - \(startO)
            finalFuel : \(startF) - \(endF)
            """)
        let tripDistance = endO - startO
        let fuelUsed = (startF - endF)/3785411.784
        let tripAvg = tripDistance/fuelUsed
        print("finalOdo : \(tripDistance)\nfinalFuel : \(fuelUsed)")
        
        let result = "Car has run : \(Float(tripDistance)) mile(s) in \(Float(fuelUsed)) gallon(s)\nAverage is : \(tripAvg) mpg"
        DispatchQueue.main.async {
            
            self.showAlert(msg: result)
            DispatchQueue.main.async {
                self.pm.sdlManager.screenManager.textField2 = result
            }
            
            self.sendTripDetails(fuelUsed: fuelUsed, tripAvg: tripAvg)
            self.sendVehicleInfo()
        }
    }
    
    
    func sendTripDetails(fuelUsed: Double, tripAvg: Double) {
        // MARK: Sending Trip Details
        let params1 = "tag=addcartripdetails&regId=1&carId=1&startodomter=\(self.startO)&endodometer=\(self.endO)&fuelused=\(fuelUsed)&tripavg=\(tripAvg)&tripstartdatetime=\(self.startTime)&tripenddatetime=\(self.endTime)"

        api.apiCalls(url: carUrl, parameters: params1) { (response) in

            print("Trip Details Sent: \(response)")

        }
    }
    
    func sendVehicleInfo() {
        // MARK: Sending Vehicle Data
        let vin = self.vinNum
        let make = (self.vehicleInfo.make != nil ? self.vehicleInfo.make : "No Data")
        let model = (self.vehicleInfo.model != nil ? self.vehicleInfo.model : "No Data")
        let modelYear = (self.vehicleInfo.modelYear != nil ? self.vehicleInfo.modelYear : "No Data")

        let params2 = "tag=usercar&regId=1&vin=\(vin)&make=\(make!)&model=\(model!)&modelyear=\(modelYear!)"

        api.apiCalls(url: carUrl, parameters: params2) { (response) in

            print("Vehicle Data Sent: \(response)")

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
    
    
    func getCurrentDateTime() -> String {
        let thisTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: thisTime)
    }
    
    
    @IBAction func gotoProfile(_ sender: UIBarButtonItem) {
        
        let profile = storyboard?.instantiateViewController(withIdentifier: "UserProfileVC") as! UserProfileVC
        navigationController?.pushViewController(profile, animated: true)
        
    }
    
}




