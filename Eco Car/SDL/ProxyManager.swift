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
    
    let api = ApiSupporter()

//TODO:- Change appID, port and ipAddress here.
    private let appName = "Eco Car"
    private let appId = "1505"
    private let appIpAddress = "m.sdl.tools"
    private let appPort: UInt16 = 19906
    

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
        lockScreenConfiguration.displayMode = .never


        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: lockScreenConfiguration, logging: .default(), fileManager: .default(), encryption: nil)

        sdlManager = SDLManager(configuration: configuration, delegate: self)
        sdlManager.delegate = self

        // Gets Updates from the Car Device
        self.sdlManager.subscribe(to: .SDLDidReceiveVehicleData, observer: self, selector: #selector(self.vehicleDataAvailable(_:)))
        
        sdlManager.screenManager.textField1 = "Welcome"
        
        
//        let navigationSupported = sdlManager.systemCapabilityManager.navigationCapability

    }

    func connect() {
        // Start watching for a connection with a SDL Core
        sdlManager.start { (success, error) in
            if success {

                print("SDL Connected Successfully")
                
                let logTitle = "sdlManager.start line 82 ProxyManager"
                let logDesc = "SDL Connected Successfully"

                let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
                self.api.apiCalls(url: logUrl, parameters: params) { (response) in
                    print("newLevel != .none && oldLevel == .none")
                    print("resp: \(response)")
                }


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
        
        let logTitle = "ios hmiLevel if"
        let logDesc = "Calling getVihicleData line 114 ProxyManager"

        let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
        api.apiCalls(url: logUrl, parameters: params) { (response) in
            print("newLevel != .none && oldLevel == .none")
            print("resp: \(response)")
        }
      } else {
        
        getVihicleData()

        let logTitle = "ios hmiLevel else"
        let logDesc = "Calling getVihicleData line 126 ProxyManager"

        let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
        api.apiCalls(url: logUrl, parameters: params) { (response) in
            print("Else statemnet")
            print("resp: \(response)")
        }
    }


      switch newLevel {
      case .full:                 // The SDL app is in the foreground
          // Always try to show the initial state to guard against some possible weird states. Duplicates will be ignored by Core.
        print("didChangeToLevel : Full")
        getVihicleData()
        
        let logTitle = "ios hmiLevel = Full"
        let logDesc = "calling getVihicleData from line 143 ProxyManager"

        let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
        api.apiCalls(url: logUrl, parameters: params) { (response) in
            print("Fluu Level")
            print("resp: \(response)")
        }

        break
        
      case .limited:        // An active NAV or MEDIA SDL app is in the background
        print("didChangeToLevel : Limited")
        getVihicleData()
        
        let logTitle = "ios hmiLevel = limited"
        let logDesc = "calling getVihicleData from line 158 ProxyManager"

        let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
        api.apiCalls(url: logUrl, parameters: params) { (response) in
            print("Limited Level")
            print("resp: \(response)")
        }

        break
        
      case .background:     // The SDL app is not in the foreground
        print("didChangeToLevel : background")
        getVihicleData()
        
        let logTitle = "ios hmiLevel = background"
        let logDesc = "calling getVihicleData from line 173 ProxyManager"

        let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
        api.apiCalls(url: logUrl, parameters: params) { (response) in
            print("Background Level")
            print("resp: \(response)")
        }

        break
        
      case .none:           // The SDL app is not yet running
        print("didChangeToLevel : None")
        getVihicleData()
        
        let logTitle = "ios hmiLevel = None"
        let logDesc = "calling getVihicleData from line 188 ProxyManager"

        let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
        api.apiCalls(url: logUrl, parameters: params) { (response) in
            print("None Level")
            print("resp: \(response)")
        }

        break
        
      default:
        getVihicleData()
        
        let logTitle = "ios hmiLevel = default"
        let logDesc = "calling getVihicleData from line 202 ProxyManager"

        let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
        api.apiCalls(url: logUrl, parameters: params) { (response) in
            print("If Statement")
            print("resp: \(response)")
        }
        break
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
//                if igStatus == "START" {
////                    let lockScreenConfiguration = SDLLockScreenConfiguration.enabled()
////                    lockScreenConfiguration.displayMode = .always
////                    sdlManager.
//                }
                
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
                
                let logTitle = "First time getting data"
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-mm-dd hh:mm:ss.s"
                let dateStr = formatter.string(from: date)
                let logDesc = "odometer = \(odo.stringValue) & fuel = \(fuel.stringValue) & engine status = \(bodyInfo.ignitionStatus.rawValue.rawValue) & vin = \(vin) & date = \(dateStr)"

                let params = "tag=testlog&logtitle=\(logTitle)&logdesc=\(logDesc)"
                self.api.apiCalls(url: logUrl, parameters: params) { (response) in
                    print("If Statement")
                    print("resp: \(response)")
                }


                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: info)
                
            }
            
        }, completionHandler: nil)
        
        
        let vehicleInfo = SDLVehicleType()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: ["vehicleInfo" : vehicleInfo])

    }
    
//    func getOEMCustonData() {
//        let getCustomData = SDLGetVehicleData()
////        getCustomData.setOEMCustom("OEM-X-Vehicle-Data", withVehicleDataState: true)
//        getCustomData.setOEMCustomVehicleData(name: "Vehicle-Data", state: true)
//        sdlManager.send(request: getCustomData) { (request, response, error) in
////            guard let response = response as? SDLGetVehicleDataResponse else { return }
//
//            if let response = response as? SDLGetVehicleDataResponse {
//
//                print("Resp: \(response)")
//
//                guard let fuel = response.instantFuelConsumption, let odo = response.odometer, let bodyInfo = response.bodyInformation, let vin = response.vin else { return }
//
//                let info = ["odometer" : odo.doubleValue,
//                            "fuel" : fuel.doubleValue,
//                            "engineStatus" : bodyInfo.ignitionStatus.rawValue.rawValue,
//                            "vin" : vin] as [String : Any]
//
////                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "uiInfoUpdate"), object: nil, userInfo: info)
//            }
//
//
////            guard let customVehicleData = response.getOEMCustomVehicleData("OEM-X-Vehicle-Data") as? SDLGetVehicleDataResponse else { return }
////            print("customVehicleData: \(customVehicleData)")
//        }
//    }
    
    
    func displayOnManticore() {
        sdlManager.screenManager.textField1 = ""
    }
    
    
}

