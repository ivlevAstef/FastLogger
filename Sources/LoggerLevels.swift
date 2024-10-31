//
//  LoggerLevels.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 25/02/2019.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

public protocol LoggerLevels {
    func other(_ level: LogLevel,
               _ msgClosure: @escaping @autoclosure @Sendable () -> String,
               path: StaticString,
               line: UInt,
               fun: StaticString)
}

// MARK: - Расширения для более удобного логирования
extension LoggerLevels {
    /// Функция логирования критической ошибки. После исполнения этой функции программа точно упадет.
    /// Перед падением будет вызвана функция `waitForFinish` дабы дождаться всех сообщений записанных до этого момента.
    /// Более подробно см `LogLevel`
    public func fatal(_ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) -> Never {
        other(.fatal, msg(), path: path, line: line, fun: fun)
        LoggerImpl.global.waitForFinish()
        fatalError(msg(), file: path, line: line)
    }

    /// Эквивалент assertionFailure, но с той лишь разницей что в релиз сборке данная проблема попадет в лог.
    /// Перед выкидывание ассерта в дебаге будет вызвана функция `waitForFinish` дабы дождаться всех сообщений записанных до этого момента.
    /// Более подробно см `LogLevel`
    public func assert(_ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) {
        other(.assert, msg(), path: path, line: line, fun: fun)
        #if DEBUG
        LoggerImpl.global.waitForFinish()
        assertionFailure(msg(), file: path, line: line)
        #endif
    }

    /// Эквивалент assert, но с той лишь разницей что в релиз сборке данная проблема попадет в лог.
    /// Перед выкидывание ассерта в дебаге будет вызвана функция `waitForFinish` дабы дождаться всех сообщений записанных до этого момента.
    /// Более подробно см `LogLevel`
    public func assert(_ condition: Bool, _ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) {
        if !condition {
            other(.assert, msg(), path: path, line: line, fun: fun)
            #if DEBUG
            LoggerImpl.global.waitForFinish()
            assertionFailure(msg(), file: path, line: line)
            #endif
        }
    }

    /// Функция логирования не критической ошибки. Более подробно см `LogLevel`
    public func error(_ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) {
        other(.error, msg(), path: path, line: line, fun: fun)
    }

    /// Функция логирования предупреждения. Более подробно см `LogLevel`
    public func warning(_ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) {
        other(.warning, msg(), path: path, line: line, fun: fun)
    }

    /// Функция логирования информации. Более подробно см `LogLevel`
    public func info(_ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) {
        other(.info, msg(), path: path, line: line, fun: fun)
    }

    /// Функция логирования дебаг информации. Более подробно см `LogLevel`
    public func debug(_ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) {
        other(.debug, msg(), path: path, line: line, fun: fun)
    }

    /// Функция логирования не важной информации. Более подробно см `LogLevel`
    public func trace(_ msg: @escaping @autoclosure @Sendable () -> String, path: StaticString = #file, line: UInt = #line, fun: StaticString = #function) {
        other(.trace, msg(), path: path, line: line, fun: fun)
    }
}

extension Logger: LoggerLevels {}
extension PackageLogger: LoggerLevels {}

