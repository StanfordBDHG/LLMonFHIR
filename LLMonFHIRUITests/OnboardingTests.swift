//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions
import XCTHealthKit


class OnboardingTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try disablePasswordAutofill()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--showOnboarding"]
        app.deleteAndLaunch(withSpringboardAppName: "LLMonFHIR")
    }
    
    
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        
        try app.navigateOnboardingFlow(assertThatHealthKitConsentIsShown: true)
        
        let tabBar = app.tabBars["Tab Bar"]
        XCTAssertTrue(tabBar.buttons["Schedule"].waitForExistence(timeout: 2))
        XCTAssertTrue(tabBar.buttons["Contacts"].waitForExistence(timeout: 2))
        XCTAssertTrue(tabBar.buttons["Mock Upload"].waitForExistence(timeout: 2))
    }
}


extension XCUIApplication {
    func conductOnboardingIfNeeded() throws {
        if self.staticTexts["LLMonFHIR"].waitForExistence(timeout: 5) {
            try navigateOnboardingFlow(assertThatHealthKitConsentIsShown: false)
        }
    }
    
    func navigateOnboardingFlow(assertThatHealthKitConsentIsShown: Bool = true) throws {
        try navigateOnboardingFlowWelcome()
        try navigateOnboardingFlowInterestingModules()
        try navigateOnboardingFlowConsent()
        try navigateOnboardingFlowHealthKitAccess(assertThatHealthKitConsentIsShown: assertThatHealthKitConsentIsShown)
    }
    
    private func navigateOnboardingFlowWelcome() throws {
        XCTAssertTrue(staticTexts["LLMonFHIR"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(buttons["Learn More"].waitForExistence(timeout: 2))
        buttons["Learn More"].tap()
    }
    
    private func navigateOnboardingFlowInterestingModules() throws {
        XCTAssertTrue(staticTexts["Interesting Modules"].waitForExistence(timeout: 2))
        
        for _ in 1..<4 {
            XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
            buttons["Next"].tap()
        }
        
        XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
        buttons["Next"].tap()
    }
    
    private func navigateOnboardingFlowConsent() throws {
        XCTAssertTrue(staticTexts["Consent Example"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(staticTexts["First Name"].waitForExistence(timeout: 2))
        try textFields["Enter your first name ..."].enter(value: "Leland")
        textFields["Enter your first name ..."].typeText("\n")
        
        XCTAssertTrue(staticTexts["Last Name"].waitForExistence(timeout: 2))
        try textFields["Enter your last name ..."].enter(value: "Stanford")
        textFields["Enter your last name ..."].typeText("\n")
        
        XCTAssertTrue(staticTexts["Leland Stanford"].waitForExistence(timeout: 2))
        staticTexts["Leland Stanford"].firstMatch.swipeUp()
        
        XCTAssertTrue(buttons["I Consent"].waitForExistence(timeout: 2))
        buttons["I Consent"].tap()
    }
    
    private func navigateOnboardingFlowHealthKitAccess(assertThatHealthKitConsentIsShown: Bool = true) throws {
        XCTAssertTrue(staticTexts["HealthKit Access"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(buttons["Grant Access"].waitForExistence(timeout: 2))
        buttons["Grant Access"].tap()
        
        try handleHealthKitAuthorization()
    }
}
