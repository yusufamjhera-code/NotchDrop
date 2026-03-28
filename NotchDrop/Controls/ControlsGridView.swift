// ControlsGridView.swift
// Grid of system control toggles

import SwiftUI

struct ControlsGridView: View {
    var body: some View {
        HStack(spacing: 12) {
            WiFiToggle()
            BluetoothToggle()
            DNDToggle()
            AirDropToggle()
            DarkModeToggle()
        }
    }
}
