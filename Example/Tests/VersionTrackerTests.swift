//
//  VersionTrackerTests.swift
//  VersionsTracker
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

class VersionTrackerTests: QuickSpec {
    override func spec() {
        describe("VersionTracker") {
            context("used with custom NSUserDefaults") {
                let scope = "appVersion"
                let userDefaults = UserDefaults(suiteName: "AppVersionTrackerTests")!
                userDefaults.resetInScope(scope)
                
                let versions = [
                    Version("1.0", buildString: "1"),  // install
                    Version("1.0", buildString: "2"),  // update
                    Version("1.1", buildString: "3"),  // upgrade
                    Version("1.0", buildString: "2")   // downgrade
                ]
                
                beforeEach {
                    VersionTracker.resetUpdateVersionHistoryOnceToken()
                }
                
                it("detects the very first app launch as Installed state") {
                    let versionTracker = VersionTracker(currentVersion: versions[0], inScope: scope, userDefaults: userDefaults)
                    expect(versionTracker.changeState).to(equal(Version.ChangeState.installed));
                }
                
                it("it will notice NotChanged for the second launch") {
                    let versionTracker = VersionTracker(currentVersion: versions[0], inScope: scope, userDefaults: userDefaults)
                    expect(versionTracker.changeState).to(equal(Version.ChangeState.notChanged));
                }
                
                it("it will notice build Updates") {
                    let versionTracker = VersionTracker(currentVersion: versions[1], inScope: scope, userDefaults: userDefaults)
                    expect(versionTracker.changeState).to(equal(Version.ChangeState.update(previousVersion: Version("1.0", buildString: "1"))));
                }
                
                it("it will notice markting version upgrades") {
                    let versionTracker = VersionTracker(currentVersion: versions[2], inScope: scope, userDefaults: userDefaults)
                    expect(versionTracker.changeState).to(equal(Version.ChangeState.upgraded(previousVersion: Version("1.0", buildString: "2"))));
                }
                
                it("it will notice version downgrades") {
                    let versionTracker = VersionTracker(currentVersion: versions[3], inScope: scope, userDefaults: userDefaults)
                    expect(versionTracker.changeState).to(equal(Version.ChangeState.downgraded(previousVersion: Version("1.1", buildString: "3"))));
                }
                
                it("update version history only once") {
                    let result1 = VersionTracker.updateVersionHistoryOnce(withVersion: versions[0], inScope: scope, onUserDefaults: userDefaults)
                    let result2 = VersionTracker.updateVersionHistoryOnce(withVersion: versions[0], inScope: scope, onUserDefaults: userDefaults)
                    expect(result1).toNot(beNil())
                    expect(result2).to(beNil()) // nil indicated the history was already updated
                }
                
            }
        }
    }
}