//
//  OrderedConcurrentMapTests.swift
//  XploraTests
//

import Testing
@testable import Xplora

struct OrderedConcurrentMapTests {

    private actor ConcurrencyProbe {
        private(set) var active = 0
        private(set) var peak = 0
        func enter() { active += 1; peak = max(peak, active) }
        func leave() { active -= 1 }
    }

    @Test func resultsKeepInputOrder_whenLaterItemsFinishFirst() async {
        // Earlier items sleep longer, so completion order is reversed.
        let inputs = [1, 2, 3, 4, 5]
        let results = await orderedConcurrentMap(inputs, maxConcurrentTasks: 5) { value in
            try? await Task.sleep(nanoseconds: UInt64(6 - value) * 20_000_000)
            return value * 10
        }
        #expect(results == [10, 20, 30, 40, 50])
    }

    @Test func neverExceedsConcurrencyLimit() async {
        let probe = ConcurrencyProbe()
        _ = await orderedConcurrentMap(Array(0..<10), maxConcurrentTasks: 2) { value in
            await probe.enter()
            try? await Task.sleep(nanoseconds: 10_000_000)
            await probe.leave()
            return value
        }
        #expect(await probe.peak <= 2)
    }

    @Test func emptyInput_returnsEmpty() async {
        let results = await orderedConcurrentMap([Int](), maxConcurrentTasks: 2) { $0 }
        #expect(results.isEmpty)
    }
}
