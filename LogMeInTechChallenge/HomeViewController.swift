//
//  HomeViewController.swift
//  WebKitDemo
//
//  Created by Samar Dutta on 2/14/22.
//  Copyright © 2022 Mushtaque Ahmed. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var lblUser: UILabel!
    @IBAction func LogoutUser(_ sender: Any) {
        //Delete frok keychain on logout
        KeyChain.delete(key: "UserCredential")
           let loginWebView = self.storyboard?.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
           self.navigationController?.pushViewController(loginWebView, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let receivedData = KeyChain.load(key: "UserCredential")  {
            
            do {
                //Set user name from cookie stored in Keychain
                let cookies = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(receivedData) as? HTTPCookie
                print(cookies!.value)
                let userCredentials = cookies!.value.components(separatedBy: "&")
                self.lblUser.text = userCredentials[0]
                    } catch {
                        print("Fail to unarchive data to cookies: \(error)")
                    }
                }
       
        self.navigationItem.setHidesBackButton(true, animated: true)
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
