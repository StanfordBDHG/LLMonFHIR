//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

@testable import LLMonFHIRShared
import Testing


@Suite
struct FHIRResourceSummaryTests {
    @Test
    func summaryInitializerWithOneLineInput() throws {
        let input = "This is a title"
        let summary = FHIRResourceSummary.Summary(input)
        #expect(summary?.title == "This is a title")
        #expect(summary?.summary == "This is a title")
    }
    
    @Test
    func summaryInitializerWithMultilineInput() throws {
        let input = "Title\nFirst line of summary\nSecond line of summary"
        let summary = FHIRResourceSummary.Summary(input)
        #expect(summary != nil)
        #expect(summary?.title == "Title")
        #expect(summary?.summary == "First line of summary\nSecond line of summary")
    }
    
    @Test
    func summaryInitializerWithEmptyInput() throws {
        let input = ""
        let summary = FHIRResourceSummary.Summary(input)
        #expect(summary == nil, "Summary should be nil for empty input")
    }
    
    @Test
    func summaryInitializerWithWhitespaceAroundContent() throws {
        let input = "  Title with whitespace  \n  Summary with whitespace  "
        let summary = FHIRResourceSummary.Summary(input)
        #expect(summary?.title == "  Title with whitespace  ")
        #expect(summary?.summary == "  Summary with whitespace  ")
    }
    
    @Test
    func summaryStringConversion() throws {
        let title = "Test Title"
        let summaryText = "This is a test summary"
        let input = "\(title)\n\(summaryText)"
        let summary = FHIRResourceSummary.Summary(input)

        #expect(summary?.description == "\(title)\n\(summaryText)")
    }
    
    @Test
    func summaryEmptyLineFiltering() throws {
        let input = "Title\n\nFirst line\n\nSecond line\n\n"
        let summary = FHIRResourceSummary.Summary(input)
        #expect(summary?.title == "Title")
        #expect(summary?.summary == "First line\nSecond line")
    }
}
