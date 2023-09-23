//
//  LoggerImpl.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 18.08.2020.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import Foundation

/// Класс предназначенный для реализации основной логики работы логгера.
final class LoggerImpl {
    static let global: LoggerImpl = LoggerImpl()

    private let destionationsLock: FastLock = makeFastLock()
    private var destinations: [LogDestination] = []
    // Некоторая замена DispatchQueue но сделанная специально под логгер.
    // Добавление элементов в очередь быстрее на 2 порядка!
    // Исполнение очереди быстрее в 2-3 раза
    // среднее время на добавление элемента: 286 * 10^-9 = 0.000000286 секунды или по другому за секунду около 3500000 добавлений
    private var queue = FastSerialQueue(label: "fastlogger.queue")

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
               _ msgClosure: @escaping () -> String,
               path: StaticString = #file,
               line: UInt = #line,
               fun: StaticString = #function) {
        let messageFormatter = MessageFormatter(level: level,
                                                package: package,
                                                path: path,
                                                line: line,
                                                fun: fun,
                                                date: Date())
        queue.async {
            var msg: String?
            for destination in self.destionationsLock.locked({ self.destinations }) {
                if destination.limitOutputLevel.priority < level.priority {
                    continue
                }

                let message = msg ?? msgClosure()
                msg = message
                let formattedMsg = messageFormatter.formatMessage(format: destination.format, msg: message)
                destination.process(formattedMsg, package: package, level: level)
            }
        }
    }

    func waitForFinish() {
        start() // На случай если мы вызвали эту функцию до полной инициализации лога.
        queue.wait()
    }
}

/// Класс для форматирования сообщения согласно некоторому формату
private class MessageFormatter {
    private static let debugFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss.SSS"
        return formatter
    }()
    private static let nanoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    private static let anyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    private static let fileFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter
    }()

    private let level: LogLevel
    private let package: String
    private let path: StaticString
    private let line: UInt
    private let fun: StaticString
    private let date: Date

    private lazy var file: String = {
        return ("\(path)" as NSString).lastPathComponent
    }()

    internal init(level: LogLevel, package: String, path: StaticString, line: UInt, fun: StaticString, date: Date) {
        self.level = level
        self.package = package
        self.path = path
        self.line = line
        self.fun = fun
        self.date = date
    }

    internal func formatMessage(format: String, msg: String) -> String {
        var result = format
        // В принципе это можно серьезно ускорить, но зачем? - всеравно не в главном потоке
        replaceIfNeed(in: &result, find: "%Dd", on: MessageFormatter.debugFormatter.string(from: self.date))
        replaceIfNeed(in: &result, find: "%Dn", on: MessageFormatter.nanoFormatter.string(from: self.date))
        replaceIfNeed(in: &result, find: "%Da", on: MessageFormatter.anyFormatter.string(from: self.date))
        replaceIfNeed(in: &result, find: "%Df", on: MessageFormatter.fileFormatter.string(from: self.date))
        replaceIfNeed(in: &result, find: "%s", on: "\(self.level.shortName)")
        replaceIfNeed(in: &result, find: "%L", on: "\(self.level.name)")
        replaceIfNeed(in: &result, find: "%e", on: "\(self.level.emoji)")
        replaceIfNeed(in: &result, find: "%F", on: self.file)
        replaceIfNeed(in: &result, find: "%l", on: "\(self.line)")
        replaceIfNeed(in: &result, find: "%M", on: "\(self.fun)")
        replaceIfNeed(in: &result, find: "%m", on: msg)
        if package.isEmpty {
            replaceIfNeed(in: &result, find: "%p", on: package)
        }

        return result
    }

    private func replaceIfNeed(in text: inout String, find: String, on substringClosure: @autoclosure () -> String) {
        var substring: String?
        while let range = text.range(of: find) {
            let subtext = substring ?? substringClosure()
            substring = subtext
            text.replaceSubrange(range, with: subtext)
        }
    }

}

extension LogLevel {
    internal var name: String {
        switch self {
        case .fatal: return "FATAL"
        case .assert: return "ASSERT"
        case .error: return "ERROR"
        case .warning: return "WARNING"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        case .trace: return "TRACE"
        case .none: return ""
        }
    }

    internal var shortName: String {
        switch self {
        case .fatal: return "FTL"
        case .assert: return "AST"
        case .error: return "ERR"
        case .warning: return "WRG"
        case .info: return "INF"
        case .debug: return "DBG"
        case .trace: return "TRC"
        case .none: return ""
        }
    }

    internal var emoji: String {
        switch self {
        case .fatal: return "🛑"
        case .assert: return "⁉️"
        case .error: return "❗️"
        case .warning: return "⚠️"
        case .info: return "🔹"
        case .debug: return "▶️"
        case .trace: return "🗯"
        case .none: return ""
        }
    }
}
