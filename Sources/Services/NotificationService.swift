import Foundation
import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseMessaging

/// 푸시 알림 권한 / FCM 토큰 / 방별 알림 설정 관리
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    /// 가장 최근에 수신한 FCM 토큰 (로그인 직후 저장 보류용)
    private var pendingToken: String?

    // MARK: - 권한 요청

    /// 시스템 알림 권한 요청. 이미 결정된 경우 현재 상태 반환.
    @discardableResult
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()

        switch current.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                return granted
            } catch {
                return false
            }
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    /// 현재 시스템 알림 권한 상태 확인
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - FCM 토큰

    /// AppDelegate.MessagingDelegate에서 호출. 로그인된 상태면 즉시 저장, 아니면 보류.
    func saveFCMToken(_ token: String) async {
        pendingToken = token
        guard let memberID = Auth.auth().currentUser?.uid else {
            // 미로그인 상태 — 로그인 후 flushPendingToken()에서 저장
            return
        }
        do {
            try await FirestoreService.shared.updateFCMToken(memberID: memberID, token: token)
        } catch {
            #if DEBUG
            print("FCM 토큰 저장 실패: \(error)")
            #endif
        }
    }

    /// 로그인 직후 호출 — 보류 중이던 토큰을 현재 사용자의 Member 문서에 저장
    func flushPendingToken(memberID: String) async {
        guard let token = pendingToken else { return }
        pendingToken = nil
        do {
            try await FirestoreService.shared.updateFCMToken(memberID: memberID, token: token)
        } catch {
            #if DEBUG
            print("FCM 토큰 flush 실패: \(error)")
            #endif
        }
    }

    /// FCM SDK에서 현재 토큰을 직접 읽어 저장 — 콜백 타이밍과 무관하게 항상 최신 토큰 동기화
    func syncCurrentToken(memberID: String) async {
        guard let token = Messaging.messaging().fcmToken else { return }
        do {
            try await FirestoreService.shared.updateFCMToken(memberID: memberID, token: token)
        } catch {
            #if DEBUG
            print("FCM 토큰 동기화 실패: \(error)")
            #endif
        }
    }

    /// 로그아웃 직전 호출 — 단일 기기 멀티 계정 시나리오 대응
    func clearFCMToken(memberID: String) async {
        do {
            try await FirestoreService.shared.clearFCMToken(memberID: memberID)
        } catch {
            #if DEBUG
            print("FCM 토큰 제거 실패: \(error)")
            #endif
        }
    }

    // MARK: - 방별 알림 설정

    func fetchSettings(groupID: String, memberID: String) async -> NotificationSettings {
        (try? await FirestoreService.shared.fetchNotificationSettings(
            groupID: groupID, memberID: memberID
        )) ?? NotificationSettings()
    }

    func saveSettings(_ settings: NotificationSettings,
                      groupID: String, memberID: String) async {
        do {
            try await FirestoreService.shared.saveNotificationSettings(
                settings, groupID: groupID, memberID: memberID
            )
        } catch {
            #if DEBUG
            print("알림 설정 저장 실패: \(error)")
            #endif
        }
    }
}
