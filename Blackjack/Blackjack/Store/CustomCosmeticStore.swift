import UIKit

/// Holds one user-uploaded photo per cosmetic category, used when that
/// category's equipped cosmetic is its "Custom Photo" slot. Images are
/// saved to local disk (not the iCloud key-value store the rest of the
/// bankroll/cosmetics state uses) since a photo is far too large for that
/// store's per-key size limit.
final class CustomCosmeticStore: ObservableObject {
    static let shared = CustomCosmeticStore()

    /// The catalog id of the "upload your own" slot for a given category.
    static func customID(for kind: CosmeticKind) -> String { "custom.\(kind.rawValue)" }

    @Published private var cache: [CosmeticKind: UIImage] = [:]

    private init() {}

    private func fileURL(for kind: CosmeticKind) -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom_\(kind.rawValue).jpg")
    }

    func hasImage(for kind: CosmeticKind) -> Bool {
        if cache[kind] != nil { return true }
        return FileManager.default.fileExists(atPath: fileURL(for: kind).path)
    }

    func image(for kind: CosmeticKind) -> UIImage? {
        if let cached = cache[kind] { return cached }
        guard let data = try? Data(contentsOf: fileURL(for: kind)), let image = UIImage(data: data) else { return nil }
        cache[kind] = image
        return image
    }

    func setImage(_ image: UIImage, for kind: CosmeticKind) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL(for: kind))
        cache[kind] = image
        objectWillChange.send()
    }
}
