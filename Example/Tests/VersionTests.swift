//
//  VersionTests.swift
//  VersionTracker
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

// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import VersionsTracker

class VersionTests: QuickSpec {
    override func spec() {
        describe("Version") {
            
            describe("currentVersion") {
                let infoDict = NSBundle.mainBundle().infoDictionary!
                it("versionString is set to CFBundleShortVersionString from info.plist") {
                    expect(Version.currentAppVersion.versionString).to(equal(infoDict["CFBundleShortVersionString"] as? String))
                }
                it("buildString is set to kCFBundleVersionKey from info.plist") {
                    expect(Version.currentAppVersion.buildString).to(equal(infoDict[kCFBundleVersionKey as String] as? String))
                }
            }
            
            describe("can compare") {
                describe("with another Version") {
                    it("can handle smaller or equal") {
                        let version = Version("1.2.3")
                        // positive tests
                        expect(version).to(beLessThanOrEqualTo(Version("1.2.3")))
                        expect(version).to(beLessThan(Version("1.2.3.1")))
                        expect(version).to(beLessThan(Version("1.2.3.1.2.3")))
                        expect(version).to(beLessThan(Version("1.2.3.1111")))
                        expect(version).to(beLessThan(Version("1.2.3.4.5.6.7.8.9")))
                        expect(version).to(beLessThan(Version("1.2.33")))
                        expect(version).to(beLessThan(Version("1.2.4")))
                        expect(version).to(beLessThan(Version("1.22")))
                        expect(version).to(beLessThan(Version("1.22.0")))
                        expect(version).to(beLessThan(Version("1.222.0")))
                        expect(version).to(beLessThan(Version("1.3")))
                        expect(version).to(beLessThan(Version("1.3.0")))
                        expect(version).to(beLessThan(Version("1.3.1")))
                        expect(version).to(beLessThan(Version("1.3.3")))
                        expect(version).to(beLessThan(Version("2.0")))
                        expect(version).to(beLessThan(Version("2.0.0")))
                        expect(version).to(beLessThan(Version("2.2")))
                        expect(version).to(beLessThan(Version("2.2.2")))
                        // negative tests
                        expect(version).toNot(beLessThan(Version("1.0")))
                        expect(version).toNot(beLessThan(Version("1.1")))
                        expect(version).toNot(beLessThan(Version("1.2")))
                        expect(version).toNot(beLessThan(Version("1.2.1")))
                        expect(version).toNot(beLessThan(Version("1.2.1.2")))
                        expect(version).toNot(beLessThan(Version("1.2.1.2.1")))
                        expect(version).toNot(beLessThan(Version("1.2.1.222.1")))
                    }
                    
                    it("treats same semantic versions as equal") {
                        let version = Version("2.0.0")
                        expect(version).to(equal(Version("2.0")))
                        expect(version).to(equal(Version("2.0.0")))
                        expect(version).to(equal(Version("2.0.0.0")))
                        expect(version).to(equal(Version("2.00.00.0.0")))
                    }
                    
                    it("treats diffenrent semantic versions not equal") {
                        let version = Version("2.0.0")
                        expect(version).toNot(equal(Version("2.1")))
                        expect(version).toNot(equal(Version("2.0.1")))
                        expect(version).toNot(equal(Version("2.0.0.1")))
                        expect(version).toNot(equal(Version("2.00.00.0.1")))
                    }
                    
                    it("treats same semantic versions but different builds as not equal") {
                        let version = Version("2.0.0", buildString: "B0815")
                        expect(version).to(equal(Version("2.0", buildString: "B0815")))
                        expect(version).to(equal(Version("2.0.0", buildString: "B0815")))
                        expect(version).to(equal(Version("2.0.0.0", buildString: "B0815")))
                        expect(version).toNot(equal(Version("2.00.00.0.0", buildString: "B4711")))
                        expect(version).toNot(equal(Version("2.0", buildString: "B4711")))
                        expect(version).toNot(equal(Version("2.0.0", buildString: "B4711")))
                        expect(version).toNot(equal(Version("2.0.0.0", buildString: "B4711")))
                        expect(version).toNot(equal(Version("2.00.00.0.0", buildString: "B4711")))
                    }
                    
                    it("does not care about installDate when semantic versions and builds are equal") {
                        let version = Version("2.0.0", buildString: "B0815", installDate: NSDate())
                        let laterDate = NSDate(timeIntervalSinceNow: 30)
                        let earlierDate = NSDate(timeIntervalSinceNow: -30)
                        expect(version).to(equal(Version("2.0", buildString: "B0815", installDate: earlierDate)))
                        expect(version).to(equal(Version("2.0.0", buildString: "B0815", installDate: earlierDate)))
                        expect(version).to(equal(Version("2.0.0.0", buildString: "B0815", installDate: earlierDate)))
                        expect(version).to(equal(Version("2.00.00.0.0", buildString: "B0815", installDate: earlierDate)))
                        expect(version).to(equal(Version("2.0", buildString: "B0815", installDate: laterDate)))
                        expect(version).to(equal(Version("2.0.0", buildString: "B0815", installDate: laterDate)))
                        expect(version).to(equal(Version("2.0.0.0", buildString: "B0815", installDate: laterDate)))
                        expect(version).to(equal(Version("2.00.00.0.0", buildString: "B0815", installDate: laterDate)))
                    }
                }
                
                
                describe("with another Strings") {
                    it("can handle smaller or equal") {
                        let version = Version("1.2.3")
                        // positive tests
                        expect(version).to(beLessThanOrEqualTo("1.2.3"))
                        expect(version).to(beLessThan("1.2.3.1"))
                        expect(version).to(beLessThan("1.2.3.1.2.3"))
                        expect(version).to(beLessThan("1.2.3.1111"))
                        expect(version).to(beLessThan("1.2.3.4.5.6.7.8.9"))
                        expect(version).to(beLessThan("1.2.33"))
                        expect(version).to(beLessThan("1.2.4"))
                        expect(version).to(beLessThan("1.22"))
                        expect(version).to(beLessThan("1.22.0"))
                        expect(version).to(beLessThan("1.222.0"))
                        expect(version).to(beLessThan("1.3"))
                        expect(version).to(beLessThan("1.3.0"))
                        expect(version).to(beLessThan("1.3.1"))
                        expect(version).to(beLessThan("1.3.3"))
                        expect(version).to(beLessThan("2.0"))
                        expect(version).to(beLessThan("2.0.0"))
                        expect(version).to(beLessThan("2.2"))
                        expect(version).to(beLessThan("2.2.2"))
                        // negative tests
                        expect(version).toNot(beLessThan("1.0"))
                        expect(version).toNot(beLessThan("1.1"))
                        expect(version).toNot(beLessThan("1.2"))
                        expect(version).toNot(beLessThan("1.2.1"))
                        expect(version).toNot(beLessThan("1.2.1.2"))
                        expect(version).toNot(beLessThan("1.2.1.2.1"))
                        expect(version).toNot(beLessThan("1.2.1.222.1"))
                    }
                    
                    it("treats same semantic versions as equal") {
                        let version = Version("2.0.0")
                        expect(version).to(equal("2.0"))
                        expect(version).to(equal("2.0.0"))
                        expect(version).to(equal("2.0.0.0"))
                        expect(version).to(equal("2.00.00.0.0"))
                    }
                    
                    it("treats diffenrent semantic versions not equal") {
                        let version = Version("2.0.0")
                        expect(version).toNot(equal("2.1"))
                        expect(version).toNot(equal("2.0.1"))
                        expect(version).toNot(equal("2.0.0.1"))
                        expect(version).toNot(equal("2.00.00.0.1"))
                    }
                }
            }
            
            it("can comepare app version strings being smaller or equal") {
                expect(Version("1.4.5") <= "1.5.5") == true
                expect(Version("1.4.5") <= "1.5.5") == true
                expect(Version("1.4.5") <= "1.55.0") == true
                expect(Version("1.4.5") <= "1.555.0") == true
                expect(Version("1.4.5") <= "1.4.5.4") == true
                expect(Version("1.4.5") <= "1.4.5.3.4.6") == true
                expect(Version("1.4.5") <= "2.0.0") == true
                
                expect(Version("1.5.5") <= "1.4.5") == false
                expect(Version("1.55.0") <= "1.4.5") == false
                expect(Version("1.555.0") <= "1.4.5") == false
                expect(Version("1.4.5.4") <= "1.4.5") == false
                expect(Version("1.4.5.3.4.6.") <= "1.4.5") == false
                expect(Version("2.0.0") <= "1.4.5") == false
            }
            
            
            describe("can determine version changes") {
                it("detects clean installs") {
                    expect(Version.changeStateForFromVersion(nil, toVersion: Version("1.0", buildString: "19", installDate: NSDate()))).to(equal(Version.ChangeState.Installed))
                }
                it("detects same version as not changed") {
                    let prevVersion = Version("1.0", buildString: "19", installDate: NSDate())
                    let curVersion = Version("1.0", buildString: "19", installDate: NSDate())
                    expect(Version.changeStateForFromVersion(prevVersion, toVersion: curVersion)).to(equal(Version.ChangeState.NotChanged))
                }
                it("detects updates") {
                    let prevVersion = Version("1.0", buildString: "19", installDate: NSDate())
                    let curVersion = Version("1.0", buildString: "20", installDate: NSDate())
                    expect(Version.changeStateForFromVersion(prevVersion, toVersion: curVersion)).to(equal(Version.ChangeState.Update(previousVersion: prevVersion)))
                }
                it("detects upgrades") {
                    let prevVersion = Version("1.0", buildString: "19", installDate: NSDate())
                    let curVersion = Version("1.1", buildString: "20", installDate: NSDate())
                    expect(Version.changeStateForFromVersion(prevVersion, toVersion: curVersion)).to(equal(Version.ChangeState.Upgraded(previousVersion: prevVersion)))
                }
                it("detects downgrades") {
                    let prevVersion = Version("1.1", buildString: "19", installDate: NSDate())
                    let curVersion = Version("1.0", buildString: "19", installDate: NSDate())
                    expect(Version.changeStateForFromVersion(prevVersion, toVersion: curVersion)).to(equal(Version.ChangeState.Downgraded(previousVersion: prevVersion)))
                }
            }
            
        }
        
    }
}


