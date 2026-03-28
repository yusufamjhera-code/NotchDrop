// BluetoothToggle.swift
// Bluetooth toggle control

import SwiftUI
import IOBluetooth

// Private C functions from IOBluetooth framework
@_silgen_name("IOBluetoothPreferenceGetControllerPowerState")
func IOBluetoothPreferenceGetControllerPowerState() -> CInt

@_silgen_name("IOBluetoothPreferenceSetControllerPowerState")
func IOBluetoothPreferenceSetControllerPowerState(_ state: CInt)

struct BluetoothToggle: View {
    @State private var isEnabled = true
    
    var body: some View {
        ControlButton(
            icon: "antenna.radiowaves.left.and.right",
            label: "Bluetooth",
            isActive: isEnabled,
            action: toggleBluetooth
        )
        .onAppear {
            checkBluetoothStatus()
        }
    }
    
    private func checkBluetoothStatus() {
        isEnabled = IOBluetoothPreferenceGetControllerPowerState() == 1
    }
    
    private func toggleBluetooth() {
        let newState: CInt = isEnabled ? 0 : 1
        IOBluetoothPreferenceSetControllerPowerState(newState)
        isEnabled.toggle()
    }
}
