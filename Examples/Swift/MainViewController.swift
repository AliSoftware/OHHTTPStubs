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
        OHHTTPStubs.onStubActivation { (request: URLRequest, stub: OHHTTPStubsDescriptor, response: OHHTTPStubsResponse) in
            print("[OHHTTPStubs] Request to \(request.url!) has been stubbed with \(stub.name)")
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Global stubs activation

    @IBAction func toggleStubs(_ sender: UISwitch) {
        OHHTTPStubs.setEnabled(sender.isOn)
        self.delaySwitch.isEnabled = sender.isOn
        self.installTextStubSwitch.isEnabled = sender.isOn
        self.installImageStubSwitch.isEnabled = sender.isOn
        
        let state = sender.isOn ? "and enabled" : "but disabled"
        print("Installed (\(state)) stubs: \(OHHTTPStubs.allStubs)")
    }
    

    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Text Download and Stub
    
    
    @IBAction func downloadText(_ sender: UIButton) {
        sender.isEnabled = false
        self.textView.text = nil
        
        let urlString = "http://www.opensource.apple.com/source/Git/Git-26/src/git-htmldocs/git-commit.txt?txt"
        let req = URLRequest(url: URL(string: urlString)!)

        NSURLConnection.sendAsynchronousRequest(req, queue: OperationQueue.main) { (_, data, _) in
            sender.isEnabled = true
            if let receivedData = data, let receivedText = NSString(data: receivedData, encoding: String.Encoding.ascii.rawValue) {
                self.textView.text = receivedText as String
            }
        }
    }

    weak var textStub: OHHTTPStubsDescriptor?
    @IBAction func installTextStub(_ sender: UISwitch) {
        if sender.isOn {
            // Install

            textStub = stub(condition: isExtension("txt")) { _ in
                let stubPath = OHPathForFile("stub.txt", type(of: self))
                return fixture(filePath: stubPath!, headers: ["Content-Type":"text/plain"])
                    .requestTime(self.delaySwitch.isOn ? 2.0 : 0.0, responseTime:OHHTTPStubsDownloadSpeedWifi)
            }
            textStub?.name = "Text stub"
        } else {
            // Uninstall
            OHHTTPStubs.removeStub(textStub!)
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Image Download and Stub
    
    @IBAction func downloadImage(_ sender: UIButton) {
        sender.isEnabled = false
        self.imageView.image = nil

        let urlString = "http://images.apple.com/support/assets/images/products/iphone/hero_iphone4-5_wide.png"
        let req = URLRequest(url: URL(string: urlString)!)

        NSURLConnection.sendAsynchronousRequest(req, queue: OperationQueue.main) { (_, data, _) in
            sender.isEnabled = true
            if let receivedData = data {
                self.imageView.image = UIImage(data: receivedData)
            }
        }
    }
    
    weak var imageStub: OHHTTPStubsDescriptor?
    @IBAction func installImageStub(_ sender: UISwitch) {
        if sender.isOn {
            // Install
            
            imageStub = stub(condition: isExtension("png") || isExtension("jpg") || isExtension("gif")) { _ in
                let stubPath = OHPathForFile("stub.jpg", type(of: self))
                return fixture(filePath: stubPath!, headers: ["Content-Type":"image/jpeg"])
                    .requestTime(self.delaySwitch.isOn ? 2.0 : 0.0, responseTime: OHHTTPStubsDownloadSpeedWifi)
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
