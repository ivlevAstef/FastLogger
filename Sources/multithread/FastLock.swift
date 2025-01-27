//
//  FastLock.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 02.05.2018.
//  Copyright © 2018 Alexander Ivlev. All rights reserved.
//

internal protocol FastLock: Sendable {
    func lock()
    func unlock()
    func locked<Result>(_ closure: () -> Result) -> Result
}

internal func makeFastLock() -> FastLock {
    #if os(Linux)
        return SpinLock()
    #else
        return UnfairLock()
    #endif
}

#if os(Linux)

import Glibc

private class SpinLock: @unchecked Sendable, FastLock {
    private var monitor: pthread_spinlock_t = 0

    init() {
        if pthread_spin_init(&monitor, 0) != 0 {
            fatalError("Spin lock initialization failed")
        }
    }

    deinit {
        pthread_spin_destroy(&monitor)
    }

    func lock() {
        pthread_spin_lock(&monitor)
    }

    func unlock() {
        pthread_spin_unlock(&monitor)
    }
}

#else

import Darwin

private class UnfairLock: @unchecked Sendable, FastLock {
    private let monitor: os_unfair_lock_t

    init() {
      monitor = .allocate(capacity: 1)
      monitor.initialize(to: os_unfair_lock())
    }

    deinit {
        monitor.deinitialize(count: 1)
        monitor.deallocate()
    }

    func lock() { os_unfair_lock_lock(monitor) }
    func unlock() { os_unfair_lock_unlock(monitor) }
    func locked<Result>(_ closure: () -> Result) -> Result {
        lock()
        defer { unlock() }
        return closure()
    }
}

#endif
