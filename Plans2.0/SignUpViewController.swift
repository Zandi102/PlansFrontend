//
//  SignUpViewController.swift
//  Plans2.0
//
//  Created by Alex Pallozzi on 3/24/22.
//
import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        return label
    }();
    
    public override func viewDidLoad() {
        usernameField.autocorrectionType = .no
        passwordField.autocorrectionType = .no
        phone.autocorrectionType = .no
        passwordField.isSecureTextEntry = true
        phone.delegate = self
        super.viewDidLoad()
        label.frame = CGRect.init(x: view.frame.size.width - 1000, y: view.frame.size.height - 200, width: 500, height: 100)
        registerButton?.addTarget(self, action: #selector(register), for: .touchUpInside)
        usernameField.delegate = self
        passwordField.delegate = self
        registerButton.layer.cornerRadius = registerButton.bounds.size.height / 2.0
        loginButton.layer.cornerRadius = loginButton.bounds.size.height / 2.0
    }
    
    //MARK - UITextField Delegates
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //For mobile numer validation
        if textField == phone {
            let allowedCharacters = CharacterSet(charactersIn:"0123456789 ")//Here change this characters based on your requirement
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func unwindToSignup(_ sender: UIStoryboardSegue) {}
    
    @objc func register () {
        let passLength = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let userLength = usernameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if(passLength.count < 8 || userLength.count < 2) {
            view.addSubview(label)
            label.frame = CGRect.init(x: 0, y: view.frame.size.height - 200, width: self.view.bounds.width, height: 100)
            label.textAlignment = .center
            label.text = "Invalid user credentials."
            usernameField.text = ""
            passwordField.text = ""
        }
        else {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.setValue(userLength, forKey: "username")
            UserDefaults.standard.setValue(passLength, forKey: "password")
            let db = DBManager();
            let url = URL(string: "http://abdasalaam.com/Functions/register3.php")!
            let parameters: [String: Any] = [
                "username": userLength,
                "password": User.hashPassword(toHash: passLength),
                "phone": phone.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
            let message = db.postRequest(url, parameters)
            switch(message) {
            case "User created successfully":
                label.frame = CGRect.init(x: 0, y: view.frame.size.height - 200, width: self.view.bounds.width, height: 100)
                //THIS PUBLIC USERNAME VAR WILL ONLY BE INSTANTIATED IF THERE IS SUCCESSFUL LOGIN
                //publicUsername will be used in other view controllers to find the info related to the user logged in
                User.currentUser = User.createCurrentUser(userLength)
                switchScreen()
            case "User already exist":
                print(message)
                view.addSubview(label)
                label.frame = CGRect.init(x: 0, y: view.frame.size.height - 200, width: self.view.bounds.width, height: 100)
                label.textAlignment = .center
                label.text = "Username already taken."
            default:
                view.addSubview(label);
                label.frame = CGRect.init(x: 0, y: view.frame.size.height - 200, width: self.view.bounds.width, height: 100)
                label.textAlignment = .center
                label.text = "Error. Please try again."
            }
        }
    }
    
    @objc func switchScreen() {
        let homeViewController = storyboard?.instantiateViewController(identifier: "MapNav") as? UINavigationController
        homeViewController?.hidesBottomBarWhenPushed = false
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
}
