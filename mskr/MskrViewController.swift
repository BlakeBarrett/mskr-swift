//
//  MskrViewController.swift
//  mskr
//
//  Created by Blake Barrett on 2/13/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class MskrViewController: UIViewController, MaskReceiver {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func onTrashClick(sender: UIBarButtonItem) {
        self.startOver()
    }
    
    @IBAction func onActionClick(sender: UIBarButtonItem) {
        let title = ""
        let message = ""
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
        }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Destroy", style: .Destructive) { (action) in
            self.startOver()
        }
        alertController.addAction(destroyAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
    func startOver() {
        // TODO: Implement
    }
    
    func setSelectedMask(mask: String) {
        // TODO: Implement
    }
    
}

protocol MaskReceiver {
    func setSelectedMask(mask:String)
}

