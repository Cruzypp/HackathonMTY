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

/// Design tokens (Paleta Capital One - Inversión: Fondo Blanco)
enum SwiftFinColor {
    // Fondos - Invertidos a blanco/claro
    static let bgPrimary       = Color(hex: "#F5F5F7")      // Fondo blanco/gris muy claro
    static let surface         = Color(hex: "#001F3F")      // Capital One Navy para cards
    static let surfaceAlt      = Color(hex: "#003D66")      // Capital One Blue (cards alt)
    
    // Text Colors (para fondos blancos)
    static let textPrimary     = Color(hex: "#1F2937")      // Texto oscuro principal
    static let textSecondary   = Color(hex: "#6B7280")      // Texto oscuro secundario
    
    // Text Colors (para cards azules oscuras)
    static let textDark        = Color(hex: "#FFFFFF")      // Blanco para cards
    static let textDarkSecondary = Color(hex: "#B0C4D4")    // Gris claro para cards
    
    // Accent Colors - Capital One Palette
    static let accentBlue      = Color(hex: "#0099DD")      // Capital One Bright Blue
    static let capitalOneRed   = Color(hex: "#D92228")      // Capital One Red (primary brand)
    static let positiveGreen   = Color(hex: "#10B981")      // Verde más brillante y claro
    static let negativeRed     = Color(hex: "#D92228")      // Capital One Red
    
    // Dividers and Borders
    static let divider         = Color(hex: "#E5E7EB")      // Gris claro para fondos blancos
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
            ContentView()
                .environmentObject(ledger)
                .environmentObject(monthSelector)
        }
    }
}

// Top-level tab enum
enum TopTab: String, CaseIterable { case overview = "Overview", expenses = "Expenses", income = "Income" }


