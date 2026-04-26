import SwiftUI

struct CellEditSheet: View {
    let currentTitle: String
    let currentDescription: String
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var description: String = ""

    init(currentTitle: String, currentDescription: String = "", onSave: @escaping (String, String) -> Void) {
        self.currentTitle = currentTitle
        self.currentDescription = currentDescription
        self.onSave = onSave
        _title = State(initialValue: currentTitle)
        _description = State(initialValue: currentDescription)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()
                    .allowsHitTesting(false)

                // 기하학적 배경 장식
                Circle()
                    .fill(BRColors.primaryDim)
                    .frame(width: 200, height: 200)
                    .offset(x: 160, y: -160)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Circle()
                    .fill(BRColors.surfaceHigh.opacity(0.6))
                    .frame(width: 120, height: 120)
                    .offset(x: -100, y: 400)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    // 헤더
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(BRColors.primaryDim)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(BRColors.primary)
                            }
                            Text(Localization.CellDetail.missionDetail)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                        }

                        Text(Localization.CellDetail.enterMissionDetails)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(BRColors.onSurface)
                            .tracking(-0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 32)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // 제목 필드
                            VStack(alignment: .leading, spacing: 10) {
                                Text(Localization.CellDetail.missionTitle)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                                    .tracking(0.5)

                                TextField(Localization.CellDetail.enterMissionName, text: $title)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(BRColors.onSurface)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .frame(minHeight: 52)
                                    .background(BRColors.surfaceLow)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 세부사항 필드
                            VStack(alignment: .leading, spacing: 10) {
                                Text(Localization.CellDetail.details)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                                    .tracking(0.5)

                                TextEditor(text: $description)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(BRColors.onSurface)
                                    .scrollContentBackground(.hidden)
                                    .scrollDisabled(true)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .frame(height: 100)
                                    .background(BRColors.surfaceLow)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()

                    // 저장 버튼
                    Button {
                        onSave(title, description)
                        dismiss()
                    } label: {
                        Text(Localization.CellDetail.save)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(AnyShapeStyle(BRColors.primaryGradient))
                            .clipShape(RoundedRectangle(cornerRadius: 48))
                            .shadow(
                                color: BRColors.primary.opacity(0.3),
                                radius: 16, y: 5
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.CreateGroup.cancel) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
        }
    }
}
