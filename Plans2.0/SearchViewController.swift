//
//  SearchViewController.swift
//  Plans2.0
//
//  Created by Alex Pallozzi on 4/11/22.

import UIKit
import Contacts

class SearchViewController: UIViewController {
    
    private struct FriendStruct: Decodable {
        enum Category: String, Decodable{
            case swift, combine, debugging, xcode
        }
        let username: String
        let name: String
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchField: UITableView!
    
    var invitations = ["John Smith, click to accept", "Demarcus Cousins, click to accept"]
    var filteredUsers = [User]()
    var usersInvited = User.allUsers
    var searchBarIsFull = false
    var doubleClick : String = ""
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.text = "Cannot Invite User Twice"
        return label
    }();
    let store = CNContactStore()
    var contactNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchField.delegate = self
        searchField.dataSource = self
        searchBar.delegate = self
        searchBar.delegate = self
        searchBar.searchTextField.textColor = .white
        
        let authorize = CNContactStore.authorizationStatus(for: .contacts)
        if authorize == .notDetermined {
            store.requestAccess(for: .contacts) { (chk, error) in
                if error == nil {
                    self.contactNames = self.getContactNames()
                }
            }
        } else if authorize == .authorized {
            self.contactNames = self.getContactNames()
            if(User.quickAddUsers.isEmpty) {
                //User.quickAddUsers = getUsersByPhone()
            }
        }
    }
    
    func trimNumber(num: String) -> String {
        let newNumb = num.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        return newNumb
    }
    
    func getContactNames() -> [String] {
        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier())
        let contact = try! store.unifiedContacts(matching: predicate, keysToFetch: [CNContactBirthdayKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactGivenNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactDatesKey as CNKeyDescriptor])
        let date = DateFormatter()
        date.dateFormat = "MM/dd/yyyy"
        var contactNames = [String]()
        for con in contact {
            contactNames.append(con.givenName + con.familyName)
        }
        
        return contactNames
    }
    
    func getPhoneNumbers() -> [String] {
        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier())
        let contact = try! store.unifiedContacts(matching: predicate, keysToFetch: [CNContactBirthdayKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactGivenNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactDatesKey as CNKeyDescriptor])
        let date = DateFormatter()
        date.dateFormat = "MM/dd/yyyy"
        var phoneNumbers = [String]()
        for con in contact {
            phoneNumbers.append(trimNumber(num: (con.phoneNumbers.first?.value.stringValue)!))
        }
        
        return phoneNumbers
    }
    
    func getUsersByPhone() -> [User] {
        let numbersFromContacts = getPhoneNumbers()
        
        var userArray = [User]()
        
        for num in numbersFromContacts {
            let db = DBManager()
            if URL(string: "http://abdasalaam.com/Functions/loadUserByPhone.php?phone=\(num)") == nil {
                continue
            }
            let url = URL(string: "http://abdasalaam.com/Functions/loadUserByPhone.php?phone=\(num)")!
            
            let messages = db.getRequest(url)
            let user = User()
            if messages.count > 0 {
                let userFields = messages[0]
                let jsonData = userFields.data(using: .utf8)!
                let resp: FriendStruct = try! JSONDecoder().decode(FriendStruct.self, from: jsonData)
                user.fullName = resp.name
                user.userName = resp.username
                userArray.append(user)
            }
        }
        return userArray
    }
    
    func determineQuickAdd() -> [String]{
        return [String]()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchBar.resignFirstResponder()
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func filterContentForSearchText(searchText: String) {
        filteredUsers = usersInvited.filter({(user: User) -> Bool in
            return user.fullName.lowercased().contains(searchText.lowercased()) || user.userName.lowercased().contains(searchText.lowercased())
        });
        searchField.reloadData()
    }
    
    func isSearchBarEmpty() -> Bool {
        if(searchBar.text! != "") {
            return false
        }
        else {
            return true
        }
    }
    
    func isFiltering() -> Bool {
        if(!isSearchBarEmpty()) {
            label.removeFromSuperview()
        }
        return !isSearchBarEmpty()
    }
    
    func numberOfInvites(username1: String, username2 : String) -> Int {
        let db = DBManager()
        let url = (URL(string: "http://abdasalaam.com/Functions/loadInvitationsBetweenFriends.php?username1=\(username1)&username2=\(username2)"))!
        let messages = db.getRequest(url)
        //message will contain the username and the name of friends that have isAdded = 1 for the corresponing user
        return messages.count
    }
}

extension SearchViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}

extension SearchViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredUsers.count
        }
        else {
            return User.quickAddUsers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath);
        if isFiltering() {
            var cellConfig = cell.defaultContentConfiguration()
            if (filteredUsers[indexPath.row].fullName.count < 3) {
                cellConfig.text = filteredUsers[indexPath.row].userName
            }
            else {
                cellConfig.text = filteredUsers[indexPath.row].fullName + ", " + filteredUsers[indexPath.row].userName
            }
            cellConfig.textProperties.color = .white
            cellConfig.secondaryText = "Swipe to send invitation"
            cellConfig.secondaryTextProperties.color = .white
            cell.contentConfiguration = cellConfig
            return cell
        }
        else {
            var cellConfig = cell.defaultContentConfiguration()
            if (User.quickAddUsers[indexPath.row].fullName.count < 3) {
                cellConfig.text = "From Contacts: " + User.quickAddUsers[indexPath.row].userName
            }
            else {
                cellConfig.text = "From Contacts: " + User.quickAddUsers[indexPath.row].fullName + ", " + User.quickAddUsers[indexPath.row].userName
            }
            cellConfig.textProperties.color = .white
            cellConfig.secondaryText = "Swipe to send invitation"
            cellConfig.secondaryTextProperties.color = .white
            cell.contentConfiguration = cellConfig
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var parameters: [String: Any] = [:]
        if isFiltering() {
            let share = UITableViewRowAction(style: .normal, title: "Invite") { action, index in
                let db = DBManager()
                let url = URL(string: "http://abdasalaam.com/Functions/addFriend.php")!
                parameters = [
                    "username1": User.currentUser.userName,
                    "username2": self.usersInvited[indexPath.row].userName
                ]
                
                _ = db.postRequest(url, parameters)
            }
            share.backgroundColor = UIColor.green
            if (self.numberOfInvites(username1:User.currentUser.userName,username2: self.filteredUsers[indexPath.row].userName) == 0) {
                return [share]
            }
            else {
                return nil
            }
        }
        else {
            let share = UITableViewRowAction(style: .normal, title: "Invite") { action, index in
                let db = DBManager()
                let url = URL(string: "http://abdasalaam.com/Functions/addFriend.php")!
                print(self.usersInvited[indexPath.row])
                parameters = [
                    "username1": User.currentUser.userName,
                    "username2": User.quickAddUsers[indexPath.row].userName
                ]
                _ = db.postRequest(url, parameters)
            }
            share.backgroundColor = UIColor.green
            if (self.numberOfInvites(username1:User.currentUser.userName,username2: User.quickAddUsers[indexPath.row].userName) == 0) {
                return [share]
            }
            else {
                return nil
            }
        }
        
    }
}

extension SearchViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        filterContentForSearchText(searchText: searchBar.text!)
        
    }
}

extension SearchViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchBar.text!)
        searchField.reloadData()
    }
}
