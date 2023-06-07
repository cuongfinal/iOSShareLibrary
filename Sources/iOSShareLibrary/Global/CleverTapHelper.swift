//
//  CleverTapHelper.swift
//  
//
//  Created by Order Tiger on 7/28/22.
//

import Foundation
import CleverTapSDK
import iOSRepositories

fileprivate struct CleverTapCompanyInfo {
    var companyCountry: String
    var companyId: Int
}

public class CleverTapHelper: NSObject, CleverTapInAppNotificationDelegate {
    
    public static var shared: CleverTapHelper = .init()
    fileprivate var companyInfo: CleverTapCompanyInfo?
    @LazyInjected var systemEvents: SystemEvents
    @LazyInjected var appState: AppStore<AppState>
    
    private override init() {}
    
    public func setInAppMessageDelegate() {
        CleverTap.sharedInstance()?.setInAppNotificationDelegate(self)
    }
    
    public func inAppNotificationButtonTapped(withCustomExtras customExtras: [AnyHashable : Any]!) {
        let dict = (customExtras as NSDictionary) as NSDictionary
        if let triggerNotification = dict.object(forKey: "trigger_notification") as? String,
           triggerNotification.elementsEqual("true") {
            if let customer = appState[\.userData.customer],
               let company = appState[\.userData.company] {
                if company.cleverTap != nil {
                    self.systemEvents.requestNotificationPermissionCleverTap(isSigIn: true, cus: customer)
                }
            }
        }
    }
    
    public func setCompanyInfo(country: String, companyId: Int) {
        companyInfo = CleverTapCompanyInfo(companyCountry: country, companyId: companyId)
    }
    
    public func sendUserLogin(info: Dictionary<String, Any>) {
        CleverTap.sharedInstance()?.onUserLogin(info)
    }
    
    public func updateProfile(info: Dictionary<String, Any>, city: String?) {
        var info = info
        if let city = city {
            info["City"] = city
        }
        CleverTap.sharedInstance()?.profilePush(info)
    }
    
    public func sendStoreSearch(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("STORE_SEARCH", parameters: parameters)
    }
    
    public func sendStoreFiltering(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("STORE_FILTERING", parameters: parameters)
    }
    
    public func sendStoreFilteringByName(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("STORE_FILTERING_BY_NAME", parameters: parameters)
    }
    
    public func sendStoreSelected(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("STORE_SELECTED", parameters: parameters)
    }
    
    public func sendProductFilteringByName(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("PRODUCT_FILTERING_BY_NAME", parameters: parameters)
    }
    
    public func sendProductAdd(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("PRODUCT_ADDED", parameters: parameters)
    }
    
    public func sendSignUpSuccessful(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("SIGNUP_SUCCESSFUL", parameters: parameters)
    }
    
    public func sendCheckoutInitiated(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("CHECKOUT_INITIATED", parameters: parameters)
    }
    
    public func sendPromoCodeApplied(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("PROMO_CODE_APPLIED", parameters: parameters)
    }
    
    public func sendProfileUpdate(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("PROFILE_UPDATED", parameters: parameters)
    }
    
    public func sendPaymentInfoAdded(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("PAYMENT_INFO_ADDED", parameters: parameters)
    }
    
    public func sendCharged(_ detail: [String: Any], items: [[String: Any]]) {
        var detail = detail
        if let companyInfo = CleverTapHelper.shared.companyInfo {
            detail["Country_ID"] = companyInfo.companyCountry
            detail["Company_ID"] = companyInfo.companyId
        }
        detail["Device_Type"] = "iOS"
        print("CT Charge sent")
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: detail, andItems: items)
    }
    
    public func sendLogInSuccessful(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("LOGIN_SUCCESSFUL", parameters: parameters)
    }
    
    public func sendLogOut(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("LOGGED_OUT", parameters: parameters)
    }
    
    public func sendCardViewed(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("CART_VIEWED", parameters: parameters)
    }
    
    public func sendCheckoutPaymentPage(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("CHECKOUT_PAYMENT_PAGE", parameters: parameters)
    }
    
    public func sendPaymentFailed(_ parameters: [String: Any]? = nil) {
        CleverTap.logEvent("PAYMENT_FAILED", parameters: parameters)
    }
    
    public func handleNotification(userInfo: [AnyHashable : Any], openDeepLinksInForeground: Bool) {
        CleverTap.sharedInstance()?.handleNotification(withData: userInfo, openDeepLinksInForeground: openDeepLinksInForeground)
    }
    
    public func getUnreadAppInbox() -> Bool {
        return CleverTap.sharedInstance()?.getInboxMessageUnreadCount() ?? 0 > 0
    }
}

extension CleverTap {
    static func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        if var parameters = parameters {
            if let companyInfo = CleverTapHelper.shared.companyInfo {
                parameters["Country_ID"] = companyInfo.companyCountry
                parameters["Company_ID"] = companyInfo.companyId
            }
            parameters["Device_Type"] = "iOS"
            CleverTap.sharedInstance()?.recordEvent(event, withProps: parameters)
        } else {
            if let companyInfo = CleverTapHelper.shared.companyInfo {
                let params = [
                    "Country_ID": companyInfo.companyCountry,
                    "Company_ID": companyInfo.companyId,
                    "Device_Type": "iOS"
                ] as [String : Any]
                CleverTap.sharedInstance()?.recordEvent(event, withProps: params)
            } else {
                CleverTap.sharedInstance()?.recordEvent(event)
            }
        }
    }
}
