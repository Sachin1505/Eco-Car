//
//  ProxyManager.swift
//  Eco Car
//
//  Created by Sachin Bhandari on 23/06/20.
//  Copyright © 2020 Sachin Bhandari. All rights reserved.
//

import Foundation
import SmartDeviceLink


class ProxyManager: NSObject {
    
//TODO:- Change appID, port and ipAddress here.
    private let appName = "Eco Car"
    private let appId = "1505"
    private let appIpAddress = "m.sdl.tools"
    private let appPort: UInt16 = 12302
    

    // Manager
    var sdlManager = SDLManager()

    // Singleton
    static let sharedManager = ProxyManager()

    fileprivate var firstHMILevel: SDLHMILevel = .none



    private override init() {
        super.init()
        firstHMILevel = .none
        // Used for USB Connection
//        let lifecycleConfiguration = SDLLifecycleConfiguration(appName: appName, fullAppId: appId)

        // Used for TCP/IP Connection
        let lifecycleConfiguration = SDLLifecycleConfiguration(
                   appName: appName,
                   fullAppId: appId,
                   ipAddress: appIpAddress,
                   port: appPort
        )
        
        // App icon image
        if let appImage = UIImage(named: "carLogo") {
            let appIcon = SDLArtwork(image: appImage, name: "carLogo", persistent: true, as: .PNG)
            lifecycleConfiguration.appIcon = appIcon
        }

        lifecycleConfiguration.shortAppName = appName
        
        let lockScreenConfiguration = SDLLockScreenConfiguration.enabled()
        lockScreenConfiguration.displayMode = .requiredOnly


        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: lockScreenConfiguration, logging: .default(), fileManager: .default(), encryption: nil)

        sdlManager = SDLManager(configuration: configuration, delegate: self)
        sdlManager.delegate = self

        // Gets Updates from the Car Device
        self.sdlManager.subscribe(to: .SDLDidReceiveVehicleData, observer: self, selector: #selector(self.vehicleDataAvailable(_:)))
        
        sdlManager.screenManager.textField1 = "Welcome"

    }

    func connect() {
        // Start watching for a connection with a SDL Core
        sdlManager.start { (success, error) in
            if success {

                print("SDL Connected Successfully")

            }
        }
    }

}

//MARK:- SDLManagerDelegate
extension ProxyManager: SDLManagerDelegate {
  func managerDidDisconnect() {
    print("Manager disconnected!")
    
    DispatchQueue.main.async {
        self.sdlManager.stop()
    }
  }
    

  func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
      if newLevel != .none && oldLevel == .none {
          // This is our first time in a non-NONE state
          firstHMILevel = newLevel

        getVihicleData()
      }


      switch newLevel {
      case .full: break                // The SDL app is in the foreground
          // Always try to show the initial state to guard against some possible weird states. Duplicates will be ignored by Core.
//          showInitialData()
      case .limited: break        // An active NAV or MEDIA SDL app is in the background
      case .background: break     // The SDL app is not in the foreground
      case .none: break           // The SDL app is not yet running
      default: break
      }
  }


}


// MARK:- Geta Data

extension ProxyManager {

    func unsubscribeToVehicleOdometer() {
        let unsubscribeToVehicleOdometer = SDLUnsubscribeVehicleData()
        unsubscribeToVehicleOdometer.odometer = true as NSNumber & SDLBool
        sdlManager.send(request: unsubscribeToVehicleOdometer) { (request, response, error) in
            guard let response = response, response.resultCode == .success else { return }
//            self.resetOdometer()

            print("Unsub : \(response)")
        }
    }
    
    
    @objc func vehicleDataAvailable(_ notification: SDLRPCNotificationNotification) {
        
        if let response = notification.notification as? SDLOnVehicleData {
            
            if let fuel = response.instantFuelConsumption {
                let info = ["fuel" : fuel.doubleValue,
                            "Trial" : "Second"] as [String : Any]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: info)
                print("onVehicleData : \(response)")
            }
            
            if let odo = response.odometer {
                let info = ["odometer" : odo.doubleValue]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: info)
            }
            
            if let bodyInfo = response.bodyInformation {
                
                let igStatus = bodyInfo.ignitionStatus.rawValue.rawValue
                if igStatus == "START" {
//                    let lockScreenConfiguration = SDLLockScreenConfiguration.enabled()
//                    lockScreenConfiguration.displayMode = .always
//                    sdlManager.
                }
                
                let info = ["engineStatus" : igStatus]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: info)
            }
        }
        
    }
    

    func getVihicleData() {

        let vehicleData = SDLGetVehicleData() // to get data on first time
        vehicleData.odometer = NSNumber(true)
        vehicleData.bodyInformation = NSNumber(true)
        vehicleData.instantFuelConsumption = NSNumber(true)
        vehicleData.vin = NSNumber(true)

        let subscribeToVehicleData = SDLSubscribeVehicleData() // to get data in notification
        subscribeToVehicleData.odometer = true as NSNumber & SDLBool
        subscribeToVehicleData.instantFuelConsumption = true as NSNumber & SDLBool
        subscribeToVehicleData.bodyInformation = true as NSNumber & SDLBool

        let rpcRequest = [vehicleData, subscribeToVehicleData]

        sdlManager.send(rpcRequest, progressHandler: { (request, response, err, value) in
            
            if let response = response as? SDLGetVehicleDataResponse {
                                
                guard let fuel = response.instantFuelConsumption, let odo = response.odometer, let bodyInfo = response.bodyInformation, let vin = response.vin else { return }
                
                let info = ["odometer" : odo.doubleValue,
                            "fuel" : fuel.doubleValue,
                            "engineStatus" : bodyInfo.ignitionStatus.rawValue.rawValue,
                            "vin" : vin] as [String : Any]

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: info)
            }
            
        }, completionHandler: nil)
        
        
        let vehicleInfo = SDLVehicleType()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: ["vehicleInfo" : vehicleInfo])

    }
    
    
    func displayOnManticore() {
        sdlManager.screenManager.textField1 = ""
    }
    
    
}

