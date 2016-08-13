//
//  AppDelegate.swift
//  Themis
//
//  Created by Peter Reinhardt on 8/13/16.
//  Copyright © 2016 Peter Reinhardt. All rights reserved.
//

import UIKit
import AVFoundation

var Timestamp: NSInteger {
    return (NSInteger)(NSDate().timeIntervalSince1970)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        var audioRecorder:AVAudioRecorder!
        
        let recordSettings = [AVSampleRateKey : NSNumber(float: Float(44100.0)),
                              AVFormatIDKey : NSNumber(int: Int32(kAudioFormatMPEG4AAC)),
                              AVNumberOfChannelsKey : NSNumber(int: 1),
                              AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))]
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(URL: directoryURL()!,
                                                settings: recordSettings)
            audioRecorder.prepareToRecord()
            try audioSession.setActive(true)
            audioRecorder.record()
            audioRecorder.meteringEnabled = true

            NSOperationQueue().addOperationWithBlock({[weak self] in
                let PERIOD = 1.0
                let PERIODS_PER_POINT = 10
                repeat {
                    var sum = 0
                    var peak = -9999999
                    var steps = 0
                    repeat {
                        NSThread.sleepForTimeInterval(PERIOD)
                        audioRecorder.updateMeters()
                        sum += (NSInteger)(audioRecorder.averagePowerForChannel(0))
                        peak = max(peak, (NSInteger)(audioRecorder.peakPowerForChannel(0)))
                        steps += 1
                    } while (steps <= PERIODS_PER_POINT)
                    
                    let average = sum / steps + 120 - 20 // seems to be the approx correction
                    peak += 120 - 20 // seems to be the approx correction
                    let dblevels: [String: NSInteger] = ["average": average, "peak": peak]
                    self?.performSelectorOnMainThread(#selector(AppDelegate.recordDatapoint), withObject: dblevels, waitUntilDone: false)
                } while (true)
                
                })
            
        } catch {
        }
        
        return true
    }
    
    func directoryURL() -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = urls[0] as NSURL
        let soundURL = documentDirectory.URLByAppendingPathComponent("sound.m4a")
        return soundURL
    }
    
    func recordDatapoint(dblevels: [String: NSInteger]) {
        // Send a single datapoint to DataDog
        let datadogUrlString = "https://app.datadoghq.com/api/v1/series?api_key=ba005fa47ed19c17831154ddde78a6b1"
        let datadogUrl = NSURL(string: datadogUrlString);
        
        let request = NSMutableURLRequest(URL:datadogUrl!);
        request.HTTPMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let average = dblevels["average"]! as NSInteger
        let peak = dblevels["peak"]! as NSInteger
        let deviceName = UIDevice.currentDevice().name
        let body = [
            "series": [
                ["metric": "office.dblevel.average", "host": deviceName, "points":[[Timestamp, average]] ],
                ["metric": "office.dblevel.peak", "host": deviceName, "points":[[Timestamp, peak]] ]
            ]
        ]
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(body, options: [])
        print(body)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
        }
        
        task.resume()
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

