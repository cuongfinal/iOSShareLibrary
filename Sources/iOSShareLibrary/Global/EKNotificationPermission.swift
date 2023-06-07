//
//  EKNotificationPermission.swift
//
//
//  Created by Order Tiger on 11/17/21.
//

import UIKit
import UserNotifications
import CleverTapSDK
import OneSignal
import iOSRepositories

public class EKNotificationPermission: NSObject, UNUserNotificationCenterDelegate {
    public static var shared = EKNotificationPermission()
    public var center: UNUserNotificationCenter?
    @LazyInjected var systemEvents: SystemEvents
    @LazyInjected var appState: AppStore<AppState>
    
    private override init() { }
    
    public func request(completion: @escaping (Bool) -> Void) {
        guard let center = center else {
            center = UNUserNotificationCenter.current()
            request(completion: completion)
            return
        }
        
        func complete(granted: Bool) {
            DispatchQueue.main.async {
                completion(granted)
            }
        }
        center.delegate = self
        center.getNotificationSettings { sett in
            center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, _) in
                if sett.authorizationStatus == .notDetermined, granted {
//                    OneSignalHelper.shared.setConsentGrant()
                    if let customer = self.appState[\.userData.customer],
                       let company = self.appState[\.userData.company], company.oneSignal != nil {
                        OneSignalHelper.shared.setExternalId(customer.id, email: customer.email, phoneNumber: customer.getPhoneNumber()) { isCompleted in
                            complete(granted: granted)
                        }
                    } else {
                        complete(granted: granted)
                    }
                } else {
                    complete(granted: granted)
                }
            }
        }
    }
    
    public func setDelegate() {
        // For cleverTap handle noti tap
        guard let center = center else {
            center = UNUserNotificationCenter.current()
            setDelegate()
            return
        }
        center.delegate = self
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // if you wish CleverTap to record the notification open and fire any deep links contained in the payload. Skip this line if you have opted for auto-integrate.
        CleverTapHelper.shared.handleNotification(userInfo: response.notification.request.content.userInfo, openDeepLinksInForeground: false)
        completionHandler()
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        CleverTapHelper.shared.handleNotification(userInfo: notification.request.content.userInfo, openDeepLinksInForeground: true)
        completionHandler([.badge, .sound, .alert])
    }
    
    public func openSettings(isOn: Bool, cancel: (() -> Void)? = nil) {
        let title = isOn ? "Notification is Turned Off" : "Notification is Turned On"
        let content = isOn ? "Press settings to update or cancel to deny access" : "Turn off push notifications from app settings on your phone"
        if let vc = UIScreen.visibleViewController() {
            let alert = UIAlertController(title: title,
                                          message: content,
                                          preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            
            alert.addAction(settingsAction)
            alert.addAction(
                UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    cancel?()
                }
            )
            vc.present(alert, animated: true)
        }
    }
    
    public var status: UNAuthorizationStatus {
        var notificationSettings: UNNotificationSettings?
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            UNUserNotificationCenter.current().getNotificationSettings { setttings in
                notificationSettings = setttings
                semaphore.signal()
            }
        }
        semaphore.wait()
        return notificationSettings?.authorizationStatus ?? .notDetermined
    }
}
