import SwiftUI

/// One line in the shop's books. Amounts are signed — sales positive,
/// wages and buys negative — so the Ledger can total a day at a glance.
struct LedgerEntry: Identifiable, Codable {
    var id = UUID()
    var day: Int
    var detail: String
    var amount: Int

    enum Kind: String, Codable {
        case sale, wages, purchase, upgrade
    }
    var kind: Kind

    var color: Color {
        amount >= 0 ? Theme.green : Theme.red
    }

    var amountText: String {
        amount >= 0 ? "+$\(amount)" : "-$\(abs(amount))"
    }
}
