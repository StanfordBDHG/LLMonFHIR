//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

private import Foundation
public import class ModelsR4.Bundle
public import class ModelsR4.Patient
private import OSLog


extension ModelsR4.Bundle {
    private static let lookup = ResourceBundlesLookup(
        rootUrl: Foundation.Bundle.llmOnFhirShared.url(forResource: "Synthetic Patients", withExtension: nil)
    )
    
    /// The names of all synthetic patients that were found in FHIR bundles in the `Synthetic Patients` folder.
    public static var allSyntheticPatientNames: Set<String> {
        Set(lookup.bundlesByPatientName.keys)
    }
    
    /// Fetches the bundle with the specified filename.
    ///
    /// - parameter bundleFilename: A filename/path relative to the `Synthetic Patients` folder.
    public static func named(_ bundleFilename: String) -> ModelsR4.Bundle? {
        lookup.bundlesByPath[bundleFilename].flatMap { url in
            try? JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(contentsOf: url))
        }
    }
    
    /// Fetches the bundle with the specified patient name.
    ///
    /// - parameter patientName: The name of the desired bundle's patient.
    public static func forPatient(named patientName: String) -> ModelsR4.Bundle? {
        lookup.bundlesByPatientName[patientName].flatMap { url in
            try? JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(contentsOf: url))
        }
    }
}


extension ModelsR4.Bundle {
    private struct ResourceBundlesLookup: Sendable {
        private static let logger = Logger(subsystem: "edu.stanford.LLMonFHIR.LLMonFHIRShared", category: "\(Self.self)")
        
        private(set) var bundlesByPath: [String: URL] = [:]
        private(set) var bundlesByPatientName: [String: URL] = [:]
        
        init(rootUrl: URL?) {
            guard let rootUrl, FileManager.default.isDirectory(at: rootUrl) else {
                return
            }
            guard let enumerator = FileManager.default.enumerator(
                at: rootUrl,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                return
            }
            var allBundlesByPatientName: [String: [URL]] = [:]
            for url in enumerator.lazy.compactMap({ $0 as? URL }) {
                guard (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else {
                    continue
                }
                let bundle: ModelsR4.Bundle
                do {
                    bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(contentsOf: url))
                } catch {
                    Self.logger.warning("Skipping FHIR bundle at \(url.path) (unable to decode): \(error)")
                    continue
                }
                if let patientName = bundle.singlePatient?.fullName {
                    defer {
                        allBundlesByPatientName[patientName, default: []].append(url)
                    }
                    guard !allBundlesByPatientName.keys.contains(patientName) else {
                        bundlesByPatientName[patientName] = nil
                        break
                    }
                    bundlesByPatientName[patientName] = url
                }
                if let bundleFilePathId = url.deletingPathExtension().partialPath(relativeTo: rootUrl) { // should always be nonnil
                    bundlesByPath[bundleFilePathId] = url
                }
            }
            for (name, urls) in allBundlesByPatientName where urls.count > 1 {
                Self.logger.warning("Found multiple FHIR bundles with same patient name '\(name)':\n\(urls.map { "- \($0.path)" }.joined(separator: "\n"))")
            }
        }
    }
}


extension ModelsR4.Bundle {
    /// The bundle's single patient, if present.
    ///
    /// If the bundle contains multiple patients, `nil` is returned.
    public var singlePatient: ModelsR4.Patient? {
        guard let patients = entry?.compactMap({ $0.resource?.get(if: ModelsR4.Patient.self) }), patients.count == 1 else {
            return nil
        }
        return patients.first
    }
}


extension ModelsR4.Patient {
    /// The full name of the patient.
    public var fullName: String? {
        for name in name ?? [] {
            let familyName = name.family?.value?.string ?? ""
            let givenNames = (name.given?.compactMap { $0.value?.string } ?? []).filter { !$0.isEmpty }
            switch (givenNames.isEmpty, familyName.isEmpty) {
            case (true, true): // we have nothing
                continue
            case (true, false): // we have given names, but no family name
                return givenNames.joined(separator: " ")
            case (false, true): // family name yes given names no
                return familyName
            case (false, false):
                return "\(givenNames.joined(separator: " ")) \(familyName)"
            }
        }
        return nil
    }
}


extension URL {
    /// Forms a path relative to a base url
    ///
    /// Example: `/a/b/c/d/e/f/g.h` relative to base `/a/b/c/` would be `d/e/f/g.h`
    ///
    /// - Note: this assumes that the url is a file url
    fileprivate func partialPath(relativeTo baseUrl: URL) -> String? {
        let ownComponents = self.resolvingSymlinksInPath().absoluteURL.pathComponents
        let baseComponents = baseUrl.resolvingSymlinksInPath().absoluteURL.pathComponents
        guard ownComponents.count >= baseComponents.count, // if the base is longer than the current uwl, it cannot be the same
              ownComponents[0..<baseComponents.count] == baseComponents[...] else {
            return nil
        }
        return ownComponents[baseComponents.count...].joined(separator: "/")
    }
}
