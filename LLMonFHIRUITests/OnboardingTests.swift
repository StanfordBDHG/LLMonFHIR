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
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--showOnboarding"]
        app.deleteAndLaunch(withSpringboardAppName: "LLMonFHIR")
    }
    
    
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        
        try app.navigateOnboardingFlow(assertThatHealthKitConsentIsShown: true)
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
        try navigateOnboardingFlowOpenAI()
        try navigateOnboardingFlowHealthKitAccess(assertThatHealthKitConsentIsShown: assertThatHealthKitConsentIsShown)
    }
    
    private func navigateOnboardingFlowWelcome() throws {
        XCTAssertTrue(staticTexts["LLM on FHIR"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(buttons["Learn More"].waitForExistence(timeout: 2))
        buttons["Learn More"].tap()
    }
    
    private func navigateOnboardingFlowInterestingModules() throws {
        XCTAssertTrue(staticTexts["Disclaimer"].waitForExistence(timeout: 2))
        
        for _ in 1..<5 {
            XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
            buttons["Next"].tap()
        }
        
        XCTAssertTrue(buttons["I Agree"].waitForExistence(timeout: 2))
        buttons["I Agree"].tap()
    }
    
    private func navigateOnboardingFlowOpenAI() throws {
        try textFields["OpenAI API Key"].enter(value: "sk-123456789")
        
        XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
        buttons["Next"].tap()
    }
    
    private func navigateOnboardingFlowHealthKitAccess(assertThatHealthKitConsentIsShown: Bool = true) throws {
        XCTAssertTrue(staticTexts["HealthKit Access"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(buttons["Grant Access"].waitForExistence(timeout: 2))
        buttons["Grant Access"].tap()
    }
}
