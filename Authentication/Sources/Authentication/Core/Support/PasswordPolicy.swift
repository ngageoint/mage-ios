//
//  PasswordPolicy.swift
//  Authentication
//
//  Created by Brent Michalski on 10/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public struct PasswordPolicy {
    public struct Template {
        public let passwordHistoryCount: String?
        public let passwordMinLength: String?
        public let restrictSpecialChars: String?
        public let specialChars: String?
        public let numbers: String?
        public let highLetters: String?
        public let lowLetters: String?
        public let maxConChars: String?
        public let minChars: String?
        
        init(dict: [String: Any]) {
            passwordHistoryCount = dict["passwordHistoryCount"] as? String
            passwordMinLength = dict["passwordMinLength"] as? String
            restrictSpecialChars = dict["restrictSpecialChars"] as? String
            specialChars = dict["specialChars"] as? String
            numbers = dict["numbers"] as? String
            highLetters = dict["highLetters"] as? String
            lowLetters = dict["lowLetters"] as? String
            maxConChars = dict["maxConChars"] as? String
            minChars = dict["minChars"] as? String
        }
    }
    
    public let customHelpText: Bool
    public let helpText: String?
    public let helpTextTemplate: Template
    
    public let passwordHistoryCountEnabled: Bool
    public let passwordHistoryCount: Int
    
    public let passwordMinLengthEnabled: Bool
    public let passwordMinLength: Int
    
    public let restrictSpecialCharsEnabled: Bool
    public let restrictSpecialChars: String // ALLOWED CHARS
    
    public let specialCharsEnabled: Bool
    public let specialChars: Int
    
    public let numbersEnabled: Bool
    public let numbers: Int
    
    public let highLettersEnabled: Bool
    public let highLetters: Int
    
    public let lowLettersEnabled: Bool
    public let lowLetters: Int
    
    public let maxConCharsEnabled: Bool
    public let maxConChars: Int
    
    public let minCharsEnabled: Bool
    public let minChars: Int
    
    public init?(dict: [String: Any]) {
        // The required keys with sensible defaults
        customHelpText = dict["customHelpText"] as? Bool ?? false
        helpText = dict["helpText"] as? String
        
        helpTextTemplate = Template(dict: dict["helpTextTemplate"] as? [String: Any] ?? [:])
        
        passwordHistoryCountEnabled = dict["passwordHistoryCountEnabled"] as? Bool ?? false
        passwordHistoryCount = dict["passwordHistoryCount"] as? Int ?? 0
        
        passwordMinLengthEnabled = dict["passwordMinLengthEnabled"] as? Bool ?? false
        passwordMinLength = dict["passwordMinLength"] as? Int ?? 0
        
        restrictSpecialCharsEnabled = dict["restrictSpecialCharsEnabled"] as? Bool ?? false
        restrictSpecialChars = dict["restrictSpecialChars"] as? String ?? ""
        
        specialCharsEnabled = dict["specialCharsEnabled"] as? Bool ?? false
        specialChars = dict["specialChars"] as? Int ?? 0
        
        numbersEnabled = dict["numbersEnabled"] as? Bool ?? false
        numbers = dict["numbers"] as? Int ?? 0
        
        highLettersEnabled = dict["highLettersEnabled"] as? Bool ?? false
        highLetters = dict["highLetters"] as? Int ?? 0
        
        lowLettersEnabled = dict["lowLettersEnabled"] as? Bool ?? false
        lowLetters = dict["lowLetters"] as? Int ?? 0
        
        maxConCharsEnabled = dict["maxConCharsEnabled"] as? Bool ?? false
        maxConChars = dict["maxConChars"] as? Int ?? 0
        
        minCharsEnabled = dict["minCharsEnabled"] as? Bool ?? false
        minChars = dict["minChars"] as? Int ?? 0
    }
}

// MARK: - Validation

public extension PasswordPolicy {
    struct Result {
        public let isValid: Bool
        public let violations: [String] // User-facing messages
    }
    
    /// Validates and returns user-facing violations (strings)
    func validate(_ password: String) -> Result {
        var violations: [String] = []
        
        // Counts
        let scalars = password.unicodeScalars
        let letters = scalars.filter { CharacterSet.letters.contains($0) }
        let uppers = scalars.filter { CharacterSet.uppercaseLetters.contains($0) }
        let lowers = scalars.filter { CharacterSet.lowercaseLetters.contains($0) }
        let digits = scalars.filter { CharacterSet.decimalDigits.contains($0) }
        
        // Special characters determination
        let specialsCount: Int = {
            if restrictSpecialCharsEnabled {
                let allowed = Set(restrictSpecialChars)
                return password.filter { !($0.isLetter || $0.isNumber) && allowed.contains($0) }.count
            } else {
                return password.filter { !($0.isLetter || $0.isNumber) }.count
            }
        }()
        
        if passwordMinLengthEnabled, password.count < passwordMinLength {
            violations.append(templateString(helpTextTemplate.passwordMinLength, number: passwordMinLength) ?? "Must be at least \(passwordMinLength) characters.")
        }
        
        if numbersEnabled, digits.count < numbers {
            violations.append(templateString(helpTextTemplate.numbers, number: numbers) ?? "Must include at least \(numbers) number(s).")
        }
        
        if highLettersEnabled, uppers.count < highLetters {
            violations.append(templateString(helpTextTemplate.highLetters, number: highLetters) ?? "Must include at least \(highLetters) uppercase letter(s).")
        }
        
        if lowLettersEnabled, lowers.count < lowLetters {
            violations.append(templateString(helpTextTemplate.lowLetters, number: lowLetters) ?? "Must include at least \(lowLetters) lowercase letter(s).")
        }
        
        if minCharsEnabled, letters.count < minChars {
            violations.append(templateString(helpTextTemplate.minChars, number: minChars) ?? "Must include at least \(minChars) letter(s).")
        }
        
        if specialCharsEnabled, specialsCount < specialChars {
            violations.append(templateString(helpTextTemplate.specialChars, number: specialChars) ?? "Must include at least \(specialChars) special character(s).")
        }
        
        if restrictSpecialCharsEnabled && !restrictSpecialChars.isEmpty {
            // Check that every special char is within the allowed set
            let allowed = Set(restrictSpecialChars)
            let bad = password.first { !$0.isLetter && !$0.isNumber && !allowed.contains($0) }
            if bad != nil {
                violations.append(templateString(helpTextTemplate.restrictSpecialChars, text: restrictSpecialChars) ?? "Special characters restricted to: \(restrictSpecialChars)")
            }
        }
        
        if maxConCharsEnabled, maxConChars > 0, hasTooManyConsecutiveCharacters(password, limit: maxConChars) {
            violations.append(templateString(helpTextTemplate.maxConChars, number: maxConChars) ?? "Must not contain more than \(maxConChars) identical consecutive characters.")
        }
        
        // Server-provided single help text (optional). Show it **only if invalid** and
        // only if server wants customezed help (to avoid duplicating)
        if !violations.isEmpty, customizeHelpText, let help = helpText, !help.isEmpty {
            let unique = [help] + violations
            return Result(isValid: false, violations: unique)
        }
        
        return Result(isValid: violations.isEmpty, violations: violations)
    }
    
    // MARK: helpers
    
    private func templateString(_ tmpl: String?, number: Int) -> String? {
        guard var str = tmpl else { return nil }
        str = str.replacingOccurrences(of: "#", with: "\(number)")
        return ". " + str
    }
    
    private func templateString(_ tmpl: String?, text: String) -> String? {
        guard var str = tmpl else { return nil }
        str = str.replacingOccurrences(of: "#", with: text)
        return ". " + str
    }
    
    private func hasTooManyConsecutiveCharacters(_ s: String, limit: Int) -> Bool {
        guard limit > 0 else { return false }
        var last: Character?
        var run = 0
        
        for char in s {
            if c == last { run += 1 } else { run = 1; last = c }
            if run > limit { return true }
        }
        return false
    }
}
