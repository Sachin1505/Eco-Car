//
//  UserProfileVC.swift
//  Eco Car
//
//  Created by Sachin Bhandari on 30/06/20.
//  Copyright © 2020 Sachin Bhandari. All rights reserved.
//

import UIKit
import CropViewController

class UserProfileVC: UIViewController {
    
    
    @IBOutlet weak var profilePicIV: UIImageView!
    @IBOutlet weak var imageLoader: UIActivityIndicatorView!

    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    let imagePicker = UIImagePickerController()
    
    let api = ApiSupporter()

    override func viewDidLoad() {
        super.viewDidLoad()

//        contentViewHeight.constant = 1500
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profilePicIV.isUserInteractionEnabled = true
        profilePicIV.addGestureRecognizer(tapGestureRecognizer)

        imagePicker.delegate = self
        
    }
    
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        print("Tap")
        imagePicker.allowsEditing = false

        let alert = UIAlertController(title: "Choose an Image", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            self?.selectOption(source: .camera)
        }))
        
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            self?.selectOption(source: .photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    func selectOption(source: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source) {
            self.imagePicker.sourceType = source

            self.present(self.imagePicker, animated: true, completion: nil)
        } else {
            print("It is not available")
        }
    }
    
    
    @IBAction func editProfile(_ sender: UIBarButtonItem) {
        
        
        
    }
    
    
    @IBAction func updateProfile(_ sender: UIButton) {
        
        guard let image = profilePicIV.image else { return }
        
        imageLoader.startAnimating()
        
        let params = ["tag" : "updateprofile",
              "regId" : "1",
              "firstName" : "Sachin",
              "lastName" : "Bhandari",
              "address" : "dvlkdcsd",
              "zipCode" : "40929",
              "email" : "sachin@gmail.com",
              "city" : "Mumbai",
              "state" : "Maharashtra",
              "esiId" : "123",
              "meterNo" : "456",
              "providernumber" : "789",
//              "renewablecontent" : "ewffbfgv",
              "profilePic" : "1"]
        
        api.uploadImage(parameters: params, fileName: "profile.jpg", image: image) { (response) in

            print("User Info with image Sent: \(response)")
            DispatchQueue.main.async {
                self.imageLoader.stopAnimating()
            }

        }
    }

    
    
    
}


// MARK:- Select and Crop Image

extension UserProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        dismiss(animated: false) { [weak self] in
            let cropViewController = CropViewController(image: pickedImage)
            cropViewController.delegate = self
            self?.present(cropViewController, animated: true, completion: nil)
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
         
        profilePicIV.image = image

        dismiss(animated: true, completion: nil)

    }
    
    
    
}
