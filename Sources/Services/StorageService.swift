import Foundation
import FirebaseStorage
import UIKit

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()

    func uploadProofPhoto(_ image: UIImage, boardID: String, cellID: String, memberID: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }
        let path = "proofs/\(boardID)/\(cellID)/\(memberID).jpg"
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    enum StorageError: Error {
        case invalidImage
    }
}
