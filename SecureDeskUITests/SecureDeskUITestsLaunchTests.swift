//
//  SecureDeskUITestsLaunchTests.swift
//  SecureDeskUITests
//
//  Created by Vipin Saini
//

import XCTest

final class SecureDeskUITestsLaunchTests: XCTestCase {
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["USE_MOCK_SERVICES"] = "true"
        app.launch()
        
        // Verify app launches with login screen
        XCTAssertTrue(app.staticTexts["SecureDesk"].exists)
        
        // Take a screenshot of launch state
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let app = XCUIApplication()
                app.launchEnvironment["USE_MOCK_SERVICES"] = "true"
                app.launch()
            }
        }
    }
}
