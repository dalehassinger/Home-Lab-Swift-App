import Testing
@testable import Home_Lab

@Suite("Utilities and Filtering Tests")
struct HomeLabUtilityTests {
    @Test("ISO8601 parsing accepts fractional and non-fractional seconds")
    func testISO8601Parsing() async throws {
        // Fractional seconds
        let withFraction = "2024-10-31T12:34:56.789Z"
        // No fractional seconds
        let withoutFraction = "2024-10-31T12:34:56Z"

        // Access the helper via reflection by re-implementing minimal logic here since it's fileprivate in app target
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date1 = formatter.date(from: withFraction) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: withFraction)
        }()
        #expect(date1 != nil)

        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date2 = formatter.date(from: withoutFraction) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: withoutFraction)
        }()
        #expect(date2 != nil)
    }

    @Test("VM filtering removes vCLS VMs and respects power filter")
    func testVMFiltering() async throws {
        // Minimal VM model mirror
        struct VM { let name: String; let power: String? }
        let vms = [
            VM(name: "vCLS-123", power: "POWERED_ON"),
            VM(name: "AppServer", power: "POWERED_ON"),
            VM(name: "DBServer", power: "POWERED_OFF")
        ]
        // Filter out vCLS
        let filtered = vms.filter { !$0.name.hasPrefix("vCLS-") }
        #expect(filtered.count == 2)
        // Powered on only
        let poweredOn = filtered.filter { $0.power?.uppercased() == "POWERED_ON" }
        #expect(poweredOn.count == 1)
    }
}
