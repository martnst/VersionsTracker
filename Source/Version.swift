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

private func parseVersion(_ lhs: Version, rhs: Version) -> Zip2Sequence<[Int], [Int]> {
    
    let lhs = lhs.versionString.characters.split(separator: ".").map { (String($0) as NSString).integerValue }
    let rhs = rhs.versionString.characters.split(separator: ".").map { (String($0) as NSString).integerValue }
    let count = max(lhs.count, rhs.count)
    return zip(
        lhs + Array(repeating: 0, count: count - lhs.count),
        rhs + Array(repeating: 0, count: count - rhs.count))
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

open class Version: ExpressibleByStringLiteral, Comparable {
    
    internal class var currentAppVersion: Version {
        guard let infoDict = Bundle.main.infoDictionary else {
            fatalError()
        }
        return Version(infoDict["CFBundleShortVersionString"] as! String, buildString: infoDict[kCFBundleVersionKey as String] as? String, installDate: nil)
    }
    
    internal class var currentOSVersion : Version {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let systemVersionString = [systemVersion.majorVersion, systemVersion.minorVersion, systemVersion.patchVersion].map({String($0)}).joined(separator: ".")
        let systemVersionStringScanner = Scanner(string: ProcessInfo.processInfo.operatingSystemVersionString)
        var build: NSString?
        systemVersionStringScanner.scanUpTo("(Build", into: nil)
        systemVersionStringScanner.scanUpTo(" ", into: nil)
        systemVersionStringScanner.scanUpTo(")", into: &build)
        return Version(systemVersionString, buildString: build as String?)
    }
    
    public let versionString: String
    public let buildString: String
    internal(set) public var installDate: Date
    
    public init(_ versionString: String, buildString build: String? = nil, installDate date: Date? = nil) {
        self.versionString = versionString
        self.buildString = build ?? ""
        self.installDate = date ?? Date()
    }
    
    // MARK: NSUserDefaults serialization
    
    private static let versionStringKey = "versionString"
    private static let buildStringKey = "buildString"
    private static let installDateKey = "installDate"
    
    internal convenience init(dict: NSDictionary) {
        self.init(dict[Version.versionStringKey] as! String,
            buildString: dict[Version.buildStringKey] as? String,
            installDate: dict[Version.installDateKey] as? Date)
    }
    
    internal static func versionFromDictionary(_ dict: NSDictionary?) -> Version? {
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
        self.installDate = Date()
    }
    
    public required init(unicodeScalarLiteral value: String) {
        self.versionString = value
        self.buildString = ""
        self.installDate = Date()
    }
    
    public required init(extendedGraphemeClusterLiteral value: String) {
        self.versionString = value
        self.buildString = ""
        self.installDate = Date()
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
        case installed
        case notChanged
        case updated(previousVersion: Version)
        case upgraded(previousVersion: Version)
        case downgraded(previousVersion: Version)
    }
    
    /**
     Determines the change state from one version to another.
     */
    internal static func changeStateForFromVersion(_ olderVersion: Version?, toVersion newerVersion: Version) -> ChangeState {
        guard let olderVersion = olderVersion else {
            return .installed
        }
        
        if olderVersion < newerVersion {
            return .upgraded(previousVersion: olderVersion)
        }
        else if olderVersion > newerVersion {
            return .downgraded(previousVersion: olderVersion)
        }
        else if olderVersion != newerVersion {
            return .updated(previousVersion: olderVersion)
        }
        return .notChanged
    }
    
}


extension Version.ChangeState: Equatable {
}

public func ==(lhs: Version.ChangeState, rhs: Version.ChangeState) -> Bool {
    switch (lhs, rhs) {
    case (.installed, .installed):
        return true
    case (.notChanged, .notChanged):
        return true
    case (let .updated(previousVersionLHS), let .updated(previousVersionRHS)):
        return previousVersionLHS == previousVersionRHS
    case (let .upgraded(previousVersionLHS), let .upgraded(previousVersionRHS)):
        return previousVersionLHS == previousVersionRHS
    case (let .downgraded(previousVersionLHS), let .downgraded(previousVersionRHS)):
        return previousVersionLHS == previousVersionRHS
    default:
        return false
    }
}
