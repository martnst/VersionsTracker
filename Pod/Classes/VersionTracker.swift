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

public class VersionTracker {
    
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
    private let userDefaults: NSUserDefaults
    
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
    public init(currentVersion: Version, inScope scope: String, userDefaults: NSUserDefaults? = nil) {
        self.userDefaults = userDefaults ?? NSUserDefaults.standardUserDefaults()
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
    
    
    private struct OnceTokens {
        static var appToken: dispatch_once_t = 0
        static var osToken: dispatch_once_t = 0
    }
    
    /**
     Updates the version history once per session. To do so it loads the version history and creates a new version. This objects will be returned in a tuple.
     However, if it was already called befor it will return `nil` as the versino history gets updates only once per app session.
     */
    internal static func updateVersionHistoryOnce(var withVersion currentVersion: Version, inScope userDefaultsScope: String, onUserDefaults userDefaults: NSUserDefaults) -> (installedVersions: [Version], previousVersion: Version?, currentVerstion: Version)?   {
        
        var result : (installedVersions: [Version], previousVersion: Version?, currentVerstion: Version)?
        
        let updateBlock:(Void)->Void = { () -> Void in
            var installedVersions = userDefaults.versionsInScope(userDefaultsScope)
            
            if let knownCurrentVersion = installedVersions.filter({$0 == currentVersion}).first {
                currentVersion = knownCurrentVersion
            } else {
                currentVersion.installDate = NSDate()
                installedVersions.append(currentVersion)
                userDefaults.setVersions(installedVersions, inScope: userDefaultsScope)
            }
            
            userDefaults.setLastLaunchedVersion(currentVersion, inScope: userDefaultsScope)
            
            result = (installedVersions: installedVersions,
                previousVersion: userDefaults.previousVersionForKey(userDefaultsScope),
                currentVerstion: currentVersion)
        }
        
        // FIXME: find a better solution, e.g. storing a map of dispatch_once_t by scopes
        if userDefaultsScope == VersionsTracker.appVersionScope {
            dispatch_once(&OnceTokens.appToken, updateBlock)
        }
        else if userDefaultsScope == VersionsTracker.osVersionScope {
            dispatch_once(&OnceTokens.osToken, updateBlock)
        }
        else {
            fatalError("unsupported version scope '\(userDefaultsScope)'")
        }
        
        return result
    }
    
    
    
}

private extension NSUserDefaults {
    
    private static let prefiex = "VersionsTracker"
    
    /**
     key for storing the last launched version in NSUserDefaults:
     - if the version stayed the same: holds the current version
     - if the version has changed:
     - holds the previous version before updateVersionHistoryOnce()
     - becomes the current version after updateVersionHistoryOnce()
     */
    private static let lastLaunchedVersionKey = "lastLaunchedVersion"
    
    /**
     key for storing the antecessor version of the last launched version in NSUserDefaults
     - holds the version of the previous launch after updateVersionHistory()
     */
    private static let previousLaunchedVersionKey = "previousLaunchedVersion"
    
    /*
    key for stroing the entire version history in NSUserDefaults
    */
    private static let installedVersionsKey = "installedVersions"
    
    func versionsInScope(scope: String) -> [Version] {
        let key = buildKeyForProperty(NSUserDefaults.installedVersionsKey, inScope: scope)
        return (self.objectForKey(key) as? [NSDictionary])?.map { Version(dict: $0) } ?? []
    }
    
    func setVersions(versions: [Version], inScope scope: String) {
        let key = buildKeyForProperty(NSUserDefaults.installedVersionsKey, inScope: scope)
        self.setObject(versions.map{ $0.asDictionary }, forKey: key)
    }
    
    func previousVersionForKey(key: String) -> Version? {
        return versionForKey(key, property: NSUserDefaults.previousLaunchedVersionKey)
    }
    
    func hasLastLaunchedVersionSetInScope(scope: String) -> Bool {
        let key = buildKeyForProperty(NSUserDefaults.lastLaunchedVersionKey, inScope: scope)
        return self.dictionaryForKey(key) != nil
    }
    
    func lastLaunchedVersionForkey(key: String) -> Version? {
        return self.versionForKey(key, property: NSUserDefaults.lastLaunchedVersionKey)
    }
    
    private func versionForKey(var key: String, property: String) -> Version? {
        key = buildKeyForProperty(property, inScope: key)
        return Version.versionFromDictionary(self.dictionaryForKey(key))
    }
    
    private func buildKeyForProperty(property: String, inScope scope: String) -> String {
        return [NSUserDefaults.prefiex, scope, property].joinWithSeparator(".")
    }
    
    /**
     Updates the last launched version with the given version.
     
     **It should only be called once per scope with the current version.**
     
     It will move the current stored last launched version to the previous launched version slot.
     This allow retrieving the previous version at any time during the session.
     */
    func setLastLaunchedVersion(version: Version, inScope scope: String) {
        let lastLaunchedKey = buildKeyForProperty(NSUserDefaults.lastLaunchedVersionKey, inScope: scope)
        let prevLaunchedKey = buildKeyForProperty(NSUserDefaults.previousLaunchedVersionKey, inScope: scope)
        let lastLaunchedDictionary = self.dictionaryForKey(lastLaunchedKey)
        self.setObject(lastLaunchedDictionary, forKey: prevLaunchedKey)  // move the last version to the previous slot
        self.setObject(version.asDictionary, forKey: lastLaunchedKey) // update last version with the current
    }
}





// MARK: - Testing helpers -

internal extension VersionTracker {
    
    internal static func resetUpdateVersionHistoryOnceToken() {
        guard NSClassFromString("XCTest") != nil else { fatalError("this method shall only be called in unit tests") }
        OnceTokens.appToken = 0
        OnceTokens.osToken = 0
    }
}

internal extension NSUserDefaults {
    
    internal func resetInScope(scope: String) {
        self.removeObjectForKey(buildKeyForProperty(NSUserDefaults.previousLaunchedVersionKey, inScope: scope))
        self.removeObjectForKey(buildKeyForProperty(NSUserDefaults.lastLaunchedVersionKey, inScope: scope))
        self.removeObjectForKey(buildKeyForProperty(NSUserDefaults.installedVersionsKey, inScope: scope))
    }
    
}



