//
//  Extensions.swift
//  ECashKit-Example
//
//  Created by Sun on 2024/8/21.
//

import Foundation

extension Decimal {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 8
        formatter.maximumFractionDigits = 8
        return formatter.string(from: self as NSDecimalNumber)!
    }
}
