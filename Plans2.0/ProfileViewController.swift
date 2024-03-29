//
//  ViewController.swift
//  Plans2.0
//
//  Created by Alex Pallozzi on 2/23/22.
//

import UIKit

class ProfileViewController: UIViewController, UITextFieldDelegate{
    
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var userPasswordField: UITextField!
    @IBOutlet weak var userEmailField: UITextField!
    @IBOutlet weak var userDescriptionField: UITextView!
    
    @IBOutlet weak var saveChangesButton: UIButton? = {
        let saveChangesButton = UIButton()
        saveChangesButton.backgroundColor = .white
        return saveChangesButton
    }()
    private let button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .red
        return button;
    }()
    
    override func viewDidLoad() {
        userEmailField.autocorrectionType = .no
        super.viewDidLoad();
        saveChangesButton?.addTarget(self, action: #selector(buttonTap), for: .touchUpInside)
        profileButton?.addTarget(self, action: #selector(changeProfile), for: .touchUpInside)
        self.username.text = User.currentUser.userName
        self.username.adjustsFontSizeToFitWidth = true
        userEmailField.text = User.currentUser.fullName
        userDescriptionField.text = User.currentUser.description
        userEmailField.delegate = self
        if User.currentUser.image.count > 0 {
            var stringImg = User.currentUser.image
            let remainder = stringImg.count % 4
            if remainder > 0 {
                stringImg = stringImg.padding(toLength: stringImg.count + 4 - remainder,
                                              withPad: "=",
                                              startingAt: 0)
            }
            let imageData = Data(base64Encoded: stringImg)
            profilePicture.image = UIImage(data: imageData!)!
        }
        else {
            profilePicture.image = UIImage(named: "ProfilePicture")
        }
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        profilePicture.clipsToBounds = true
        saveChangesButton!.layer.cornerRadius = saveChangesButton!.bounds.size.height / 2.0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userPasswordField.resignFirstResponder()
        userEmailField.resignFirstResponder()
        userDescriptionField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func changeProfile() {
        presentPhotoActionSheet()
    }
    
    @objc func buttonTap() {
        let strBase64 = profilePicture.image!.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
        User.currentUser.fullName = self.userEmailField.text!
        User.currentUser.description = self.userDescriptionField.text!
        User.currentUser.userName = self.userEmailField.text!;
        User.currentUser.description = userDescriptionField.text!;
        User.currentUser.updateImage(strBase64);
        let url = URL(string: "http://abdasalaam.com/Functions/modifyUser.php")!
        let parameters: [String: Any] = [
            "username":User.currentUser.userName,
            "password":User.currentUser.password,
            "age":"0",
            "phone":"0",
            "name":userEmailField.text!,
            "description": User.currentUser.description,
            "image":strBase64
        ]
        Task {
            let save = saveConcurrently()
            _ = await save.postReq(url, parameters)
        }
    }
    @IBAction func unwindToProfile(_ sender: UIStoryboardSegue) {}
    
    actor saveConcurrently {
        init() {
        }
        
        func postReq(_ url : URL, _ parameters: [String: Any]) {
            let db = DBManager();
            _ = db.postRequest(url, parameters)
            
        }
    }

}

extension ProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select your picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self] _ in
            self?.presentCameraRoll()
        }))
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentCameraRoll() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.profilePicture.image = image
        self.profilePicture.layer.masksToBounds = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

