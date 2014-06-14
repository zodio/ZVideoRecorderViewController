//
//  ZSwiftViewController.swift
//  ZVideoRecorderExample
//
//  Created by Jai Govindani on 6/14/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

import UIKit

class ZSwiftViewController : UIViewController, VideoRecorderDelegate {
    
    @IBOutlet var infoLabel : UILabel
    
    @IBAction func takeVideoButtonTapped(sender : AnyObject) {
        
        let videoRecorder = ZVideoRecorderViewController.videoRecorder()
        videoRecorder.maxVideoDuration = 5.0
        videoRecorder.delegate = self
        presentViewController(videoRecorder, animated: true, completion: nil)
    }
    
    func videoRecordedAtPath(path: String!) {
        infoLabel.text = "Video recorded at path: \(path)"
    }
}
