// VersionTracker.swift
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

open class VersionTracker {
    
    /**
     Sorted array of all versions which the user has had installed. New versions are appended at the end of the array. The last element is the current version.
     
     *Unless using the Singleton, the version history is lazy loaded from NSUserDefaults. If you only need to access the `currentVersion`
     or the `previousVersion` use the corresponding properties to save loading the entire history.*
     */
    private(set) public lazy var versionHistory: [Version] = self.userDefaults.versionsInScope(self.userDefaultsScope)
    
    /**
     The previous version or `nil` if the user did not updated the app yet.
     
     *The absence of the previous version does not mean the app is running for the very first time. Therefor check if the* `state` *is set to* `Installed`.
     
     - returns: The previousVersion version or `nil`.
     */
    private(set) public lazy var previousVersion: Version? = {
        if self._previousVersion == self.currentVersion {
            return nil
        }
        return self._previousVersion
    }()
    
    /**
     The previous version as stored in NSUserDefaults. Might be equal to the currentVersion in which case `previousVersion` should return `nil`. Hence the need for a 2nd property.
     */
    private(set) lazy var _previousVersion: Version? = self.userDefaults.previousVersionForKey(self.userDefaultsScope)
    
    /**
     - returns: The current version.
     */
    private(set) public lazy var currentVersion: Version = self.userDefaults.lastLaunchedVersionForkey(self.userDefaultsScope)!
    
    
    /**
     The app version state indicates version changes since the last launch of the app.
     */
    private(set) public lazy var changeState: Version.ChangeState = Version.changeStateForFromVersion(self._previousVersion, toVersion: self.currentVersion)
    
    
    /**
     The user defaults to store the version history in.
     */
    private let userDefaults: UserDefaults
    
    /**
     A string to build keys for storing version history of a particular verion to track.
     */
    private let userDefaultsScope : String
    
    
    /**
     Initializes and returns a newly allocated `VersionTracker` instance.
     When `VersionTracker.updateVersionHistory()` was called before, all properties will be lazy loaded to keep the memory footprint low.
     
     - parameter currentVersion: The current version.
     - parameter userDefaults: Pass in a NSUserDefaults object for storing and retrieving the version history. Defaults to `NSUserDefaults.standardUserDefaults()`.
     - parameter scope: A string to build keys for storing version history of a particular verion to track.
     */
    public init(currentVersion: Version, inScope scope: String, userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? UserDefaults.standard
        self.userDefaultsScope = scope
        // when initialize the first instance or the singleton instance, everything loaded in order to update the version history can be used
        if let stuff = VersionTracker.updateVersionHistoryOnce(
            withVersion: currentVersion,
            inScope: userDefaultsScope,
            onUserDefaults: self.userDefaults) {
                self.versionHistory = stuff.installedVersions
                self._previousVersion = stuff.previousVersion
                self.currentVersion = stuff.currentVerstion
                self.changeState = Version.changeStateForFromVersion(stuff.previousVersion, toVersion: stuff.currentVerstion)
        }
            // elsewise those properties will be lazy loaded
        else {
            // check if NSUserDefaults contain an entry for the current version
            // otherwise another NSUserDefaults object was used already, which is not supported
            if !self.userDefaults.hasLastLaunchedVersionSetInScope(userDefaultsScope) {
                fatalError("❗️VersionTracker was already initialized with another NSUserDefaults object before.")
            }
        }
    }
    
    
    fileprivate struct DidUpdateOnceTracking {
        fileprivate static var appVersion: Bool = false
        static var osVersion: Bool = false
    }
    
    /**
     Updates the version history once per session. To do so it loads the version history and creates a new version. This objects will be returned in a tuple.
     However, if it was already called befor it will return `nil` as the version history gets updates only once per app session.
     */
    internal static func updateVersionHistoryOnce(withVersion newVersion: Version, inScope userDefaultsScope: String, onUserDefaults userDefaults: UserDefaults) -> (installedVersions: [Version], previousVersion: Version?, currentVerstion: Version)?   {

        var result : (installedVersions: [Version], previousVersion: Version?, currentVerstion: Version)?

        // FIXME: find a better solution, e.g. storing a map of dispatch_once_t by scopes
        if userDefaultsScope == VersionsTracker.appVersionScope {
            if !DidUpdateOnceTracking.appVersion {
                result = updateVersionHistory(withVersion: newVersion, inScope: userDefaultsScope, onUserDefaults: userDefaults)
                DidUpdateOnceTracking.appVersion = true
            }
        }
        else if userDefaultsScope == VersionsTracker.osVersionScope {
            if !DidUpdateOnceTracking.osVersion {
                result = updateVersionHistory(withVersion: newVersion, inScope: userDefaultsScope, onUserDefaults: userDefaults)
                DidUpdateOnceTracking.appVersion = true
            }
        }
        else {
            fatalError("unsupported version scope '\(userDefaultsScope)'")
        }

        return result
    }
    
    private static func updateVersionHistory(withVersion newVersion: Version, inScope userDefaultsScope: String, onUserDefaults userDefaults: UserDefaults) -> (installedVersions: [Version], previousVersion: Version?, currentVerstion: Version) {
        var installedVersions = userDefaults.versionsInScope(userDefaultsScope)
        
        let currentVersion : Version
        if let knownCurrentVersion = installedVersions.filter({$0 == newVersion}).first {
            currentVersion = knownCurrentVersion
        } else {
            newVersion.installDate = Date()
            installedVersions.append(newVersion)
            userDefaults.setVersions(installedVersions, inScope: userDefaultsScope)
            currentVersion = newVersion
        }
        
        userDefaults.setLastLaunchedVersion(currentVersion, inScope: userDefaultsScope)
        
        return (installedVersions: installedVersions,
                previousVersion: userDefaults.previousVersionForKey(userDefaultsScope),
                currentVerstion: currentVersion)
    }
    
}

private extension UserDefaults {
    
    static let prefiex = "VersionsTracker"
    
    /**
     key for storing the last launched version in NSUserDefaults:
     - if the version stayed the same: holds the current version
     - if the version has changed:
     - holds the previous version before updateVersionHistoryOnce()
     - becomes the current version after updateVersionHistoryOnce()
     */
    static let lastLaunchedVersionKey = "lastLaunchedVersion"
    
    /**
     key for storing the antecessor version of the last launched version in NSUserDefaults
     - holds the version of the previous launch after updateVersionHistory()
     */
    static let previousLaunchedVersionKey = "previousLaunchedVersion"
    
    /*
    key for stroing the entire version history in NSUserDefaults
    */
    static let installedVersionsKey = "installedVersions"
    
    func versionsInScope(_ scope: String) -> [Version] {
        let key = buildKeyForProperty(UserDefaults.installedVersionsKey, inScope: scope)
        return (self.object(forKey: key) as? [NSDictionary])?.map { Version(dict: $0) } ?? []
    }
    
    func setVersions(_ versions: [Version], inScope scope: String) {
        let key = buildKeyForProperty(UserDefaults.installedVersionsKey, inScope: scope)
        self.set(versions.map{ $0.asDictionary }, forKey: key)
    }
    
    func previousVersionForKey(_ key: String) -> Version? {
        return versionForKey(key, property: UserDefaults.previousLaunchedVersionKey)
    }
    
    func hasLastLaunchedVersionSetInScope(_ scope: String) -> Bool {
        let key = buildKeyForProperty(UserDefaults.lastLaunchedVersionKey, inScope: scope)
        return self.dictionary(forKey: key) != nil
    }
    
    func lastLaunchedVersionForkey(_ key: String) -> Version? {
        return self.versionForKey(key, property: UserDefaults.lastLaunchedVersionKey)
    }
    
    func versionForKey(_ key: String, property: String) -> Version? {
        let versionDict = self.dictionary(forKey: buildKeyForProperty(property, inScope: key))
        return Version.versionFromDictionary(versionDict as NSDictionary?)
    }
    
    func buildKeyForProperty(_ property: String, inScope scope: String) -> String {
        return [UserDefaults.prefiex, scope, property].joined(separator: ".")
    }
    
    /**
     Updates the last launched version with the given version.
     
     **It should only be called once per scope with the current version.**
     
     It will move the current stored last launched version to the previous launched version slot.
     This allow retrieving the previous version at any time during the session.
     */
    func setLastLaunchedVersion(_ version: Version, inScope scope: String) {
        let lastLaunchedKey = buildKeyForProperty(UserDefaults.lastLaunchedVersionKey, inScope: scope)
        let prevLaunchedKey = buildKeyForProperty(UserDefaults.previousLaunchedVersionKey, inScope: scope)
        let lastLaunchedDictionary = self.dictionary(forKey: lastLaunchedKey)
        self.set(lastLaunchedDictionary, forKey: prevLaunchedKey)  // move the last version to the previous slot
        self.set(version.asDictionary, forKey: lastLaunchedKey) // update last version with the current
    }
}





// MARK: - Testing helpers -

internal extension VersionTracker {
    
    internal static func resetUpdateVersionHistoryOnceToken() {
        guard NSClassFromString("XCTest") != nil else { fatalError("this method shall only be called in unit tests") }
        DidUpdateOnceTracking.appVersion = false
        DidUpdateOnceTracking.osVersion = false
    }
}

internal extension UserDefaults {
    
    internal func resetInScope(_ scope: String) {
        self.removeObject(forKey: buildKeyForProperty(UserDefaults.previousLaunchedVersionKey, inScope: scope))
        self.removeObject(forKey: buildKeyForProperty(UserDefaults.lastLaunchedVersionKey, inScope: scope))
        self.removeObject(forKey: buildKeyForProperty(UserDefaults.installedVersionsKey, inScope: scope))
    }
    
}



