import UIKit
import FirebaseStorage

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()

    // MARK: - 인증 사진 업로드

    func uploadProofImage(_ image: UIImage, groupID: String, cellID: String, memberID: String) async throws -> String {
        let compressed = compressImage(image)
        let path = "proof/\(groupID)/\(cellID)/\(memberID)"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(compressed, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - 인증 사진 삭제

    func deleteProofImage(groupID: String, cellID: String, memberID: String) async {
        let path = "proof/\(groupID)/\(cellID)/\(memberID)"
        let ref = storage.reference().child(path)
        try? await ref.delete()
    }

    // MARK: - 이미지 압축 (최대 600px, JPEG 45%) — 빠른 업로드 우선
    private func compressImage(_ image: UIImage) -> Data {
        let maxSize: CGFloat = 600
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.45) ?? Data()
    }
}
