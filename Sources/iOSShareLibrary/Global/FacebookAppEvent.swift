//
//  FacebookAppEvent.swift
//  
//
//  Created by Order Tiger on 7/18/22.
//

import Foundation
import FacebookCore
import UICompanent

enum FacebookAppEventKey: String {
    case addToCart = "fb_mobile_add_to_cart"
    case initCheckout = "fb_mobile_initiated_checkout"
    case purchase = "fb_mobile_purchase"
    case addPaymentInfo = "fb_mobile_add_payment_info"
    case completeRegister = "fb_mobile_complete_registration"
}

public class FacebookAppEvent {
    public static var shared: FacebookAppEvent = .init()
    private init() { }
    
    public func addToCart(itemId: Int, currency: String = EKCurrency.code, subTotal: Double) {
        let subRouned = subTotal.roundedDecimal(to: 2, mode: .up)
        AppEvents.logEvent(.addToCart, valueToSum: subRouned, parameters: [.content: "Add to cart",
                                                                          .contentType: "product",
                                                                          .currency: currency,
                                                                          .contentID: itemId])
    }
    
    public func initCheckout(itemIds: [Int], currency: String = EKCurrency.code, itemNums: Int, subTotal: Double) {
        let stringIds = itemIds.map(String.init).joined(separator: ",")
        AppEvents.logEvent(.initCheckout, valueToSum: subTotal, parameters: [.content: "Initiate checkout",
                                                                             .contentType: "customerOrder",
                                                                             .currency: currency,
                                                                             .contentID: stringIds,
                                                                             .numItems: itemNums,
                                                                             .paymentInfoAvailable: 1])
    }
    
    public func purchase(orderId: Int, currency: String = EKCurrency.code, subTotal: Double) {
        AppEvents.logEvent(.purchase, valueToSum: subTotal, parameters: [.orderID: orderId,
                                                                         .currency: currency])
    }
    
    public func addPaymentInfo(isSuccess: Bool) {
        AppEvents.logEvent(.addPaymentInfo, parameters: [.success: isSuccess])
    }
    
    public func completeRegister(currency: String = EKCurrency.code) {
        AppEvents.logEvent(.completeRegister, parameters: [.registrationMethod: "system",
                                                           .currency: currency])
    }
    
}

extension AppEvents {
    static func logEvent(_ event: FacebookAppEventKey, valueToSum: Double = 0, parameters: [ParameterName: Any]? = nil) {
        if valueToSum == 0 {
            AppEvents.shared.logEvent(AppEvents.Name(event.rawValue), parameters: parameters)
        } else {
            AppEvents.shared.logEvent(AppEvents.Name(event.rawValue), valueToSum: valueToSum, parameters: parameters)
        }
    }
}
