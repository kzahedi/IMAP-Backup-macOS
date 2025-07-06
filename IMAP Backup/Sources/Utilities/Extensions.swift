import Foundation
import SwiftUI

// MARK: - Color Extensions
extension Color {
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "red":
            self = .red
        case "blue":
            self = .blue
        case "green":
            self = .green
        case "orange":
            self = .orange
        case "purple":
            self = .purple
        case "pink":
            self = .pink
        case "yellow":
            self = .yellow
        case "cyan":
            self = .cyan
        case "mint":
            self = .mint
        case "teal":
            self = .teal
        case "indigo":
            self = .indigo
        default:
            self = .gray
        }
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        } else {
            return String(self.prefix(length)) + trailing
        }
    }
    
    /// Sanitizes a string for use as a filename by replacing problematic characters
    func sanitizedForFilename() -> String {
        // Character replacement map for filesystem safety (matching Go implementation)
        let replacements: [Character: String] = [
            "/": "_",
            "\\": "_",
            ":": "_",
            "*": "_",
            "?": "_",
            "\"": "_",
            "<": "_",
            ">": "_",
            "|": "_",
            " ": "_",
            ".": "_",
            "\t": "_",
            "\n": "_",
            "\r": "_"
        ]
        
        var sanitized = ""
        for char in self {
            if let replacement = replacements[char] {
                sanitized += replacement
            } else if char.isASCII && !char.isWhitespace {
                sanitized += String(char)
            } else {
                sanitized += "_"
            }
        }
        
        // Trim underscores from start and end
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        
        // Limit length for filesystem compatibility
        if sanitized.count > 50 {
            sanitized = String(sanitized.prefix(50))
        }
        
        // Ensure we have something if everything was filtered out
        if sanitized.isEmpty {
            sanitized = "Unknown"
        }
        
        return sanitized
    }
    
    /// Extracts sender name from email address like "Name <email@domain.com>" or "email@domain.com"
    func extractSenderName() -> String {
        // Try to extract name from "Name <email@domain.com>" format using simple string operations
        if let angleIndex = self.firstIndex(of: "<") {
            let name = String(self[..<angleIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                return name.sanitizedForFilename()
            }
        }
        
        // Fall back to email address local part
        if let atIndex = self.firstIndex(of: "@") {
            let localPart = String(self[..<atIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !localPart.isEmpty {
                return localPart.sanitizedForFilename()
            }
        }
        
        // If all else fails, sanitize the whole string
        let sanitized = self.trimmingCharacters(in: .whitespacesAndNewlines).sanitizedForFilename()
        return sanitized.isEmpty ? "Unknown" : sanitized
    }
}

// MARK: - URL Extensions
extension URL {
    var sizeOnDisk: Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        return size
    }
    
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}

// MARK: - Date Extensions
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    func timeAgoDisplay() -> String {
        if isToday {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: self))"
        } else if isYesterday {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday at \(formatter.string(from: self))"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: self)
        }
    }
    
    func formattedFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH_mm_ss"
        return formatter.string(from: self)
    }
}

// MARK: - Task Extensions
extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

// MARK: - View Extensions
extension View {
    func conditionalModifier<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
    
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder()
                .opacity(shouldShow ? 1 : 0)
            self
        }
    }
}