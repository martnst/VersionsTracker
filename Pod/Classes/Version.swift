// Version.swift
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

private func parseVersion(lhs: Version, rhs: Version) -> Zip2Sequence<[Int], [Int]> {
    
    let lhs = lhs.versionString.characters.split(".").map { (String($0) as NSString).integerValue }
    let rhs = rhs.versionString.characters.split(".").map { (String($0) as NSString).integerValue }
    let count = max(lhs.count, rhs.count)
    return zip(
        lhs + Array(count: count - lhs.count, repeatedValue: 0),
        rhs + Array(count: count - rhs.count, repeatedValue: 0))
}

public func == (lhs: Version, rhs: Version) -> Bool {
    
    var result: Bool = true
    for (l, r) in parseVersion(lhs, rhs: rhs) {
        
        if l != r {
            result = false
        }
    }
    
    if result == true {
        result = lhs.buildString == rhs.buildString
    }
    
    return result
}

public func < (lhs: Version, rhs: Version) -> Bool {
    
    for (l, r) in parseVersion(lhs, rhs: rhs) {
        if l < r {
            return true
        } else if l > r {
            return false
        }
    }
    return false
}

public class Version: StringLiteralConvertible, Comparable {
    
    internal class var currentAppVersion: Version {
        guard let infoDict = NSBundle.mainBundle().infoDictionary else {
            fatalError()
        }
        return Version(infoDict["CFBundleShortVersionString"] as! String, buildString: infoDict[kCFBundleVersionKey as String] as? String, installDate: nil)
    }
    
    internal class var currentOSVersion : Version {
        let systemVersion = NSProcessInfo.processInfo().operatingSystemVersion
        let systemVersionString = [systemVersion.majorVersion, systemVersion.minorVersion, systemVersion.patchVersion].map({String($0)}).joinWithSeparator(".")
        let systemVersionStringScanner = NSScanner(string: NSProcessInfo.processInfo().operatingSystemVersionString)
        var build: NSString?
        systemVersionStringScanner.scanUpToString("(Build", intoString: nil)
        systemVersionStringScanner.scanUpToString(" ", intoString: nil)
        systemVersionStringScanner.scanUpToString(")", intoString: &build)
        return Version(systemVersionString, buildString: build as? String)
    }
    
    public let versionString: String
    public let buildString: String
    internal(set) public var installDate: NSDate
    
    public init(_ versionString: String, buildString build: String? = nil, installDate date: NSDate? = nil) {
        self.versionString = versionString
        self.buildString = build ?? ""
        self.installDate = date ?? NSDate()
    }
    
    // MARK: NSUserDefaults serialization
    
    private static let versionStringKey = "versionString"
    private static let buildStringKey = "buildString"
    private static let installDateKey = "installDate"
    
    internal convenience init(dict: NSDictionary) {
        self.init(dict[Version.versionStringKey] as! String,
            buildString: dict[Version.buildStringKey] as? String,
            installDate: dict[Version.installDateKey] as? NSDate)
    }
    
    internal static func versionFromDictionary(dict: NSDictionary?) -> Version? {
        if let dictionary = dict {
            return Version(dict: dictionary)
        }
        return nil
    }
    
    internal var asDictionary: NSDictionary {
        get {
            return [
                Version.versionStringKey : self.versionString,
                Version.buildStringKey : self.buildString,
                Version.installDateKey : self.installDate
            ]
        }
    }
    
    
    // MARK: StringLiteralConvertible
    
    public required init(stringLiteral value: String) {
        self.versionString = value
        self.buildString = ""
        self.installDate = NSDate()
    }
    
    public required init(unicodeScalarLiteral value: String) {
        self.versionString = value
        self.buildString = ""
        self.installDate = NSDate()
    }
    
    public required init(extendedGraphemeClusterLiteral value: String) {
        self.versionString = value
        self.buildString = ""
        self.installDate = NSDate()
    }
}

extension Version: CustomStringConvertible {
    public var description: String {
        return "\(self.versionString) (\(self.buildString))"
    }
}

extension Version {
    
    /**
     The app version state indicates version changes since the last launch of the app.
     - Installed: clean install, very first launch
     - NotChanged: version not changed
     - Update: build string changed, but marketing version stayed the same
     - Upgraded: marketing version increased
     - Downgraded: markting version decreased
     */
    public enum ChangeState {
        case Installed
        case NotChanged
        case Update(previousVersion: Version)
        case Upgraded(previousVersion: Version)
        case Downgraded(previousVersion: Version)
    }
    
    /**
     Determines the change state from one version to another.
     */
    internal static func changeStateForFromVersion(olderVersion: Version?, toVersion newerVersion: Version) -> ChangeState {
        guard let olderVersion = olderVersion else {
            return .Installed
        }
        
        if olderVersion < newerVersion {
            return .Upgraded(previousVersion: olderVersion)
        }
        else if olderVersion > newerVersion {
            return .Downgraded(previousVersion: olderVersion)
        }
        else if olderVersion != newerVersion {
            return .Update(previousVersion: olderVersion)
        }
        return .NotChanged
    }
    
}


extension Version.ChangeState: Equatable {
}

public func ==(lhs: Version.ChangeState, rhs: Version.ChangeState) -> Bool {
    switch (lhs, rhs) {
    case (.Installed, .Installed):
        return true
    case (.NotChanged, .NotChanged):
        return true
    case (let .Update(previousVersionLHS), let .Update(previousVersionRHS)):
        return previousVersionLHS == previousVersionRHS
    case (let .Upgraded(previousVersionLHS), let .Upgraded(previousVersionRHS)):
        return previousVersionLHS == previousVersionRHS
    case (let .Downgraded(previousVersionLHS), let .Downgraded(previousVersionRHS)):
        return previousVersionLHS == previousVersionRHS
    default:
        return false
    }
}
