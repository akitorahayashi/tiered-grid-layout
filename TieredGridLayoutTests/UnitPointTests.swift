import SwiftUI
@testable import TieredGridLayout
import XCTest

final class UnitPointTests: XCTestCase {
    var layout: TieredGridLayout!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // TieredGridLayout のデフォルト alignment (.center) を使用してテスト
        layout = TieredGridLayout()
    }

    override func tearDownWithError() throws {
        layout = nil
        try super.tearDownWithError()
    }

    func testDefaultAlignment_isCenter() {
        // TieredGridLayout のデフォルト alignment が .center であることを確認
        let defaultLayout = TieredGridLayout()
        XCTAssertEqual(defaultLayout.alignment, .center, "TieredGridLayout のデフォルト alignment は .center であるべき")
    }

    func testUnitPointMapping() {
        let testCases: [(Alignment, UnitPoint)] = [
            (.topLeading, .topLeading),
            (.top, .top),
            (.topTrailing, .topTrailing),
            (.leading, .leading),
            (.center, .center),
            (.trailing, .trailing),
            (.bottomLeading, .bottomLeading),
            (.bottom, .bottom),
            (.bottomTrailing, .bottomTrailing),
        ]

        for (alignment, expectedUnitPoint) in testCases {
            let result = layout.unitPoint(for: alignment)
            XCTAssertEqual(
                result,
                expectedUnitPoint,
                "Alignment \(alignment) は \(expectedUnitPoint) にマップされることを確認 (実際の結果: \(result))"
            )
        }

        // デフォルトケースを確認
        let defaultCaseResult = layout
            .unitPoint(for: .leadingLastTextBaseline) // 明示的に処理されない alignment を使用
        XCTAssertEqual(defaultCaseResult, .center, "Alignment のデフォルトケースは .center を返すことを確認")
    }
}
