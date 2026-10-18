import Foundation

/// Keeps the latest failure across restarts. Never persists localized error text,
/// URLs, file paths or arbitrary userInfo from Sparkle / the operating system.
final class UpdateDiagnostics {
    static let shared = UpdateDiagnostics(defaults: .standard)
    private let defaults: UserDefaults
    private let key = "lastUpdateFailure.v1"
    private static let domains: Set<String> = [
        "SUSparkleErrorDomain", NSCocoaErrorDomain, NSPOSIXErrorDomain,
        NSURLErrorDomain, NSOSStatusErrorDomain
    ]

    private struct ErrorCode: Codable {
        let domain: String
        let code: Int
    }

    private struct Failure: Codable {
        let date: Date
        let sourceVersion: String
        let targetVersion: String
        let errors: [ErrorCode]
    }

    init(defaults: UserDefaults) { self.defaults = defaults }

    func record(error: Error, sourceVersion: String, targetVersion: String?, date: Date = Date()) {
        var errors: [ErrorCode] = []
        var current: NSError? = error as NSError
        while let item = current, errors.count < 8 {
            errors.append(ErrorCode(domain: Self.safeDomain(item.domain), code: item.code))
            current = item.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        let failure = Failure(date: date, sourceVersion: DiagnosticEnvironment.version(sourceVersion),
                              targetVersion: DiagnosticEnvironment.version(targetVersion ?? "unknown"), errors: errors)
        if let data = try? JSONEncoder().encode(failure) { defaults.set(data, forKey: key) }
    }

    func summary() -> String {
        let heading = "\n\n## Last update failure\n"
        guard let data = defaults.data(forKey: key), data.count <= 8192,
              let failure = try? JSONDecoder().decode(Failure.self, from: data),
              failure.date.timeIntervalSince1970.isFinite else {
            return heading + "No recorded update failure. History starts with this version."
        }
        let codes = failure.errors.prefix(8).map { "\(Self.safeDomain($0.domain)):\($0.code)" }.joined(separator: " → ")
        return heading + "- date: \(ISO8601DateFormatter().string(from: failure.date))\n"
            + "- versions: \(DiagnosticEnvironment.version(failure.sourceVersion)) → \(DiagnosticEnvironment.version(failure.targetVersion))\n"
            + "- error-chain: \(codes)\n"
            + "This is the last recorded failure, not the current update status. Error descriptions and private paths are omitted."
    }

    private static func safeDomain(_ domain: String) -> String {
        domains.contains(domain) ? domain : "other"
    }
}
