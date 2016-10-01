//
//  AppDelegate.swift
//  Decibel
//
//  Created by Peter Reinhardt on 8/13/16.
//  Copyright © 2016 Peter Reinhardt. All rights reserved.
//

import UIKit
import AVFoundation

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
    
    var timer: DispatchSourceTimer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if DATADOG_KEY == "YOUR_KEY_HERE" {
            fatalError("You must update your datadog key to use Decibel")
        }
        guard let url = directoryURL() else {
            print("Unable to find a init directoryURL")
            return false
        }
        
        let recordSettings = [
            AVSampleRateKey : NSNumber(value: Float(44100.0) as Float),
            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC) as Int32),
            AVNumberOfChannelsKey : NSNumber(value: 1 as Int32),
            AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue) as Int32),
        ]

        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            let audioRecorder = try AVAudioRecorder(url: url, settings: recordSettings)
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            try audioSession.setActive(true)
            audioRecorder.isMeteringEnabled = true
            recordForever(audioRecorder: audioRecorder)
        } catch let err {
            print("Unable start recording", err)
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
    
    func recordForever(audioRecorder: AVAudioRecorder) {
        let queue = DispatchQueue(label: "io.segment.decibel", attributes: .concurrent)
        timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(1), leeway: .milliseconds(100))
        timer?.setEventHandler { [weak self] in
            audioRecorder.updateMeters()

             // NOTE: seems to be the approx correction to get real decibels
            let correction: Float = 100
            let average = audioRecorder.averagePower(forChannel: 0) + correction
            let peak = audioRecorder.peakPower(forChannel: 0) + correction
            self?.recordDatapoint(average: average, peak: peak)
        }
        timer?.resume()
    }
    
    
    func recordDatapoint(average: Float, peak: Float) {
        // Send a single datapoint to DataDog
        let datadogUrlString = "https://app.datadoghq.com/api/v1/series?api_key=\(DATADOG_KEY)"
        
        let deviceName = UIDevice.current.name
        let timestamp = (NSInteger)(Date().timeIntervalSince1970)
        let body = [
            "series": [
                ["metric": "office.dblevel.average", "host": deviceName, "points": [ [timestamp, average] ] ],
                ["metric": "office.dblevel.peak", "host": deviceName, "points":[ [timestamp, peak] ] ],
            ]
        ]
        
        guard let datadogUrl = URL(string: datadogUrlString),
            let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Bad URL or body")
            return
        }
        print("Will send request to \(datadogUrl)", body)
        
        let request = NSMutableURLRequest(url: datadogUrl)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if let error = error {
                print("error=\(error)")
                return
            }
            if let data = data {
                let responseString = String(data: data, encoding: String.Encoding.utf8)
                print("responseString = \(responseString)")
                return
            }
            print("Neither error nor data was provided")
        }
        task.resume()
    }

}

