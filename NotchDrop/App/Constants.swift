// Constants.swift
// App-wide constants and configuration

import Foundation
import SwiftUI

enum NotchConstants {
    static let notchWidth: CGFloat = 200
    static let notchHeight: CGFloat = 45
    static let expandedWidth: CGFloat = 620
    static let expandedHeight: CGFloat = 160
    static let expandDuration: Double = 0.3
    static let collapseDuration: Double = 0.25
    static let springResponse: Double = 0.4
    static let springDamping: Double = 0.8
    static let cornerRadius: CGFloat = 28
    static let hoverAreaHeight: CGFloat = 50
    

}

enum AppColors {
    static let background = Color.black.opacity(0.85)
    static let widgetBackground = Color.white.opacity(0.1)
    static let accent = Color.blue
    static let text = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let controlActive = Color.blue
    static let controlInactive = Color.gray.opacity(0.5)
}

enum AppFonts {
    static let widgetTitle = Font.system(size: 11, weight: .medium)
    static let widgetValue = Font.system(size: 16, weight: .semibold)
    static let controlLabel = Font.system(size: 10, weight: .medium)
    static let time = Font.system(size: 48, weight: .light, design: .rounded)
    static let date = Font.system(size: 14, weight: .medium)
}
