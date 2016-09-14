// VersionsTracker.swift
//
// Copyright (c) 2016 Martin Stemmle
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation

open class VersionsTracker {
    
    internal static let appVersionScope = "appVersion";
    internal static let osVersionScope = "osVersion";
    
    
    /**
     Shared instance, for those who prefer using `VersionsTracker` as a singleton.
     */
    open static var sharedInstance : VersionsTracker {
        get {
            if _sharedInstance == nil {
                fatalError("❗️VersionsTracker.initialize() musted be called befor accessing the singleton")
            }
            return _sharedInstance!
        }
    }
    
    private static var _sharedInstance : VersionsTracker?
    
    
    public lazy var appVersion : VersionTracker = VersionTracker(currentVersion: Version.currentAppVersion,
        inScope: VersionsTracker.appVersionScope,
        userDefaults: self.userDefaults)
    
    
    public lazy var osVersion : VersionTracker = VersionTracker(currentVersion: Version.currentOSVersion,
        inScope: VersionsTracker.osVersionScope,
        userDefaults: self.userDefaults)
    
    /**
     The user defaults to store the version history in.
     */
    private let userDefaults: UserDefaults
    
    
    
    /**
     **When using `VersionTracker` as a singleton, this should be called on each app launch.**
     
     Initializes the singleton causing it to load and update the version history.
     
     - parameter userDefaults: Pass in a NSUserDefaults object for storing and retrieving the version history. Defaults to `NSUserDefaults.standardUserDefaults()`.
     
     */
    public static func initialize(trackAppVersion: Bool, trackOSVersion: Bool, withUserDefaults userDefaults: UserDefaults? = nil) {
        if _sharedInstance != nil {
            fatalError("❗️VersionsTracker.initialize() was already called before and must be called only once.")
        }
        _sharedInstance = VersionsTracker(trackAppVersion: trackAppVersion,
            trackOSVersion: trackOSVersion,
            withUserDefaults: userDefaults)
    }
    
    /**
     **When NOT using `VersionTracker` this should be called on each app launch.**
     
     Updates the version history once per app session.
     
     *It should but does not has to be called befor instantiating any instance. Any new instance will make sure the version history got updated internally.*
     *However, calling* `updateVersionHistory()` *after the app is launched is recommended to not lose version updates if no instance gets ever initialized.*
     
     - parameter userDefaults: Pass in a NSUserDefaults object for storing and retrieving the version history. Defaults to `NSUserDefaults.standardUserDefaults()`.
     */
    public static func updateVersionHistories(trackAppVersion: Bool, trackOSVersion: Bool, withUserDefaults userDefaults: UserDefaults? = nil) {
        let defaults = userDefaults ?? UserDefaults.standard
        if trackAppVersion {
            let versionInfo = VersionTracker.updateVersionHistoryOnce(
                withVersion: Version.currentAppVersion,
                inScope: VersionsTracker.appVersionScope,
                onUserDefaults: defaults)
            if versionInfo == nil {
                print("[VersionsTracker] ⚠️ App version history was already updated")
            }
        }
        if trackOSVersion {
            let versionInfo = VersionTracker.updateVersionHistoryOnce(
                withVersion: Version.currentOSVersion,
                inScope: VersionsTracker.osVersionScope,
                onUserDefaults: defaults)
            if versionInfo == nil {
                print("[VersionsTracker] ⚠️ OS Version history was already updated")
            }
        }
    }
    
    public init(trackAppVersion: Bool = false, trackOSVersion: Bool = false, withUserDefaults userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? UserDefaults.standard
        
        if (trackAppVersion) {
            // triggre version histroy update
            self.appVersion.currentVersion
        }
        
        if (trackOSVersion) {
            // triggre version histroy update
            self.osVersion.currentVersion
        }
    }
    
}
