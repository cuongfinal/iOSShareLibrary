//
//  OneSignalHelper.swift
//  
//
//  Created by Cuong Le on 8/12/22.
//

import Foundation
import OneSignal
import iOSRepositories
import UICompanent

enum OneSignalKey: String {
    case storeSelected = "store_selected"
    case addToCart = "add_to_cart"
    case viewCart = "view_basket"
    case checkoutInitiated = "checkout_initiated"
    case purchase = "purchase"
}

public class OneSignalHelper {
    public static var shared: OneSignalHelper = .init()
    @LazyInjected var appState: AppStore<AppState>
    @LazyInjected private var repoOS: OneSignalRepository
    
    private init() { }
    
    public func setExternalId(_ customerId: Int?,
                              email: String?,
                              phoneNumber: String?, completion: ((Bool) -> Void)?) {
        guard  let customerId = customerId, haveOneSignalConfig() else {
            return
        }
        
        OneSignal.setExternalUserId(String(customerId)) { results in
            if let completion = completion {
                completion(true)
            }
        }

        // Link externalId into email, sms
        if let customer = self.appState[\.userData.customer],
            let deviceState = OneSignal.getDeviceState(), let OSAppId = OneSignal.appId() {
            
            Task {
                // Set Email
                if let email = email, customer.promotionEmail == true {
                    if let emailUID = deviceState.emailUserId {
                        // If linked, update opt in/out state
                        _ = try? await self.repoOS.optInOutSubscriptionOneSignal(appId: OSAppId, playerId: emailUID, isOptIn: true)
                    } else {
                        // Set new if not linked
                        OneSignal.setEmail(email) {
                            OneSignal.setExternalUserId(String(customerId))
                        } withFailure: { _ in }
                    }
                }
                
                // Set SMS
                if let phoneNumber = phoneNumber, customer.promotionSms == true {
                    if let smsUID = deviceState.smsUserId {
                        // If linked, update opt in/out state
                        _ = try? await self.repoOS.optInOutSubscriptionOneSignal(appId: OSAppId, playerId: smsUID, isOptIn: true)
                    } else {
                        // Set new if not linked
                        OneSignal.setSMSNumber(phoneNumber) { _ in
                            OneSignal.setExternalUserId(String(customerId))
                        } withFailure: { _ in }
                    }
                    
                }
            }
        }
    }
    
    public func logOutAll() {
        guard haveOneSignalConfig() else { return }
        removeExternalId()
        logoutEmail()
        logoutSMS()
        OneSignal.getTags({tagsReceived in
            print("tagsReceived: ", tagsReceived.debugDescription)
            var tagsArray = [String]()
            if let tagsHashableDictionary = tagsReceived {
                tagsHashableDictionary.forEach({
                    if let asString = $0.key as? String {
                        tagsArray += [asString]
                    }
                })
            }
            print("tagsArray: ", tagsArray)
            OneSignal.deleteTags(tagsArray, onSuccess: { tagsDeleted in
                print("tags deleted success: ", tagsDeleted.debugDescription)
            }, onFailure: { error in
                print("deleting tags error: ", error.debugDescription)
            })
        })
    }
    
    public func removeExternalId() {
        guard haveOneSignalConfig() else { return }
        OneSignal.removeExternalUserId()
    }
    
    public func disablePush(_ state: Bool) {
        guard haveOneSignalConfig() else { return }
        OneSignal.disablePush(state)
    }
    
    public func logoutEmail() {
        guard haveOneSignalConfig() else { return }
        OneSignal.logoutEmail()
    }
    
    public func logoutSMS() {
        guard haveOneSignalConfig() else { return }
        OneSignal.logoutSMSNumber()
    }
    
    public func unsubcribedEmail() {
        guard haveOneSignalConfig() else { return }
        if let deviceState = OneSignal.getDeviceState(),
            let OSAppId = OneSignal.appId(), let emailUID = deviceState.emailUserId {
            Task {
                _ = try? await self.repoOS.optInOutSubscriptionOneSignal(appId: OSAppId, playerId: emailUID, isOptIn: false)
            }
        }
    }
    
    public func unsubcribedSMS() {
        guard haveOneSignalConfig() else { return }
       
        if let deviceState = OneSignal.getDeviceState(),
            let OSAppId = OneSignal.appId(), let smsUID = deviceState.smsUserId {
            Task {
                _ = try? await self.repoOS.optInOutSubscriptionOneSignal(appId: OSAppId, playerId: smsUID, isOptIn: false)
            }
        }
    }
    
    public func setConsentGrant() {
//        guard haveOneSignalConfig() else { return }
//        OneSignal.consentGranted(true)
    }
    
    public func sendAppStartWithCustomer(_ parameters: [String: Any]? = nil) {
        OneSignalHelper.sendTags(nil, parameters: parameters)
    }
    
    public func clearParamsBasketEmpty() {
        OneSignalHelper.shared.addToCart([:], isClearCart: true)
        OneSignalHelper.shared.storeSelected([:], isClearCart: true)
    }
    
    public func storeSelected(_ parameters: [String: Any]? = nil, isClearCart: Bool = false) {
        if isClearCart {
            OneSignalHelper.sendTags(.storeSelected, value: "", parameters: parameters)
            return
        }
        if let company = appState[\.userData.company] {
            if company.companyType == .portal {
                // Just send in case portal
                OneSignalHelper.sendTags(.storeSelected, parameters: parameters)
            } else {
                guard var parameters = parameters else { return }
                if let firstTag = parameters.first {
                    parameters.removeValue(forKey: firstTag.key)
                    OneSignalHelper.sendTags(nil, keyString: firstTag.key, value: firstTag.value as? String, parameters: parameters)
                }
            }
        }
        
    }
    
    public func addToCart(_ parameters: [String: Any]? = nil, isClearCart: Bool = false) {
        if isClearCart {
            OneSignalHelper.sendTags(.addToCart, value: "", parameters: parameters)
            return
        }
        OneSignalHelper.sendTags(.addToCart, parameters: parameters)
    }
    
    public func viewCart(_ parameters: [String: Any]? = nil) {
        OneSignalHelper.sendTags(.viewCart, parameters: [:])
    }
    
    public func loginAndSignUp(_ parameters: [String: Any]? = nil) {
        // PLAS-68
        guard var parameters = parameters else { return }
        if let firstTag = parameters.first {
            parameters.removeValue(forKey: firstTag.key)
            OneSignalHelper.sendTags(nil, keyString: firstTag.key, value: firstTag.value as? String, parameters: parameters)
        }
    }
    
    public func checkoutInitiated(_ parameters: [String: Any]? = nil) {
        OneSignalHelper.sendTags(.checkoutInitiated, parameters: parameters)
    }
    
    public func profileUpdated(_ parameters: [String: Any]? = nil) {
        // PLAS-68
        guard var parameters = parameters else { return }
        if let firstTag = parameters.first {
            parameters.removeValue(forKey: firstTag.key)
            OneSignalHelper.sendTags(nil, keyString: firstTag.key, value: firstTag.value as? String, parameters: parameters)
        }
    }
    
    public func purchase(_ parameters: [String: Any]? = nil) {
        guard haveOneSignalConfig() else { return }
        OneSignal.getTags { tags in
            if var params = parameters {
                var amountSpent = params["amount_spent"] as? Double ?? 0
                let storeSavings = EKCurrency.symbol + ((amountSpent/100) * 0.2).decimal(2)
                var purchased = 1
                
                if let syncAmountSpent = tags?["amount_spent"] as? String,
                    let syncAmountSpentDouble = Double(syncAmountSpent) {
                    amountSpent = syncAmountSpentDouble + amountSpent
                }
//                if let syncStoreSaving = tags?["store_savings"] as? String,
//                    let syncStoreSavingDouble = Double(syncStoreSaving) {
//                    storeSavings = syncStoreSavingDouble + storeSavings
//                }
                if let syncPurchased = tags?[OneSignalKey.purchase.rawValue] as? String,
                    let syncPurchasedInt = Int(syncPurchased) {
                    purchased = syncPurchasedInt + purchased
                }
                params["amount_spent"] = amountSpent
                params["store_order_savings"] = storeSavings
                OneSignalHelper.sendTags(.purchase, value: String(purchased), parameters: params)
            }
            OneSignalHelper.sendTags(.purchase, value: "1", parameters: nil)
        }
    }
    
    public func sendOutcome(_ value: Double) {
        guard haveOneSignalConfig() else { return }
        OneSignal.sendOutcome(withValue: "Purchase", value: NSNumber(value: value * 100)) { outcomeSent in
            print("outcome sent: \(outcomeSent!.name) with random value: \(value)" )
        }
    }
    
    fileprivate func haveOneSignalConfig() -> Bool {
        if let company = self.appState[\.userData.company] {
            return company.oneSignal != nil
        }
        return false
    }
    
    fileprivate func checkSendTagStatus() -> Bool {
        let deviceState = OneSignal.getDeviceState()
        
        if let customer = self.appState[\.userData.customer] {
            if customer.promotionSms == false &&
                customer.promotionEmail == false &&
                deviceState?.isSubscribed == false {
                return false
            }
        } else {
            if deviceState?.isSubscribed == false {
                return false
            }
        }
        return true
    }
}

extension OneSignalHelper {
    static func sendTags(_ key: OneSignalKey?, keyString: String? = nil, value: String? = nil, parameters: [String: Any]? = nil) {
        guard OneSignalHelper.shared.checkSendTagStatus() else { return }
        
        if var parameters = parameters {
            var keyRaw: String = ""
            if let key = key { keyRaw = key.rawValue } else if let keyString = keyString {
                keyRaw = keyString
            }
            guard !keyRaw.isEmpty else { return }
            
            if let value = value {
                parameters[keyRaw] = value
            } else {
                let timestamp = Int(Date().timeIntervalSince1970)
                parameters[keyRaw] = timestamp
            }
            OneSignal.sendTags(parameters)
            print("👮👮👮 OneSignal Tags Sent: \(parameters)")
        }
    }
}
