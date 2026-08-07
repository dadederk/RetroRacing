//
//  GroupActivitiesSharePlayHostActivationControllerTests.swift
//  RetroRacingUniversalTests
//
//  Created by Dani Devesa on 01/08/2026.
//

import Testing
import RetroRacingShared
@testable import RetroRacingShared

@MainActor
struct GroupActivitiesSharePlayHostActivationControllerTests {
    @Test func testGivenPendingActivationWhenPreparingAgainThenDuplicateRequestIsIgnored() {
        let controller = makeController()

        #expect(controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics))
        #expect(
            controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics) == false
        )
        #expect(controller.isPendingHostActivation)
    }

    @Test func testGivenInFlightActivationWhenPreparingAgainThenRequestIsIgnored() async {
        let controller = makeController()
        _ = controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics)

        #expect(
            controller.beginDirectActivation(
                reason: .eligibleMenuRequest,
                hasDeliveredSession: false,
                diagnostics: diagnostics
            ) == .activate
        )
        #expect(controller.isActivationInFlight)
        #expect(
            controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics) == false
        )
    }

    @Test func testGivenPendingActivationWhenDirectActivationSucceedsThenActivationAwaitsSession() async throws {
        let controller = makeController(activationResult: .success(true))
        _ = controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics)

        #expect(
            controller.beginDirectActivation(
                reason: .eligibleMenuRequest,
                hasDeliveredSession: false,
                diagnostics: diagnostics
            ) == .activate
        )
        let didActivate = try await controller.activatePendingActivity()
        let shouldAwaitSession = controller.completeDirectActivation(
            didActivate: didActivate,
            reason: .eligibleMenuRequest,
            sessionWasDelivered: false,
            diagnostics: diagnostics
        )

        #expect(shouldAwaitSession)
        #expect(controller.isPendingHostActivation)
        #expect(controller.isActivationInFlight == false)
    }

    @Test func testGivenPendingActivationWhenDirectActivationReturnsFalseThenPendingActivationClears() async throws {
        let controller = makeController(activationResult: .success(false))
        _ = controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics)

        #expect(
            controller.beginDirectActivation(
                reason: .eligibleMenuRequest,
                hasDeliveredSession: false,
                diagnostics: diagnostics
            ) == .activate
        )
        let didActivate = try await controller.activatePendingActivity()
        let shouldAwaitSession = controller.completeDirectActivation(
            didActivate: didActivate,
            reason: .eligibleMenuRequest,
            sessionWasDelivered: false,
            diagnostics: diagnostics
        )

        #expect(shouldAwaitSession == false)
        #expect(controller.isPendingHostActivation == false)
        #expect(controller.isActivationInFlight == false)
    }

    @Test func testGivenPendingActivationWhenDirectActivationThrowsThenPendingActivationClears() async {
        let controller = makeController(activationResult: .failure(ActivationFailure()))
        _ = controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics)

        #expect(
            controller.beginDirectActivation(
                reason: .eligibleMenuRequest,
                hasDeliveredSession: false,
                diagnostics: diagnostics
            ) == .activate
        )
        do {
            _ = try await controller.activatePendingActivity()
            Issue.record("Expected activation to throw")
        } catch {
            let shouldAwaitSession = controller.failDirectActivation(
                error: error,
                reason: .eligibleMenuRequest,
                sessionWasDelivered: false,
                diagnostics: diagnostics
            )
            #expect(shouldAwaitSession == false)
        }

        #expect(controller.isPendingHostActivation == false)
        #expect(controller.isActivationInFlight == false)
    }

    @Test func testGivenDeliveredSessionWhenDirectActivationBeginsThenItShortCircuits() {
        let controller = makeController()
        _ = controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics)

        let disposition = controller.beginDirectActivation(
            reason: .eligibleMenuRequest,
            hasDeliveredSession: true,
            diagnostics: diagnostics
        )

        #expect(disposition == .completed(true))
        #expect(controller.isActivationInFlight == false)
    }

    @Test func testGivenPendingActivationWhenCancellingThenCancellationReportsOnce() {
        let controller = makeController()
        _ = controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics)

        #expect(controller.cancel(reason: .sharingControllerDismissed))
        #expect(controller.isPendingHostActivation == false)
        #expect(controller.cancel(reason: .sharingControllerDismissed) == false)
    }

    @Test func testGivenPendingActivationWhenLeavingWithoutSessionThenCancellationReportsOnce() {
        let controller = makeController()
        _ = controller.prepare(source: .menuRequest, isSessionActive: false, diagnostics: diagnostics)

        #expect(controller.cancelForLeaveWithoutSession())
        #expect(controller.isPendingHostActivation == false)
        #expect(controller.cancelForLeaveWithoutSession() == false)
    }
}

private extension GroupActivitiesSharePlayHostActivationControllerTests {
    var diagnostics: GroupActivitiesSharePlayHostActivationDiagnostics {
        GroupActivitiesSharePlayHostActivationDiagnostics(generation: 42, stateName: "waitingForFriend")
    }

    func makeController(
        activationResult: Result<Bool, Error> = .success(true)
    ) -> GroupActivitiesSharePlayHostActivationController {
        GroupActivitiesSharePlayHostActivationController {
            switch activationResult {
            case .success(let didActivate):
                return didActivate
            case .failure(let error):
                throw error
            }
        }
    }
}

private struct ActivationFailure: Error {}
