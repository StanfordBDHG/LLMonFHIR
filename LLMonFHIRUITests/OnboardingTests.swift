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
        let app = XCUIApplication()
        app.launchEnvironment["LLMONFHIR_IS_BEING_UI_TESTED"] = "1"
        app.launchArguments = ["--showOnboarding", "--mode", "test"]
        app.launch()
    }
    
    
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        
        try app.navigateOnboardingFlow()
    }
}


extension XCUIApplication {
    func navigateOnboardingFlow() throws {
        try navigateOnboardingFlowWelcome()
        try navigateOnboardingFlowInterestingModules()
        try navigateOnboardingFlowOpenAI()
        try navigateOnboardingFlowHealthKitAccess()
    }
    
    private func navigateOnboardingFlowWelcome() throws {
        XCTAssertTrue(staticTexts["LLMonFHIR"].waitForExistence(timeout: 2))
        
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
        try textFields["API Key…"].enter(value: "sk-123456789")
        
        XCTAssertTrue(buttons["Continue"].waitForExistence(timeout: 2))
        buttons["Continue"].tap()
        
        XCTAssertTrue(buttons["Save Model Selection"].waitForExistence(timeout: 2))
        buttons["Save Model Selection"].tap()
        
        XCTAssertTrue(buttons["Save Choice"].waitForExistence(timeout: 2))
        buttons["Save Choice"].tap()
    }
    
    private func navigateOnboardingFlowHealthKitAccess() throws {
        XCTAssertTrue(staticTexts["Health Records Access"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(buttons["Continue"].waitForExistence(timeout: 2))
        buttons["Continue"].tap()
    }
}
