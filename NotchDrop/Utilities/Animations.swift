// Animations.swift
// Custom animation configurations

import SwiftUI

struct NotchAnimations {
    static func expandAnimation() -> Animation {
        .spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)
    }
    
    static func collapseAnimation() -> Animation {
        .spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)
    }
    
    static func fadeInAnimation(delay: Double = 0) -> Animation {
        .easeOut(duration: 0.25).delay(delay)
    }
    
    static func scaleAnimation() -> Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
}

// View modifier for staggered widget animations
struct StaggeredAppearance: ViewModifier {
    let index: Int
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8)
                    .delay(Double(index) * 0.05),
                value: isVisible
            )
    }
}

extension View {
    func staggeredAppearance(index: Int, isVisible: Bool) -> some View {
        modifier(StaggeredAppearance(index: index, isVisible: isVisible))
    }
}

// Hover effect modifier
struct HoverEffect: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverEffect() -> some View {
        modifier(HoverEffect())
    }
}
