//
//  AppDelegate.swift
//  Decibel
//
//  Created by Peter Reinhardt on 8/13/16.
//  Copyright © 2016 Peter Reinhardt. All rights reserved.
//

import UIKit
import AVFoundation

var Timestamp: NSInteger {
    return (NSInteger)(Date().timeIntervalSince1970)
}

/*
 NOTE: PLEASE PUT YOUR DATADOG KEY BELOW
 */
let DATADOG_KEY = "YOUR_KEY_HERE"
/*
 NOTE: PLEASE PUT YOUR DATADOG KEY ABOVE
 */


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        var audioRecorder:AVAudioRecorder!
        
        let recordSettings = [AVSampleRateKey : NSNumber(value: Float(44100.0) as Float),
                              AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC) as Int32),
                              AVNumberOfChannelsKey : NSNumber(value: 1 as Int32),
                              AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue) as Int32)]
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(url: directoryURL()!,
                                                settings: recordSettings)
            audioRecorder.prepareToRecord()
            try audioSession.setActive(true)
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true

            OperationQueue().addOperation({[weak self] in
                let PERIOD = 1.0
                let PERIODS_PER_POINT = 10
                repeat {
                    var sum = 0
                    var peak = -9999999
                    var steps = 0
                    repeat {
                        Thread.sleep(forTimeInterval: PERIOD)
                        audioRecorder.updateMeters()
                        sum += (NSInteger)(audioRecorder.averagePower(forChannel: 0))
                        peak = max(peak, (NSInteger)(audioRecorder.peakPower(forChannel: 0)))
                        steps += 1
                    } while (steps <= PERIODS_PER_POINT)
                    
                    let average = sum / steps + 120 - 20 // seems to be the approx correction
                    peak += 120 - 20 // seems to be the approx correction
                    let dblevels: [String: NSInteger] = ["average": average, "peak": peak]
                    self?.performSelector(onMainThread: #selector(AppDelegate.recordDatapoint), with: dblevels, waitUntilDone: false)
                } while (true)
                
                })
            
        } catch {
        }
        
        return true
    }
    
    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent("sound.m4a")
        return soundURL
    }
    
    func recordDatapoint(_ dblevels: [String: NSInteger]) {
        
        // Send a single datapoint to DataDog
        let datadogUrlString = "https://app.datadoghq.com/api/v1/series?api_key=\(DATADOG_KEY)"
        let datadogUrl = URL(string: datadogUrlString);
        
        let request = NSMutableURLRequest(url:datadogUrl!);
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let average = dblevels["average"]! as NSInteger
        let peak = dblevels["peak"]! as NSInteger
        let deviceName = UIDevice.current.name
        let body = [
            "series": [
                ["metric": "office.dblevel.average", "host": deviceName, "points":[[Timestamp, average]] ],
                ["metric": "office.dblevel.peak", "host": deviceName, "points":[[Timestamp, peak]] ]
            ]
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
        print(body)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            let responseString = String(data: data!, encoding: String.Encoding.utf8)
            print("responseString = \(responseString)")
        }) 
        
        task.resume()
    }

}

