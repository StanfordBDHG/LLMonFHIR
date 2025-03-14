//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

@testable import LLMonFHIR
import Testing


@Suite("FHIRResourceSummary.Summary Initializer Tests")
struct FHIRResourceSummaryTests {
    @Test("Summary initializer with one line input")
    func summaryInitializerWithOneLineInput() throws {
        let input = "This is a title"
        let summary = FHIRResourceSummary.Summary(input)

        #expect(summary?.title == "This is a title")
        #expect(summary?.summary == "This is a title")
    }

    @Test("Summary initializer with multiline input")
    func summaryInitializerWithMultilineInput() throws {
        let input = "Title\nFirst line of summary\nSecond line of summary"
        let summary = FHIRResourceSummary.Summary(input)

        #expect(summary != nil)
        #expect(summary?.title == "Title")
        #expect(summary?.summary == "First line of summary\nSecond line of summary")
    }

    @Test("Summary initializer with empty input returns nil")
    func summaryInitializerWithEmptyInput() throws {
        let input = ""
        let summary = FHIRResourceSummary.Summary(input)

        #expect(summary == nil, "Summary should be nil for empty input")
    }

    @Test("Summary initializer preserves whitespace around content")
    func summaryInitializerWithWhitespaceAroundContent() throws {
        let input = "  Title with whitespace  \n  Summary with whitespace  "
        let summary = FHIRResourceSummary.Summary(input)

        #expect(summary?.title == "  Title with whitespace  ")
        #expect(summary?.summary == "  Summary with whitespace  ")
    }

    @Test("Summary conforms to LosslessStringConvertible")
    func summaryStringConversion() throws {
        let title = "Test Title"
        let summaryText = "This is a test summary"
        let input = "\(title)\n\(summaryText)"
        let summary = FHIRResourceSummary.Summary(input)

        #expect(summary?.description == "\(title)\n\(summaryText)")
    }

    @Test("Summary correctly filters empty lines")
    func summaryEmptyLineFiltering() throws {
        let input = "Title\n\nFirst line\n\nSecond line\n\n"
        let summary = FHIRResourceSummary.Summary(input)

        #expect(summary?.title == "Title")
        #expect(summary?.summary == "First line\nSecond line")
    }
}
