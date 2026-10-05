//
//  OrderedConcurrentMap.swift
//  Xplora
//

/// Transforms `inputs` with at most `maxConcurrentTasks` transforms in flight
/// and returns the results in the same order as `inputs`, regardless of
/// which transform finishes first.
func orderedConcurrentMap<Input, Output>(
    _ inputs: [Input],
    maxConcurrentTasks: Int,
    transform: @escaping @Sendable (Input) async -> Output
) async -> [Output] {
    guard !inputs.isEmpty else { return [] }
    let limit = max(1, maxConcurrentTasks)

    return await withTaskGroup(of: (Int, Output).self) { group in
        var results = [Output?](repeating: nil, count: inputs.count)
        var nextIndex = 0

        func addNextTask() {
            let index = nextIndex
            let input = inputs[index]
            nextIndex += 1
            group.addTask { (index, await transform(input)) }
        }

        while nextIndex < min(limit, inputs.count) {
            addNextTask()
        }
        for await (index, output) in group {
            results[index] = output
            if nextIndex < inputs.count {
                addNextTask()
            }
        }
        return results.map { $0! }
    }
}
