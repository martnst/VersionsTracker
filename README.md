# VersionsTracker

[![CI Status](http://img.shields.io/travis/maremmle/VersionsTracker.svg?style=flat)](https://travis-ci.org/Martin Stemmle/VersionsTracker)
[![Version](https://img.shields.io/cocoapods/v/VersionsTracker.svg?style=flat)](http://cocoapods.org/pods/VersionsTracker)
[![License](https://img.shields.io/cocoapods/l/VersionsTracker.svg?style=flat)](http://cocoapods.org/pods/VersionsTracker)
[![Platform](https://img.shields.io/cocoapods/p/VersionsTracker.svg?style=flat)](http://cocoapods.org/pods/VersionsTracker)



**Keeping track of version installation history made easy.**


## Features

- Track not just marketing version, but also build number and install date
- Track both App and OS version
- Access current version
- Check for version updates and first launch
- No use as Singleton required
- Ability to use custom NSUserDefaults (e.g. for [sharing it with extensions](https://developer.apple.com/library/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html) )


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first. Play with the Sample app's version and build numbers.

## Requirements
- Xcode 7.0+
- iOS 8.0+
- [Semantic Versioning](http://semver.org/)

## Installation

VersionsTracker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "VersionsTracker"
```



## Usage

### Initialization

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    if iDontMindSingletons {
        VersionsTracker.initialize(trackAppVersion: true, trackOSVersion: true)
    }
    else {
        // make sure to update the version history once once during you app's life time
        VersionsTracker.updateVersionHistories(trackAppVersion: true, trackOSVersion: true)
    }

    return true
}
```

### Get the current versions with build and install date

```swift
let versionsTracker = iDontMindSingletons ? VersionsTracker.sharedInstance : VersionsTracker()

let curAppVersion : Version = versionsTracker.appVersion.currentVersion
print("Current marketing version is \(curAppVersion.versionString) (Build \(curAppVersion.buildString)) and was first launched \(curAppVersion.installDate)")
```


### Get the version history

```swift
let versionsTracker = iDontMindSingletons ? VersionsTracker.sharedInstance : VersionsTracker()

let appVersions: [Version] = versionsTracker.appVersion.versionHistory
let firstOSVerion : Version = versionsTracker.osVersion.versionHistory.first!
print("The very first time the app was launched on iOS \(firstOSVerion.versionString) on \(firstOSVerion.installDate)")

```


### Check version changes easily

```swift
let versionsTracker = iDontMindSingletons ? VersionsTracker.sharedInstance : VersionsTracker()

switch versionsTracker.appVersion.changeState {
case .Installed:
    // 🎉 Sweet, a new user just installed your app
    // ... start tutorial / intro

case NotChanged:
    // 😴 nothing as changed
    // ... nothing to do

case Update(let previousVersion: Version):
    // 🙃 new build of the same version
    // ... hopefully it fixed those bugs the QA guy reported

case Upgraded(let previousVersion: Version)
    // 😄 marketing version increased
    // ... migrate old app data

case Downgraded(let previousVersion: Version)
    // 😵 marketing version decreased (hopefully we are not on production)
    // ... purge app data and start over

}    
```

Since the build is also kept track off, it enables detecting updates of it as well. However, the build fraction of a version is treated as an arbitrary string. This is to support any build number, from integer counts to git commit hashes. Therefor there is no way to determine the direction of a build change.  

### Compare Version

```swift
let versionsTracker = iDontMindSingletons ? VersionsTracker.sharedInstance : VersionsTracker()
let curAppVersion : Version = versionsTracker.appVersion.currentVersion

curAppVersion >= Version("1.2.3")
curAppVersion >= "1.2.3"
Version("1.2.3") < Version("3.2.1")
curAppVersion != Version("1.2.3", buildString: "B19")
```

Versions with the same marketing version but different build are not equal.  




## Author

Martin Stemmle, marste@msmix.de

## License

VersionsTracker is available under the MIT license. See the LICENSE file for more info.
