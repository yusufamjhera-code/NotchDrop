// SystemMonitor.swift
// Monitors CPU and RAM usage

import Foundation
import Combine

class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()
    
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var memoryUsed: Double = 0.0
    @Published var memoryTotal: Double = 0.0
    
    private var timer: Timer?
    private var previousCPUInfo: host_cpu_load_info?
    
    private init() {
        updateStats()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    private func updateStats() {
        updateCPUUsage()
        updateMemoryUsage()
    }
    
    private func updateCPUUsage() {
        var cpuInfo: host_cpu_load_info?
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS, let info = cpuInfo else { return }
        
        let userTicks = Double(info.cpu_ticks.0)
        let systemTicks = Double(info.cpu_ticks.1)
        let idleTicks = Double(info.cpu_ticks.2)
        let niceTicks = Double(info.cpu_ticks.3)
        
        if let previous = previousCPUInfo {
            let prevUser = Double(previous.cpu_ticks.0)
            let prevSystem = Double(previous.cpu_ticks.1)
            let prevIdle = Double(previous.cpu_ticks.2)
            let prevNice = Double(previous.cpu_ticks.3)
            
            let userDiff = userTicks - prevUser
            let systemDiff = systemTicks - prevSystem
            let idleDiff = idleTicks - prevIdle
            let niceDiff = niceTicks - prevNice
            
            let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
            let usedTicks = userDiff + systemDiff + niceDiff
            
            if totalTicks > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.cpuUsage = (usedTicks / totalTicks) * 100
                }
            }
        }
        
        previousCPUInfo = info
    }
    
    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = Double(vm_kernel_page_size)
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        
        let activeMemory = Double(stats.active_count) * pageSize
        let wiredMemory = Double(stats.wire_count) * pageSize
        let compressedMemory = Double(stats.compressor_page_count) * pageSize
        
        let usedMemory = activeMemory + wiredMemory + compressedMemory
        
        DispatchQueue.main.async { [weak self] in
            self?.memoryUsed = usedMemory / (1024 * 1024 * 1024)  // GB
            self?.memoryTotal = totalMemory / (1024 * 1024 * 1024)  // GB
            self?.memoryUsage = (usedMemory / totalMemory) * 100
        }
    }
}
