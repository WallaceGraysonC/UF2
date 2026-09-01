import Foundation

/// The second axis of a Drop — the "topic" to the theme's "genre".
/// Theme decides the format and the crowd; Angle decides the hook, and the
/// pairing of the two is what makes a Drop land or fall flat.
enum DropAngle: String, CaseIterable, Identifiable {
    case slasher = "Slasher"
    case cultSciFi = "Cult Sci-Fi"
    case soundtracks = "Soundtracks"
    case localBands = "Local Bands"
    case oneHitWonders = "One-Hit Wonders"
    case imports = "Imports"
    case deepCuts = "Deep Cuts"
    case sealedAndGraded = "Sealed & Graded"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .slasher: return "Masks, final girls, video nasties."
        case .cultSciFi: return "The weird ones with the airbrushed covers."
        case .soundtracks: return "Score and OST, cross-format."
        case .localBands: return "Anything recorded within thirty miles."
        case .oneHitWonders: return "You know exactly one song. It's enough."
        case .imports: return "Region-locked, obi strips, foreign pressings."
        case .deepCuts: return "Nothing anybody came in asking for."
        case .sealedAndGraded: return "Shrink intact. Do not open."
        }
    }
}
