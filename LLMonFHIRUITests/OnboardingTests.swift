//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions
import XCTHealthKit


@MainActor
class OnboardingTests: XCTestCase, Sendable {
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }
    
    
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .health)
        app.launchArguments = ["--showOnboarding", "--mode", "test"]
        app.launch()
        try app.navigateOnboardingFlowWelcome()
        try app.navigateOnboardingFlowDisclaimers()
        try app.navigateOnboardingFlowOpenAI()
        try app.navigateOnboardingFlowHealthKitAccess()
    }
}


extension XCUIApplication {
    fileprivate func navigateOnboardingFlowWelcome() throws {
        XCTAssertTrue(staticTexts["LLMonFHIR"].waitForExistence(timeout: 2))
        XCTAssertTrue(buttons["Learn More"].waitForExistence(timeout: 2))
        buttons["Learn More"].tap()
    }
    
    
    fileprivate func navigateOnboardingFlowDisclaimers() throws {
        XCTAssertTrue(staticTexts["Disclaimer"].waitForExistence(timeout: 2))
        for _ in 1..<5 {
            XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
            buttons["Next"].tap()
        }
        XCTAssertTrue(buttons["I Agree"].waitForExistence(timeout: 2))
        buttons["I Agree"].tap()
    }
    
    
    fileprivate func navigateOnboardingFlowOpenAI() throws {
        try textFields["API Key…"].clear()
        XCTAssertEqual(textFields["API Key…"].textFieldValue, "")
        try textFields["API Key…"].enter(value: "sk-123456789")
        
        XCTAssertTrue(buttons["Continue"].waitForExistence(timeout: 2))
        buttons["Continue"].tap()
        
        XCTAssertTrue(buttons["Save Model Selection"].waitForExistence(timeout: 2))
        buttons["Save Model Selection"].tap()
        
        XCTAssertTrue(buttons["Save Choice"].waitForExistence(timeout: 2))
        buttons["Save Choice"].tap()
    }
    
    
    fileprivate func navigateOnboardingFlowHealthKitAccess() throws {
        XCTAssertTrue(staticTexts["Health Records Access"].waitForExistence(timeout: 2))
        XCTAssertTrue(buttons["Continue"].waitForExistence(timeout: 2))
        buttons["Continue"].tap()
    }
}
