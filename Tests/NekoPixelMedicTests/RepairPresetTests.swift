import XCTest
@testable import NekoPixelMedic

final class RepairPresetTests: XCTestCase {
    func testSuperResolutionPlanAlwaysUpscalesTo2x() {
        let plan = RepairPreset.superResolution.makePlan(strength: 0.9)

        XCTAssertEqual(plan.outputScale, 2, accuracy: 0.0001)

        guard case let .upscale(factor)? = plan.passes.first(where: { pass in
            if case .upscale = pass {
                return true
            }
            return false
        }) else {
            return XCTFail("Expected an upscale pass in the super resolution plan.")
        }

        XCTAssertEqual(factor, 2, accuracy: 0.0001)
    }

    func testRestorePlanIncludesTonePassBeforeSharpen() {
        let plan = RepairPreset.restore.makePlan(strength: 0.6)

        XCTAssertEqual(plan.passes.count, 3)

        guard case let .tone(saturation, contrast, _, _, _)? = plan.passes.first else {
            return XCTFail("The restore plan should begin with tone adjustments.")
        }

        XCTAssertGreaterThan(saturation, 1.0)
        XCTAssertGreaterThan(contrast, 1.0)
    }

    func testDeblurPlanStrengthIncreasesSharpenAmount() {
        let softer = RepairPreset.deblur.makePlan(strength: 0.3)
        let stronger = RepairPreset.deblur.makePlan(strength: 0.9)

        let softerAmount = sharpenAmount(in: softer)
        let strongerAmount = sharpenAmount(in: stronger)

        XCTAssertNotNil(softerAmount)
        XCTAssertNotNil(strongerAmount)
        XCTAssertGreaterThan(strongerAmount ?? 0, softerAmount ?? 0)
    }

    private func sharpenAmount(in plan: RepairPlan) -> Double? {
        for pass in plan.passes {
            if case let .sharpen(amount) = pass {
                return amount
            }
        }
        return nil
    }
}
