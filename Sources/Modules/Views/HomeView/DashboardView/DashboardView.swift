//
//  DashboardView.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import SwiftUI

// Dashboard View
struct DashboardView: View {
    let totalBalance: String
    let rateOfReturn: String
    
    let lifetimeSpendings: String
    let lastMonthSpendings: String
    
    let lifetimeEarnings: String
    let lastMonthEarnings: String
    
    @State private var showLifetimeSpendings = true
    @State private var showLifetimeEarnings = true
    
    @State private var showRateOfReturnInfo = false
    let itemsWithoutPurchasePrice: Int // Add this property
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                DashboardCard(
                    title: "Total Balance",
                    value: totalBalance,
                    valueColor: .primary,
                    isInteractive: false
                )
                
                DashboardCard(
                    title: "Rate of Return",
                    value: rateOfReturn,
                    valueColor: rateOfReturn.contains("-") ? .red : .green,
                    isInteractive: false,
                    showInfoIcon: true,
                    infoAction: {
                        showRateOfReturnInfo = true
                    }
                )
                
                if UIDevice.isiPhoneSE {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLifetimeSpendings.toggle()
                        }
                    }) {
                        DashboardCard(
                            title: showLifetimeSpendings ? "Lifetime Spendings" : "Last Month",
                            value: showLifetimeSpendings ? lifetimeSpendings : lastMonthSpendings,
                            valueColor: .primary,
                            isInteractive: true,
                            isToggled: !showLifetimeSpendings
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            if !UIDevice.isiPhoneSE {
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLifetimeEarnings.toggle()
                        }
                    }) {
                        DashboardCard(
                            title: showLifetimeEarnings ? "Lifetime Earnings" : "Last Month",
                            value: showLifetimeEarnings ? lifetimeEarnings : lastMonthEarnings,
                            valueColor: .primary,
                            isInteractive: true,
                            isToggled: !showLifetimeEarnings
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLifetimeSpendings.toggle()
                        }
                    }) {
                        DashboardCard(
                            title: showLifetimeSpendings ? "Lifetime Spendings" : "Last Month",
                            value: showLifetimeSpendings ? lifetimeSpendings : lastMonthSpendings,
                            valueColor: .primary,
                            isInteractive: true,
                            isToggled: !showLifetimeSpendings
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .frame(maxHeight: 160)
        .popover(isPresented: $showRateOfReturnInfo) {
            RateOfReturnInfoView(itemsWithoutPurchasePrice: itemsWithoutPurchasePrice)
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let valueColor: Color
    var isInteractive: Bool = false
    var isToggled: Bool = false
    var showInfoIcon: Bool = false // Add this
    var infoAction: (() -> Void)? = nil // Add this
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    if showInfoIcon {
                        Button(action: {
                            infoAction?()
                        }) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.appPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(valueColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.8)
            }
            
            if isInteractive {
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .rotationEffect(.degrees(isToggled ? 180 : 0))
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isToggled)
            }
        }
        .padding(UIDevice.isiPhoneSE ? 12 : 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isInteractive ? Color.appPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isToggled ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isToggled)
    }
}

struct RateOfReturnInfoView: View {
    let itemsWithoutPurchasePrice: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How Rate of Return is Calculated")
                .font(.headline)
            
            Text("""
            Your Rate of Return is calculated using:
            
            • Current total market value of your collection
            • Lifetime amount spent on purchases
            • Lifetime earnings from sales
            
            Formula:
            [(Current Value + Earnings - Spent) ÷ Spent] × 100%
            
            Example:
            If you spent $1,000, earned $200,
            and current value is $1,500:
            [($1,500 + $200 - $1,000) ÷ $1,000] × 100% = 70%
            """)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
            
            if itemsWithoutPurchasePrice > 0 {
                Divider()
                
                Text("Important Note")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                
                Text("\(itemsWithoutPurchasePrice) item(s) in your collection are missing purchase price data. These items are excluded from the calculation, which may affect accuracy.")
                    .font(.footnote)
            }
        }
        .padding()
        .frame(maxWidth: 300)
    }
}
