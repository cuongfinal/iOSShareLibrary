//
//  EKAnalytics.swift
//
//
//  Created by Order Tiger on 11/21/21.
//

import Foundation
import FirebaseAnalytics
import Firebase
import Shake
import iOSRepositories
import SwiftyRemoteConfig
import UICompanent

enum EKAnalyticsKey: String {
    case login = "login"
    case signUp = "sign_up"
    case purchase = "purchase"
    case search = "search"
    case addPaymentInfo = "add_payment_info"
    case addShippingInfo = "add_shipping_info"
    case addToCart = "add_to_cart"
    case beginCheckout = "begin_checkout"
    case removeFromCart = "remove_from_cart"
    case viewCart = "view_cart"
    case viewItemList = "view_item_list"
    case viewItem = "view_item"
    case selectContent = "select_content"
}

public class EKAnalytics {
    public static var shared: EKAnalytics = .init()
    
    private init() { }
    
    public func setAllowAdsPersonalizationSignals() {
        if let allowAdsPersonalizationSignals = RemoteConfigs.allowAdsPersonalizationSignals {
            Analytics.setUserProperty(allowAdsPersonalizationSignals ? "true" : "false", forName: AnalyticsUserPropertyAllowAdPersonalizationSignals)
        }
    }
    
    public func analyticsCollectionEnabled(_ isEnable: Bool) {
        Analytics.setAnalyticsCollectionEnabled(isEnable)
    }
    
    public func setUserID(uid: Int) {
        if RemoteConfigs.setGAUserId {
            Analytics.setUserID(String(uid))
        }
    }
    
    public func login() {
        Analytics.logEvent(.login, parameters: [
            AnalyticsParameterMethod: "Email"
        ])
    }
    
    public func signUp() {
        Analytics.logEvent(.signUp, parameters: [
                            AnalyticsParameterMethod: "Email"
        ])
    }
    
    public func search(_ searchTerm: String) {
        Analytics.logEvent(.search, parameters: [
            AnalyticsParameterSearchTerm: searchTerm
        ])
    }
    
    public func viewCart(currency: String = EKCurrency.code, subTotal: String, items: [[String:Any]]) {
        Analytics.logEvent(.viewCart, parameters: [
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterValue: subTotal,
            AnalyticsParameterItems: items
        ])
    }
    
    public func viewItem(currency: String = EKCurrency.code, price: Double, items: [[String:Any]]) {
        Analytics.logEvent(.viewItem, parameters: [
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterValue: price,
            AnalyticsParameterItems: items
        ])
    }
    
    public func addPaymentInfo(currency: String = EKCurrency.code) {
        Analytics.logEvent(.addPaymentInfo, parameters: [
            AnalyticsParameterCurrency: currency
        ])
    }
    
    public func addShippingInfo(currency: String = EKCurrency.code) {
        Analytics.logEvent(.addShippingInfo, parameters: [
            AnalyticsParameterCurrency: currency
        ])
    }
    
    public func viewItemList(branchID: Int, branchName: String, items: [[String:Any]]) {
        Analytics.logEvent(.viewItemList, parameters: [
            AnalyticsParameterItemListID: branchID,
            AnalyticsParameterItemListName: branchName,
            AnalyticsParameterItems: items
        ])
    }
    
    public func addToCart(currency: String = EKCurrency.code, subTotal: Double, items: [[String:Any]]) {
        Analytics.logEvent(.addToCart, parameters: [
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterValue: subTotal,
            AnalyticsParameterItems: items
        ])
    }
    
    public func beginCheckout(currency: String = EKCurrency.code, subTotal: Double, items: [[String:Any]]) {
        Analytics.logEvent(.beginCheckout, parameters: [
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterValue: subTotal,
            AnalyticsParameterItems: items
        ])
    }
    
    public func removeFromCart(currency: String = EKCurrency.code, subTotal: Double, items: [[String:Any]]) {
        Analytics.logEvent(.removeFromCart, parameters: [
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterValue: subTotal,
            AnalyticsParameterItems: items
        ])
    }
    
    public func selectContentStoreListing(itemID: Int) {
        Analytics.logEvent(.selectContent, parameters: [
            AnalyticsParameterContentType: "store",
            AnalyticsParameterItemID: itemID
        ])
    }
    
    public func selectContentBusCat(itemID: Int) {
        Analytics.logEvent(.selectContent, parameters: [
            AnalyticsParameterContentType: "business_category",
            AnalyticsParameterItemID: itemID
        ])
    }
    
    public func selectContentBusSubCat(itemID: String) {
        Analytics.logEvent(.selectContent, parameters: [
            AnalyticsParameterContentType: "business_sub_category",
            AnalyticsParameterItemID: itemID
        ])
    }
    
    public func purchase(orderId: String, currency: String = EKCurrency.code,
                         subTotal: Double, promoCode: String, delCharge: Double, tax: Double, items: [[String:Any]]) {
        Analytics.logEvent(.purchase, parameters: [
            AnalyticsParameterTransactionID: orderId,
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterValue: subTotal,
            AnalyticsParameterCoupon: promoCode,
            AnalyticsParameterShipping: delCharge,
            AnalyticsParameterItems: items,
            AnalyticsParameterTax: tax
        ])
    }
}
// MARK: - Shakebugs
public extension EKAnalytics {
    func setShakeBranch(id: Int) {
        Shake.setMetadata(key: "branch_id", value: String(id))
    }
    func setShakeOrder(id: Int) {
        Shake.setMetadata(key: "order_id", value: String(id))
    }
    func setShakeTrans(id: String) {
        Shake.setMetadata(key: "trans_id", value: id)
    }
    func shakeClearMetadata() {
        Shake.clearMetadata()
    }
}

extension Analytics {
    static func logEvent(_ event: EKAnalyticsKey, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }
}

// Complited
// EKAnalytics.shared.login()
// EKAnalytics.shared.signUp()
// EKAnalytics.shared.viewCart()
// EKAnalytics.shared.beginCheckout(subTotal: 123) -
// EKAnalytics.shared.addToCart(subTotal: 123)
// EKAnalytics.shared.viewItemList(branchID: 123, branchName: "Kamalov") -
// EKAnalytics.shared.selectItem()

// To Do
// EKAnalytics.shared.addPaymentInfo()
// EKAnalytics.shared.purchase(customerID: 123, subTotal: 123, promoCode: 123, delCharge: 123)
