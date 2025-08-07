//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class FHIRDisplayTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["--skipOnboarding", "--testMode", "--mockPatients"]
        
        app.deleteAndLaunch(withSpringboardAppName: "LLMonFHIR")
    }

    func testFHIRResourcesView() throws {
        let app = XCUIApplication()
        
        app.swipeUp()

        let mockResource = app.staticTexts["Mock Resource"]
        XCTAssertTrue(mockResource.exists, "The 'Mock Resource' does not exist.")

        mockResource.tap()
        sleep(2)
        let newScreenMockResourceText = app.staticTexts["Mock Resource"]
        XCTAssertTrue(newScreenMockResourceText.exists, "The 'Mock Resource' text does not exist on the new screen.")
    }
    
    @MainActor
    func testLLMOnFHIRPaperTest() async throws {
        throw XCTSkip()
        
        let app = XCUIApplication()
        
        let patients = [
            "Allen322 Ferry570",
            "Beatris270 Bogan287",
            "Edythe31 Morar593",
            "Gonzalo160 Dueñas839",
            "Jacklyn830 Veum823",
            "Milton509 Ortiz186"
        ]
        
        let questions = [
            "What are my current medications and how should I be taking them?",
            "What are the most common side effects for each medication I am taking?",
            "Am I allergic to any of my medications?",
            "Can you summarize my current medical conditions?",
            "What are the health behaviors I should be incorporating into my daily routine to help with my conditions?",
            "Can you summarize my current medical conditions in German?",
            "What are my recent laboratory values, what do they mean, and how can I improve them?"
        ]
        
        for patient in patients {
            app.navigationBars["Your Health Records"].buttons["Settings"].testExistanceAndTap()
            app.staticTexts["Resources Selection"].testExistanceAndTap()
            
            app.buttons[patient].testExistanceAndTap(timeout: 20)
            app.navigationBars["Resources Settings"].buttons["Settings"].testExistanceAndTap()
            app.navigationBars["Settings"].buttons["Cancel"].testExistanceAndTap()
            
            app.buttons["Chat with all resources"].testExistanceAndTap()
            
            app.buttons["Reset Chat"].testExistanceAndTap()
            
            XCTAssertTrue(app.buttons["Dismiss"].waitForExistence(timeout: 300))
            
            for question in questions {
                app.textViews["Message"].testExistanceAndTap()
                app.typeText(question)
                app.buttons["Send Message"].testExistanceAndTap()
                
                try await Task.sleep(for: .seconds(2))
                
                XCTAssertTrue(app.buttons["Dismiss"].waitForExistence(timeout: 300))
            }
            
            app.buttons["Dismiss"].testExistanceAndTap()
            
            try await Task.sleep(for: .seconds(2))
        }
    }
}


extension XCUIElement {
    func testExistanceAndTap(timeout: Double = 2) {
        XCTAssertTrue(waitForExistence(timeout: timeout))
        tap()
    }
}
