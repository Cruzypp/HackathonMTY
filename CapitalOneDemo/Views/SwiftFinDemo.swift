//
//  SwiftFinApp_FullCode.swift
//  SwiftFin – Dark UI starter with Store, Screens, Sheets & Reports
//  Requires iOS 16+ (Charts)
//
//  Paste this single file into your Xcode project.
//
import SwiftUI
import Charts
import Combine

// MARK: - Color helpers (no necesitas crear nada extra)
extension Color {
    /// Hex like "#0B1220" or "0B1220"
    init(hex: String, alpha: Double = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b).opacity(alpha)
    }
}

/// Design tokens (paleta fría modo oscuro)
enum SwiftFinColor {
    static let bgPrimary       = Color(hex: "#0B1220")      // fondo principal
    static let surface         = Color(hex: "#0F172A")      // tarjetas
    static let surfaceAlt      = Color(hex: "#111827")
    static let textPrimary     = Color(hex: "#E5E7EB")
    static let textSecondary   = Color(hex: "#94A3B8")
    static let accentBlue      = Color(hex: "#3B82F6")
    static let positiveGreen   = Color(hex: "#22C55E")
    static let negativeRed     = Color(hex: "#EF4444")
    static let divider         = Color(hex: "#1F2937")
}

// NOTE: MonthSelector and LedgerViewModel are in `ViewModels/ViewModels.swift`
//       Models are in `Models/Models.swift` and UI views live in `Views/`.

@main
struct SwiftFinDemoApp: App {
    // State objects: create in init to control order
    @StateObject var monthSelector: MonthSelector
    @StateObject var ledger: LedgerViewModel

    init() {
        let ms = MonthSelector()
        _monthSelector = StateObject(wrappedValue: ms)
        _ledger = StateObject(wrappedValue: LedgerViewModel(monthSelector: ms))
    }

    var body: some Scene {
        WindowGroup {
            SwiftFinRoot()
                .environmentObject(ledger)
                .environmentObject(monthSelector)
                .preferredColorScheme(.dark)
        }
    }
}

// Top-level tab enum
enum TopTab: String, CaseIterable { case overview = "Overview", expenses = "Expenses", income = "Income" }


