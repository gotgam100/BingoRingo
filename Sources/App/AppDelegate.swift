import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()

        // 알림 위임자
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // APNs 등록 — 권한 요청은 NotificationService에서 별도 수행
        application.registerForRemoteNotifications()

        return true
    }

    // MARK: - APNs

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // APNs 토큰을 FCM에 전달 → FCM이 등록 토큰을 발급
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("APNs 등록 실패: \(error)")
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate (포그라운드 알림 처리)

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// 앱이 포그라운드일 때도 배너/사운드 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    /// 알림 탭 시 호출 — 추후 딥링크 라우팅에 활용 가능
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

// MARK: - MessagingDelegate (FCM 토큰 수신)

extension AppDelegate: MessagingDelegate {

    /// FCM 토큰 발급/갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        #if DEBUG
        print("FCM Token: \(token)")
        #endif
        Task { await NotificationService.shared.saveFCMToken(token) }
    }
}
