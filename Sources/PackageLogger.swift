//
//  PackageLogger.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 22/02/2019.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

/// Логгер привязанный к пакету. Позволяет в сообщения логгера добавлять доп информацию о имени модуля/пакета.
public struct PackageLogger {
    /// Название модуля/пакета.
    public let name: String

    /// Инициализация логгера с конкретным названием модуля/пакета.
    /// - Parameter name: Название модуля/пакет.
    public init(name: String) {
        Swift.assert(!name.isEmpty, "module name can't be empty. If your no need module name, please use simple syntax `log.`")
        self.name = name
    }

    /// Основная универсальная функция логирования. Все остальные функции вызывают её.
    /// Так как сообщение сделано на `autoclosure` надо быть аккуратней и использовать в сообщениях только не изменяемые поля.
    /// Причина этого в том, что сам closure может вычислиться намного позже чем вызов функции.
    ///
    /// - Parameters:
    ///   - level: Уровень логирования. Для большей информации см. `LogLevel`
    ///   - msgClosure: сообщение которое будет выведено. Сделано `autoclosure` для более быстрого исполнения.
    ///   - path: путь до файла - генерируется автоматически
    ///   - line: строчка кода в файле - генерируется автоматически
    ///   - fun: название функции в файле - генерируется автоматически
    public func other(_ level: LogLevel,
                      _ msgClosure: @escaping @autoclosure @Sendable () -> String,
                      path: StaticString = #file,
                      line: UInt = #line,
                      fun: StaticString = #function) {
        LoggerImpl.global.other(level, name, msgClosure, path: path, line: line, fun: fun)
    }
}
