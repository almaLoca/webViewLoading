//
//  ViewController.swift
//  carmel
//
//  Created by Netstager on 12/10/18.
//  Copyright © 2018 techvegasllp. All rights reserved.
//
import Foundation
import UIKit
import WebKit
import Alamofire

class Connectivity {
    class func isConnectedToInternet() ->Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var closeBtn: UIButton!
    var webView: WKWebView!
    let link  = "http://sandone.in/"
    
    var d = false
    var activityIndicator: UIActivityIndicatorView?
    override func viewDidLoad() {
        super.viewDidLoad()
        showToast(message: "Welcome to carmel Academy")
        closeBtn.isHidden = true
        self.view.backgroundColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpViews()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func setUpViews()  {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor  = #colorLiteral(red: 0.971870482, green: 0.6425055861, blue: 0.04525602609, alpha: 1)
        
        webView = WKWebView()
        webView.isHidden = true
        activityIndicator = UIActivityIndicatorView(style: .gray)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        activityIndicator?.center = self.view.center
        [webView].forEach({view.addSubview($0)})
        setupConstraints()
        webView.configuration.userContentController.add(self, name: "myInterface")
        webView.load(URLRequest(url: URL(string: link)!))
        
        print("loading" )
        activityIndicator?.startAnimating()
    }
    func setupConstraints(){
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    @IBAction func closeBtn_Click(_ sender: Any) {
        closeBtn.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
        webView.load(URLRequest(url: URL(string: link)!))
    }
    
    
    
    func download(_ sender: Any){
        guard let link = (sender as? URL)?.absoluteString else {return}
        print("\(link)")
        let s = """
        var xhr = new XMLHttpRequest();
        xhr.open('GET', "\(link)", true);
        xhr.responseType = 'arraybuffer';
        xhr.onload = function(e) {
        if (this.status == 200) {
        var uInt8Array = new Uint8Array(this.response);
        var i = uInt8Array.length;
        var binaryString = new Array(i);
        while (i--){
        binaryString[i] = String.fromCharCode(uInt8Array[i]);
        }
        var data = binaryString.join('');
        var base64 = window.btoa(data);
        
        window.webkit.messageHandlers.myInterface.postMessage(base64);
        }
        };
        xhr.send();
        """
        webView?.evaluateJavaScript(s, completionHandler: {(string,error) in
            print(error ?? "no error")
        })
    }
}
extension ViewController: WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            var documentsURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last,
            let convertedData = Data.init(base64Encoded: message.body as! String)
            else {
                //handle error when getting documents URL
                return
        }
        //name your file however you prefer
        documentsURL.appendPathComponent("MyDoc.pdf")
        do {
            try convertedData.write(to: documentsURL)
        } catch {
            //handle write error here
        }
        //if you want to get a quick output of where your
        //file was saved from the simulator on your machine
        //just print the documentsURL and go there in Finder
        print("URL for view \(documentsURL.absoluteString)")
        let activityViewController = UIActivityViewController.init(activityItems: [documentsURL], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}

extension ViewController: WKNavigationDelegate,WKUIDelegate{
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if !(navigationAction.targetFrame != nil && (navigationAction.targetFrame?.isMainFrame)!){
            webView .load(navigationAction.request);
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        setView(view: webView, hidden: false)
        self.activityIndicator = nil
        if d{
            download(webView.url as Any)
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("url \(navigationAction.request.url!.absoluteString)")
        if navigationAction.request.url!.absoluteString.contains("pdf")  || navigationAction.request.url!.absoluteString.contains("xlsx") || navigationAction.request.url!.absoluteString.contains("png") || navigationAction.request.url!.absoluteString.contains("txt") || navigationAction.request.url!.absoluteString.contains("docx"){
            if !d{
                d = true
                //for setting the button
                closeBtn.isHidden = false
                self.navigationController?.isNavigationBarHidden = false
                
               let url = navigationAction.request.url?.absoluteString.components(separatedBy: "?").first ?? ""
                
               // let url = "https://www.carmelacademy.in/carmel/m_parent/student_homework.php"
                decisionHandler(.cancel)
                webView.load(URLRequest(url: URL(string: url)!))
                
                return
            }
            
        }
        decisionHandler(.allow)
    }
}
extension ViewController {
    func setView(view: UIView, hidden: Bool) {
        UIView.transition(with: view, duration: 0.5, options: .transitionCrossDissolve, animations: {
            view.isHidden = hidden
        })
    }
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 120, y: self.view.frame.size.height-100, width: 250, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 10.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 6.0, delay: 0.6, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    } }


/*
var webView: WKWebView!



class ViewController:  UIViewController,WKNavigationDelegate,WKUIDelegate,UIWebViewDelegate{
    
//    var mywebView = WKWebView()
    @IBOutlet weak var mywebView: WKWebView!
    var counter = 0
    var timer = Timer()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor  = #colorLiteral(red: 0.971870482, green: 0.6425055861, blue: 0.04525602609, alpha: 1)
        
        //        UIApplication.shared.statusBarView?.backgroundColor = UIColor.green
        //UIApplication.shared.statusBarView?.backgroundColor = UIColor.red
        
        let url = URL(string: "https://www.carmelacademy.in/carmel/m_parent/")!
        mywebView?.load(URLRequest(url: url))
        
        // 2
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: mywebView, action: #selector(mywebView.reload))
        toolbarItems = [refresh]
        navigationController?.isToolbarHidden = false
        
        timer.invalidate() // just in case this button is tapped multiple times
        // start the timer
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    @objc func timerAction() {
        
        if Connectivity.isConnectedToInternet() {
            print("Yes! internet is available.")
            // do some tasks..
        }
        else
        {
            print("Ohh! internet not available.")
            //            let mainStoryboard:UIStoryboard = UIStoryboard(name:"Main",bundle:nil)
            //            let desController = mainStoryboard.instantiateViewController(withIdentifier: "notReachableViewController") as! notReachableViewController
            //            self.navigationController?.pushViewController(desController, animated: true)
            timer.invalidate()
            performSegue(withIdentifier: "goto", sender: nil)
            
        }
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
        
    }
    
    override func loadView() {
        mywebView?.navigationDelegate = self
        view = mywebView
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let request = navigationAction.request.urlRequest
        print(request as Any)
        if requestIsDownloadable(request: request!)
        {
            initializeDownload(download: request!)
        }
    }
    
    private func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool
    {
        print(request)
        if requestIsDownloadable(request: request)
        {
            initializeDownload(download: request)
            return false
        }
        return true
    }
    
    
    func requestIsDownloadable( request: URLRequest) -> Bool
    {
        let requestString : NSString = (request.url?.absoluteString)! as NSString
        let fileType : String = requestString.pathExtension
        print(fileType)
        let isDownloadable : Bool = (
            (fileType.caseInsensitiveCompare("zip") == ComparisonResult.orderedSame) ||
                (fileType.caseInsensitiveCompare("rar") == ComparisonResult.orderedSame) ||
                (fileType.caseInsensitiveCompare("pdf") == ComparisonResult.orderedSame)
        )
        
        
        return isDownloadable
    }
    
    
    func initializeDownload( download: URLRequest)
    {
        let downloadAlertController : UIAlertController = UIAlertController(title: "Download Detected!", message: "Would you like to download this file?", preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction : UIAlertAction = UIAlertAction(title: "Nope", style: UIAlertAction.Style.cancel, handler:
        {(alert: UIAlertAction!) in
            print("Download Cancelled.")
        })
        
        let okAction : UIAlertAction = UIAlertAction(title: "Yes!", style: UIAlertAction.Style.default, handler:
        {(alert: UIAlertAction!) in
            let downloadingAlertController : UIAlertController = UIAlertController(title: "Downloading...", message: "Please wait while your file downloads.\nThis alert will disappear when it's done.", preferredStyle: UIAlertController.Style.alert)
            self.present(downloadingAlertController, animated: true, completion: nil)
            
            do
            {
                let urlToDownload : NSString = (download.url?.absoluteString)! as NSString
                let url : NSURL = NSURL(string: urlToDownload as String)!
                let urlData : NSData = try NSData.init(contentsOf: url as URL)
                
                if urlData.length > 0
                {
                    let paths : Array = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    let documentsDirectory : String = paths[0]
                    let filePath : String = String.localizedStringWithFormat("%@/%@", documentsDirectory, urlToDownload.lastPathComponent)
                    
                    urlData.write(toFile: filePath, atomically: true)
                    downloadingAlertController.dismiss(animated: true, completion: nil)
                }
            }
            catch let error as NSError
            {
                print(error.localizedDescription)
            }
        })
        
        downloadAlertController.addAction(cancelAction)
        downloadAlertController.addAction(okAction)
        self.present(downloadAlertController, animated: true, completion: nil)
    }
    
    //    UIApplication.shared.statusBarView?.backgroundColor = .red
}

// newly edited by ameer *Your Chunk :)*

//When you user extenstion, we have to put outer side of the class
extension UIApplication {
    var statusBarView: UIView? {
        if responds(to: Selector(("statusBar"))) {
            return value(forKey: "statusBar") as? UIView
        }
        return nil
    }
}
*/
