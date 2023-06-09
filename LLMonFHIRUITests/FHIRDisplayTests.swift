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
        app.launchArguments = ["--skipOnboarding", "--testMode"]
        app.deleteAndLaunch(withSpringboardAppName: "LLMonFHIR")
    }

    func testFHIRResourcesView() throws {
        let app = XCUIApplication()

        let mockResource = app.otherElements.buttons["Mock Resource"]
        XCTAssertTrue(mockResource.exists, "The 'Mock Resource' does not exist.")

        mockResource.tap()
        sleep(2)
        let newScreenMockResourceText = app.staticTexts["Mock Resource"]
        XCTAssertTrue(newScreenMockResourceText.exists, "The 'Mock Resource' text does not exist on the new screen.")
    }
}
