# Decibel

Decibel is small iOS app for recording office noise dB levels to Datadog. Read more about it's conception and research uses [here](https://segment.com/blog/how-we-added-10-people-without-hiring-a-soul/).

### Goal
- Noise is distracting many people in the office
- We want to understand the acoustics of the office
- We want to understand the sources of noise

### August 31, 2016

![](https://cloudup.com/cmtcIxPLwUE+)

* 12am-1am: our security guard playing loud music on dance floor (on request to collect data!)
* 7:30am: people start showing up at the office
* 12pm-12:30pm: lunchtime
* 1:30pm-1:50pm: rebranding launch celebration
* 2:30pm: team offsite, ~20 people headed out

### App

<img src="https://cldup.com/vXQwJJoM42.png" width="200">

### January 16, 2022

* You can create a free Datadog account (free trial) and you don't need to install any user agent.
* Just find your API key from your account like 6e**********c6 and put it into line 15 of the AppDelegate.
* You will likely have to change the bundle Id of the app to avoid conflicts in order to build it on a simulator/device
* If it's a new datadog account, it might take ~15 minutes for your data to register. You can go to the (DataDog dashboard)[https://app.datadoghq.com/] and you'll see the it saying that you have a host reporting data to Datadog
* If you go to the Metrics Explorer, you'll see "office.dblevel.peak" under Graph, select that and Voila! That's the same value being sent from your device as you can see in the Application Output of Xcode.


Additionally, you can check out the (metrics API documentation for Data dog)[https://docs.datadoghq.com/api/latest/metrics/]