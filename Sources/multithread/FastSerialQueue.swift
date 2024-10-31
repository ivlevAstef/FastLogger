//
//  FastSerialQueue.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 18.02.2021.
//  Copyright © 2021 TASSTA GmbH. All rights reserved.
//

import Foundation

/// Специальная очередь, которая гарантированно использует один поток.
/// Аналог обычной DispathQueue, но намного быстрее в исполнении.
/// В добавок на этой очереди можно вызывать `sync` внутри `sync` - существует возможность рекурсивного вызова.
final class FastSerialQueue {
    private class Element {
        internal let process: () -> Void
        internal var next: Element? = nil

        internal init(process: @escaping () -> Void) {
            self.process = process
        }
    }

    private let executor: FastSerialQueueExecutor = FastSerialQueueExecutor()
    // в блоке не может быть unowned так как никто не знает, когда же тело потока запуститься
    private lazy var thread = Thread(block: { [executor] in
        // Метод вызовется разово, при инициализации очереди.
        executor.run()
    })

    /// :nodoc:
    init(label: String) {
        self.thread.name = label
    }

    deinit {
        thread.cancel()
        // Нужно чтобы разморозить поток, и чтобы он закрылся. Актуально только если нет операций для вывода.
        executor.onceAwakeThread()
    }

    /// Запускает поток выполнения, если он не был еще запущен.
    /// Обращаю внимание, что не стоит вызывать эту функцию дважды, а также метод инициализации по умолчанию всегда запускает поток.
    func start() {
        if !thread.isExecuting {
            thread.start()
        }
    }

    /// Добавляет дополнительную задачу на исполнение
    /// - Parameter process: Задача которая должна исполнится в другом потоке.
    func async(_ process: @escaping () -> Void) {
        executor.addProcess(process)
    }

    /// Ожидает завершения всех процессов добавленных в очередь на момент вызова этой функции.
    func wait() {
        executor.wait()
    }
}

private final class FastSerialQueueExecutor: @unchecked Sendable {
    private final class Element {
        internal let process: () -> Void
        internal var next: Element? = nil

        internal init(process: @escaping () -> Void) {
            self.process = process
        }
    }

    private var head: Element?
    private var tail: Element?

    private let operationLocker: FastLock = makeFastLock()
    private let syncCounter = DispatchSemaphore(value: 0)

    /// список всех, кто ожидает завершения какой либо операции
    private var waiters: [(element: Element, semaphore: DispatchSemaphore)] = []

    /// Добавляет дополнительную задачу на исполнение
    /// - Parameter process: Задача которая должна исполнится в другом потоке.
    fileprivate func addProcess(_ process: @escaping () -> Void) {
        let newElement = Element(process: process)
        operationLocker.lock()
        unsafeAddElement(newElement)
        operationLocker.unlock()
        syncCounter.signal()
    }

    /// Добавляет дополнительную задачу на исполнение с ожиданием её окончания,
    /// - Parameter process: Задача которая должна исполнится в другом потоке.
    fileprivate func addProcessAndWait(_ process: @escaping () -> Void) {
        let newElement = Element(process: process)
        let waiter = DispatchSemaphore(value: 0)
        operationLocker.lock()
        unsafeAddElement(newElement)
        waiters.append((newElement, waiter))
        operationLocker.unlock()
        syncCounter.signal()

        waiter.wait()
    }

    /// Исполняет все операции до новой задачи включительно.
    /// !!!! Важно - эту операцию можно безопасно вызывать, только с того же потока, на котором идет основной цикл исполнения.
    /// - Parameter process: Задача которая должна исполнится в другом потоке.
    fileprivate func addProcessAndExecute(_ process: @escaping () -> Void) {
        let newElement = Element(process: process)
        operationLocker.lock()
        unsafeAddElement(newElement)
        operationLocker.unlock()

        /// Исполняем все операции последовательно, пока не дойдем и не исполнем нашу.
        while newElement !== executeOneOperation() {
            continue
        }
    }

    private func unsafeAddElement(_ element: Element) {
        if let tail = self.tail {
            tail.next = element
            self.tail = element
        } else {
            self.head = element
            self.tail = element
        }
    }

    fileprivate func onceAwakeThread() {
        syncCounter.signal()
    }

    fileprivate func wait() {
        let waiter: DispatchSemaphore? = operationLocker.locked {
            // Дабы не уйти в бесконечное ожидание если операций нет
            if let tail = self.tail {
                let waiter = DispatchSemaphore(value: 0)
                waiters.append((tail, waiter))
                return waiter
            }
            return nil
        }

        waiter?.wait()
    }

    fileprivate func run() {
        while !Thread.current.isCancelled {
            syncCounter.wait()
            executeOneOperation()
        }
    }

    @discardableResult
    private func executeOneOperation() -> Element? {
        operationLocker.lock()
        let element = head
        head = head?.next

        if head == nil {
            tail = nil
        }

        let semaphoresForSignal = waiters.filter { $0.element === element }.map { $0.semaphore }
        waiters.removeAll(where: { $0.element === element })
        operationLocker.unlock()

        if let element = element {
            element.process()

            // Оповещаем о том, что операция была сделана.
            semaphoresForSignal.forEach { $0.signal() }
            return element
        }

        // Очередь пустая
        return nil
    }
}
