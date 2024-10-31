//
//  LoggerImpl.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 18.08.2020.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import Foundation

/// Класс предназначенный для реализации основной логики работы логгера.
final class LoggerImpl: @unchecked Sendable {
    static let global: LoggerImpl = LoggerImpl()

    private let destionationsLock: FastLock = makeFastLock()
    private var destinations: [LogDestination] = []
    // Некоторая замена DispatchQueue но сделанная специально под логгер.
    // Добавление элементов в очередь быстрее на 2 порядка!
    // Исполнение очереди быстрее в 2-3 раза
    // среднее время на добавление элемента: 286 * 10^-9 = 0.000000286 секунды или по другому за секунду около 3500000 добавлений
    private let queue = FastSerialQueue(label: "fastlogger.queue")

    func start() {
        queue.start()
    }

    func addDestination(_ destination: LogDestination) {
        destionationsLock.locked { destinations.append(destination) }
    }

    func removeDestination(_ destination: LogDestination) {
        destionationsLock.locked { destinations.removeAll { $0 === destination } }
    }

    /// Основная универсальная функция логирования. Все остальные функции вызывают её.
    /// Так как сообщение сделано на `autoclosure` надо быть аккуратней и использовать в сообщениях только не изменяемые поля.
    /// Причина этого в том, что сам closure может вычислиться намного позже чем вызов функции.
    ///
    /// - Parameters:
    ///   - level: Уровень логирования. Для большей информации см. `LogLevel`
    ///   - module: Модуль из которого вызывается логгирование.
    ///   - msgClosure: сообщение которое будет выведено. Сделано `autoclosure` для более быстрого исполнения.
    ///   - path: путь до файла - генерируется автоматически
    ///   - line: строчка кода в файле - генерируется автоматически
    ///   - fun: название функции в файле - генерируется автоматически
    func other(_ level: LogLevel,
               _ package: String,
               _ msgClosure: @escaping @Sendable () -> String,
               path: StaticString = #file,
               line: UInt = #line,
               fun: StaticString = #function) {
        let date = Date()
        queue.async {
            var msg: LogMessage?
            for destination in self.destionationsLock.locked({ self.destinations }) {
                if destination.limitOutputLevel.priority < level.priority {
                    continue
                }

                let message = msg ?? LogMessage(level: level,
                                                package: package,
                                                path: path,
                                                line: line,
                                                method: fun,
                                                date: date,
                                                msg: msgClosure())
                msg = message
                destination.process(message)
            }
        }
    }

    func waitForFinish() {
        start() // На случай если мы вызвали эту функцию до полной инициализации лога.
        queue.wait()
    }
}
