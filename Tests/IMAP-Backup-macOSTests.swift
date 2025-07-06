import XCTest
@testable import IMAP_Backup_macOS

final class IMAPBackupTests: XCTestCase {
    
    func testAccountCreation() throws {
        let account = Account(
            name: "Test Account",
            host: "imap.example.com",
            username: "test@example.com"
        )
        
        XCTAssertEqual(account.name, "Test Account")
        XCTAssertEqual(account.host, "imap.example.com")
        XCTAssertEqual(account.username, "test@example.com")
        XCTAssertEqual(account.port, 993)
        XCTAssertTrue(account.useSSL)
        XCTAssertTrue(account.isEnabled)
    }
    
    func testEmailValidation() throws {
        XCTAssertTrue("test@example.com".isValidEmail)
        XCTAssertTrue("user.name+tag@domain.co.uk".isValidEmail)
        XCTAssertFalse("invalid-email".isValidEmail)
        XCTAssertFalse("@example.com".isValidEmail)
        XCTAssertFalse("test@".isValidEmail)
    }
    
    func testProviderDetection() throws {
        let gmailAccount = Account(
            name: "Gmail",
            host: "imap.gmail.com",
            username: "test@gmail.com"
        )
        
        XCTAssertEqual(gmailAccount.providerIcon, "envelope.fill")
        XCTAssertEqual(gmailAccount.providerColor, "red")
        
        let outlookAccount = Account(
            name: "Outlook",
            host: "outlook.office365.com",
            username: "test@outlook.com"
        )
        
        XCTAssertEqual(outlookAccount.providerIcon, "envelope.circle.fill")
        XCTAssertEqual(outlookAccount.providerColor, "blue")
    }
}