//
//  ViewController.swift
//  OHHTTPStubsDemo
//
//  Created by Olivier Halligon on 18/04/2015.
//  Copyright (c) 2015 AliSoftware. All rights reserved.
//

import UIKit
import OHHTTPStubs

class MainViewController: UIViewController {

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Outlets
    
    @IBOutlet var delaySwitch: UISwitch!
    @IBOutlet var textView: UITextView!
    @IBOutlet var installTextStubSwitch: UISwitch!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var installImageStubSwitch: UISwitch!

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Init & Dealloc
    
    override func viewDidLoad() {
        super.viewDidLoad()

        installTextStub(self.installTextStubSwitch)
        installImageStub(self.installImageStubSwitch)
        OHHTTPStubs.onStubActivation { (request: NSURLRequest!, stub: OHHTTPStubsDescriptor!) in
            println("[OHHTTPStubs] Request to \(request.URL!) has been stubbed with \(stub.name)")
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Global stubs activation

    @IBAction func toggleStubs(sender: UISwitch) {
        OHHTTPStubs.setEnabled(sender.on)
        self.delaySwitch.enabled = sender.on
        self.installTextStubSwitch.enabled = sender.on
        self.installImageStubSwitch.enabled = sender.on
        
        let state = sender.on ? "and enabled" : "but disabled"
        println("Installed (\(state)) stubs: \(OHHTTPStubs.allStubs)")
    }
    

    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Text Download and Stub
    
    
    @IBAction func downloadText(sender: UIButton) {
        sender.enabled = false
        self.textView.text = nil
        
        let urlString = "http://www.opensource.apple.com/source/Git/Git-26/src/git-htmldocs/git-commit.txt?txt"
        let req = NSURLRequest(URL: NSURL(string: urlString)!)

        NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()) { (_, data, _) in
            sender.enabled = true
            let receivedText = NSString(data: data, encoding: NSASCIIStringEncoding)
            self.textView.text = receivedText! as String
        }
    }

    weak var textStub: OHHTTPStubsDescriptor?
    @IBAction func installTextStub(sender: UISwitch) {
        if sender.on {
            // Install

            // - we use an inline closure for the test predicate with shorthand argument names
            // - we also use the "trailing closure" syntax of Swift for convenience
            // - we don't care about the 'request' parameter in the trailing closure so we use '_'
            textStub = OHHTTPStubs.stubRequestsPassingTest({$0.URL!.pathExtension == "txt"}) { _ in
                let stubPath = OHPathForFile("stub.txt", self.dynamicType)
                return OHHTTPStubsResponse(
                    fileAtPath: stubPath!,
                    statusCode: 200,
                    headers: ["Content-Type":"text/plain"]
                    )
                    .requestTime(self.delaySwitch.on ? 2.0 : 0.0, responseTime:OHHTTPStubsDownloadSpeedWifi)
            }
            textStub?.name = "Text stub"
        } else {
            // Uninstall
            OHHTTPStubs.removeStub(textStub!)
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Image Download and Stub
    
    @IBAction func downloadImage(sender: UIButton) {
        sender.enabled = false
        self.imageView.image = nil

        let urlString = "http://images.apple.com/support/assets/images/products/iphone/hero_iphone4-5_wide.png"
        let req = NSURLRequest(URL: NSURL(string: urlString)!)

        NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()) { (_, data, _) in
            sender.enabled = true
            self.imageView.image = UIImage(data: data)
        }
    }
    
    weak var imageStub: OHHTTPStubsDescriptor?
    @IBAction func installImageStub(sender: UISwitch) {
        if sender.on {
            // Install
            
            let isImage = { (request: NSURLRequest!) -> Bool in
                contains(["png","jpg","jpeg","gif"], request.URL?.pathExtension ?? "")
            }
            // - we use a separate block 'isImage' for the 'test' predicate for code readability
            // - we use the "trailing closure" syntax of Swift for convenience
            // - we don't care about the 'request' parameter in the trailing closure so we use '_'
            imageStub = OHHTTPStubs.stubRequestsPassingTest(isImage) { _ in
                let stubPath = OHPathForFile("stub.jpg", self.dynamicType)
                return OHHTTPStubsResponse(
                    fileAtPath: stubPath!,
                    statusCode: 200,
                    headers: ["Content-Type":"image/jpeg"]
                    )
                    .requestTime(self.delaySwitch.on ? 2.0 : 0.0, responseTime: OHHTTPStubsDownloadSpeedWifi)
            }
            imageStub?.name = "Image stub"
        } else {
            // Uninstall
            OHHTTPStubs.removeStub(imageStub!)
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Cleaning
    
    @IBAction func clearResults() {
        self.textView.text = ""
        self.imageView.image = nil
    }
    
}
