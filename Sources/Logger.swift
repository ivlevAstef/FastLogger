//
//  Logger.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 22/02/2019.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import Foundation

/// Базовый экземпляр логгера, не привязанный к модулю.
/// В коде можно использовать следующим образом:
/// ```
/// import FastLogger
/// log.info("message")
/// log.error("message")
/// ...
/// ```
/// Для большей информации о уровнях логирования смотри `LoggerLevels`
public let log = Logger()

/// Класс предназначенный для логирования и настроек логгера.
/// Использовать через переменную 'log'
/// Если хочется добавить указание модуля/пакета, то рекомендуется такой синтаксис:
/// ```
/// /// Объявление:
/// extension Logger {
///     fileprivate var module { PackageLogger(name: "module_name") }
/// }
///
/// /// Использование:
/// log.module.info("your message")
/// ```
public struct Logger: Sendable {
    /// Настройки, а также методы для контроля жизненного цикла логгера.
    public struct Configuration: Sendable {
        /// Запускает логгер. Вызывать этот метод единожды, после настройки всего что нужно.
        /// Без вывоза этого метода, все переданные сообщения в логгер будут накапливаться в нем, но не будут никуда записаны.
        /// Поэтому даже если вы начнете писать сообщения в логгер, до того как его запустите, сообщения не будут потеряны.
        public func start() {
            LoggerImpl.global.start()
        }

        /// Добавляет во все логгеры поток вывода информации. То есть в переданный объект будут приходить готовые сообщения от логгера.
        ///
        /// - Parameter destination: обработчик готовых сообщений от логера
        public func addDestination(_ destination: LogDestination) {
            LoggerImpl.global.addDestination(destination)
        }

        /// Удаляет поток вывода информации.
        ///
        /// - Parameter destination: обработчик готовых сообщений от логера
        public func removeDestination(_ destination: LogDestination) {
            LoggerImpl.global.removeDestination(destination)
        }

        /// Функция которая ожидает завершения записи всех сообщений логирования в destinations, которые были добавлены до момента вызова функции.
        /// Функция предназначена в первую очередь для дозаписи всех сообщение перед уничтожение приложения в случае краша:
        /// ```
        /// class AppDelegate {
        /// ...
        /// func applicationWillTerminate(_ application: UIApplication) {
        ///     log.warning("Application Terminate")
        ///     log.waitForFinish()
        /// }
        /// }
        /// ```
        public func waitForFinish() {
            LoggerImpl.global.waitForFinish()
        }
    }

    /// Настройки, а также методы для контроля жизненного цикла логгера.
    public let configuration: Configuration = Configuration()

    fileprivate init() { }

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
        LoggerImpl.global.other(level, "", msgClosure, path: path, line: line, fun: fun)
    }
}
