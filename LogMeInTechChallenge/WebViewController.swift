//
//  WebViewController.swift

import UIKit
import WebKit
import Foundation

protocol StepByDelegate : AnyObject {
    func updateUI(enable:Bool)
    
}

enum WebViewOperationType : Int {
    case  load
    case  refresh
}

class WebViewController: UIViewController , UIWebViewDelegate  {
    
    
    weak var  delegate : StepByDelegate?
    var jsonString = String()
    var webViewType : WebViewOperationType = .load
    var loginWebView: WKWebView!
    
    
    private func loadWebView() {
        if let receivedData = KeyChain.load(key: "UserCredential")  {
            
            do {
                let cookies = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(receivedData) as? HTTPCookie
                print(cookies!.value)
                let cookieExpiredTime = cookies!.expiresDate
                print(cookies!.expiresDate!)
                let currentDate = Date()
                // Delete user credential from keychain if keychain data age is more than 2 hours
                if hourDifference(from: cookies!.expiresDate!, to: currentDate)   > 2
                {
                    KeyChain.delete(key: "UserCredential")
                }
                else
                {
                    let homeVC = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
                    self.navigationController?.pushViewController(homeVC, animated: true)
                }
            } catch {
                print("Fail to unarchive data to cookies: \(error)")
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        let contentController = WKUserContentController()
        contentController.add(self, name: "loginWebView")
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        self.loginWebView = WKWebView( frame: self.view.bounds, configuration: config)
        self.navigationItem.setHidesBackButton(true, animated: true)
        loadWebView()
        
        self.view.addSubview(self.loginWebView)
    }
    
    /// Returns the amount of hours from another date
    func hourDifference(from date: Date, to toDate: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: toDate).hour ?? 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "LoginForm", withExtension: "html")!
        loginWebView.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        
        loginWebView.navigationDelegate = self
        loginWebView.load(request)
    }
}

extension WebViewController : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        print("didFinish")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
}
//MARK: - Web view method to handle call backs

extension WebViewController : WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        //Call API to authenticate user
        let dict = message.body as? Dictionary<String, String>
        var request = URLRequest(url: URL(string: "http://localhost:5149/userAuthentication")!)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true
        request.addValue("application/json", forHTTPHeaderField: "Content-Type");
        let userId = dict?["userid"];
        let passWord = dict?["password"];
        let json: [String: Any] = ["UserName": userId,
                                   "PassWord": passWord]
        var count = 0;
        let jsonData = try? JSONSerialization.data(withJSONObject: json);
        request.httpBody = jsonData;
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            print("response = \(response)")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                count = json!.count as Int
                if(count > 0)
                {
                    if let parseJSON = json {
                        print("response = \(json)")
                        let userName = parseJSON["userName"] as? String
                        let passWord = parseJSON["passWord"] as? String
                        let userCredential = userName! + "&" + passWord!
                        if let cookie = HTTPCookie(properties: [
                            .domain: "127.0.0.1:5149",
                            .path: "/",
                            .name: "AuthCookie",
                            .value: userCredential,
                            .secure: "TRUE",
                            .expires: NSDate(timeIntervalSinceNow: 7200)
                        ]) {
                            
                            print("Cookie inserted: \(cookie)")
                            let cookiesData = try NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: false)
                            let status = KeyChain.save(key: "UserCredential", data: cookiesData)
                            print("status: ", status)
                            
                            if let receivedData = KeyChain.load(key: "UserCredential")  {
                                
                                do {
                                    //Redirect to Home view controller if login successful
                                    DispatchQueue.main.async {
                                    let homeVC = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
                                    self.navigationController?.pushViewController(homeVC, animated: true)
                                    }
                                } catch {
                                    print("Fail to unarchive data to cookies: \(error)")
                                }
                            }
                        }
                    }
                }
                 else
                {
                    print("Wrong user credential")
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    func endCurrentChat(isEnded: Bool){
        self.navigationController?.popViewController(animated: true)
    }
}
