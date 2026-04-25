import Foundation

enum BuildInfo {
    static var versionString: String {
        let dict = Bundle.main.infoDictionary ?? [:]
        let marketing = (dict["CFBundleShortVersionString"] as? String) ?? "0"
        #if DEBUG
        let branch = (dict["GitBranch"] as? String) ?? ""
        let sha = (dict["GitShortSHA"] as? String) ?? ""
        let leaf = sanitizedLeaf(of: branch)
        guard !leaf.isEmpty, !sha.isEmpty else { return marketing }
        return "\(semverPad(marketing))-\(leaf)+\(sha)"
        #else
        return marketing
        #endif
    }

    private static func semverPad(_ v: String) -> String {
        var parts = v.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        while parts.count < 3 { parts.append("0") }
        return parts.prefix(3).joined(separator: ".")
    }

    private static func sanitizedLeaf(of branch: String) -> String {
        let last = branch.split(separator: "/").last.map(String.init) ?? branch
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-"))
        let scalars = last.lowercased().unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        return String(scalars)
    }
}
