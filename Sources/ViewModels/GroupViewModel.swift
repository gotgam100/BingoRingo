import Foundation
import FirebaseFirestore

@MainActor
final class GroupViewModel: ObservableObject {
    @Published var groups: [BingoGroup] = []
    @Published var isLoading: Bool = false
    private var listener: ListenerRegistration?

    func fetchGroups(for memberID: String) {
        isLoading = true
        let db = Firestore.firestore()
        listener = db.collection("groups")
            .whereField("memberIDs", arrayContains: memberID)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                self.groups = snapshot?.documents.compactMap {
                    try? $0.data(as: BingoGroup.self)
                } ?? []
                self.isLoading = false
            }
    }

    func createGroup(name: String, leaderID: String) async throws {
        let code = String(UUID().uuidString.prefix(6).uppercased())
        let group = BingoGroup(
            name: name,
            inviteCode: code,
            memberIDs: [leaderID],
            leaderID: leaderID
        )
        try await FirestoreService.shared.createGroup(group)
    }

    func joinGroup(inviteCode: String, memberID: String) async throws {
        guard var group = try await FirestoreService.shared.fetchGroup(byInviteCode: inviteCode) else {
            throw GroupError.notFound
        }
        guard group.memberIDs.count < 10 else { throw GroupError.full }
        guard !group.memberIDs.contains(memberID) else { return }
        group.memberIDs.append(memberID)
        try await FirestoreService.shared.createGroup(group)
    }

    deinit {
        listener?.remove()
    }

    enum GroupError: LocalizedError {
        case notFound
        case full
        var errorDescription: String? {
            switch self {
            case .notFound: return Localization.isEnglish ? "Invite code not found." : "초대 코드를 찾을 수 없어요."
            case .full:     return Localization.isEnglish ? "This room is full (max 10 members)." : "방이 꽉 찼어요. (최대 10명)"
            }
        }
    }
}
