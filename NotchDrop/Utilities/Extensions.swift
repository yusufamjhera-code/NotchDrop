// Extensions.swift
// Helpful extensions

import SwiftUI
import AppKit

extension View {
    func widgetStyle() -> some View {
        self
            .padding(12)
            .background(AppColors.widgetBackground)
            .cornerRadius(12)
    }
    
    func controlButtonStyle(isActive: Bool) -> some View {
        self
            .frame(width: 50, height: 50)
            .background(isActive ? AppColors.controlActive : AppColors.controlInactive)
            .cornerRadius(12)
    }
}

extension Animation {
    static var notchExpand: Animation {
        .spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)
    }
    
    static var notchCollapse: Animation {
        .spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)
    }
}
