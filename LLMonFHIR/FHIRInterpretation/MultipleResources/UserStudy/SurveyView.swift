//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


// MARK: - Answer State Management

/// Manages the state of answers for different types of survey questions
@MainActor
final class SurveyAnswerState: ObservableObject {
    /// Stores answers for Likert scale questions, keyed by question index
    @Published private(set) var likertScaleAnswers: [Int: Int] = [:]

    /// Stores answers for free text questions, keyed by question index
    @Published private(set) var freeTextAnswers: [Int: String] = [:]

    /// Stores the answer for Net Promoter Score question
    @Published private(set) var npsAnswer: Int?

    /// Retrieves all answers for a set of questions in their proper format
    /// - Parameter questions: The questions to get answers for
    /// - Returns: An array of answers matching the questions array
    func getAnswers(for questions: [Question]) -> [Answer] {
        questions.enumerated().map { index, question in
            switch question.type {
            case .likertScale:
                return likertScaleAnswers[index].map { .likertScale($0) } ?? .unanswered
            case .freeText:
                return freeTextAnswers[index].map { .freeText($0) } ?? .unanswered
            case .netPromoterScore:
                return npsAnswer.map { .netPromoterScore($0) } ?? .unanswered
            }
        }
    }

    /// Checks if a question has been answered correctly
    /// - Parameters:
    ///   - questionIndex: The index of the question
    ///   - type: The type of the question
    ///   - isOptional: Whether the question can be skipped
    /// - Returns: True if the question has been answered appropriately
    func isAnswered(questionIndex: Int, type: QuestionType, isOptional: Bool) -> Bool {
        if isOptional {
            return true
        }

        switch type {
        case .likertScale:
            return likertScaleAnswers[questionIndex] != nil
        case .freeText:
            return freeTextAnswers[questionIndex]?.isEmpty == false
        case .netPromoterScore:
            return npsAnswer != nil
        }
    }

    /// Updates the answer for a Likert scale question
    /// - Parameters:
    ///   - value: The selected value
    ///   - index: The question index
    func updateLikertScale(value: Int, at index: Int) {
        likertScaleAnswers[index] = value
    }

    /// Updates the answer for a free text question
    /// - Parameters:
    ///   - text: The entered text
    ///   - index: The question index
    func updateFreeText(_ text: String, at index: Int) {
        freeTextAnswers[index] = text
    }

    /// Updates the answer for the NPS question
    /// - Parameter value: The selected NPS value
    func updateNPS(_ value: Int) {
        npsAnswer = value
    }
}


// MARK: - Question Section View

/// A view that displays a single question and its corresponding input method
struct QuestionSectionView: View {
    /// The question to display
    let question: Question

    /// The index of this question in the task
    let index: Int

    /// The shared state object for managing answers
    @ObservedObject var answerState: SurveyAnswerState


    var body: some View {
        Section {
            questionContent
        } header: {
            Text(question.isOptional ? "\(question.text) (Optional)" : question.text)
                .textCase(.none)
                .font(.body)
                .fontWeight(.medium)
        }
    }


    @ViewBuilder private var questionContent: some View {
        switch question.type {
        case .likertScale(let responseOptions):
            LikertScaleQuestionView(
                index: index,
                responseOptions: responseOptions,
                answerState: answerState
            )
        case .freeText:
            FreeTextQuestionView(
                index: index,
                answerState: answerState
            )
        case .netPromoterScore(let range):
            NPSQuestionView(
                range: range,
                answerState: answerState
            )
        }
    }
}


// MARK: - Question Type Views

/// A reusable view component for displaying radio button selection options
struct RadioSelectionView: View {
    /// The range of integer values to display as selectable options
    let range: ClosedRange<Int>

    /// The currently selected value, which can be nil if nothing is selected
    let selectedValue: Int?

    /// A closure that converts an integer value to its display text
    let displayText: (Int) -> String

    /// A closure that's called when a selection is made, passing the selected integer value
    let onSelect: (Int) -> Void

    var body: some View {
        ForEach(range, id: \.self) { value in
            Button(action: { onSelect(value) }) {
                HStack {
                    Text(displayText(value))

                    Spacer()

                    Image(systemName: "circle")
                        .accessibilityHidden(true)
                        .foregroundStyle(selectedValue == value ? .accent : .secondary)
                        .overlay {
                            if selectedValue == value {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.accent)
                            }
                        }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}


/// A view for collecting Likert scale responses
struct LikertScaleQuestionView: View {
    /// The index of this question
    let index: Int

    /// The response options for this question
    let responseOptions: [String]

    /// The shared state object for managing answers
    @ObservedObject var answerState: SurveyAnswerState

    private var range: ClosedRange<Int> {
        1...responseOptions.count
    }


    var body: some View {
        RadioSelectionView(
            range: range,
            selectedValue: answerState.likertScaleAnswers[index],
            displayText: { value in
                guard value > 0 && value <= responseOptions.count else {
                    return ""
                }
                return responseOptions[value - 1]
            },
            onSelect: { value in
                answerState.updateLikertScale(value: value, at: index)
            }
        )
    }
}


/// A view for collecting free text responses
struct FreeTextQuestionView: View {
    /// The index of this question
    let index: Int

    /// The shared state object for managing answers
    @ObservedObject var answerState: SurveyAnswerState


    var body: some View {
        TextEditor(text: binding)
            .frame(height: 100)
    }


    private var binding: Binding<String> {
        Binding(
            get: { answerState.freeTextAnswers[index] ?? "" },
            set: { answerState.updateFreeText($0, at: index) }
        )
    }
}


/// A view for collecting Net Promoter Score responses
struct NPSQuestionView: View {
    /// The valid range for this NPS question
    let range: ClosedRange<Int>

    /// The shared state object for managing answers
    @ObservedObject var answerState: SurveyAnswerState


    var body: some View {
        RadioSelectionView(
            range: range,
            selectedValue: answerState.npsAnswer,
            displayText: { value in
                switch value {
                case 0: return "\(value) (Would not recommend)"
                case 10: return "\(value) (Would recommend)"
                default: return "\(value)"
                }
            },
            onSelect: { value in
                answerState.updateNPS(value)
            }
        )
    }
}


// MARK: - Main Survey View

/// The main view for displaying and collecting survey responses
struct SurveyView: View {
    /// The task containing the questions to display
    let task: SurveyTask

    /// Controls whether this view is currently displayed
    @Binding var isPresented: Bool

    /// Callback to invoke when the survey is submitted
    let onSubmit: ([Answer]) -> Void

    /// The state object managing all answers
    @StateObject private var answerState = SurveyAnswerState()


    var body: some View {
        NavigationView {
            Form {
                questionSections
                submitButtonSection
            }
            .navigationTitle("Task \(task.id)")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarItems(trailing: cancelButton)
        }
    }
    

    private var questionSections: some View {
        ForEach(Array(task.questions.enumerated()), id: \.offset) { index, question in
            QuestionSectionView(
                question: question,
                index: index,
                answerState: answerState
            )
        }
    }

    private var submitButtonSection: some View {
        Button(action: handleSubmit) {
            Text("Submit")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderless)
        .disabled(!areAllQuestionsAnswered)
    }

    private var cancelButton: some View {
        Button("Cancel") {
            isPresented = false
        }
    }

    private var areAllQuestionsAnswered: Bool {
        task.questions.indices.allSatisfy { index in
            let question = task.questions[index]
            return answerState.isAnswered(
                questionIndex: index,
                type: question.type,
                isOptional: question.isOptional
            )
        }
    }

    private func handleSubmit() {
        let answers = answerState.getAnswers(for: task.questions)
        onSubmit(answers)
        isPresented = false
    }
}
