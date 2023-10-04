//
//  LogDebugDestination.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 23.09.2023.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import Foundation
import OSLog

/// Позволяет записывать сообщения от логгера в дебаг вывод.
open class LogDebugDestination: LogDestination {
    /// Указанный формат логирования при инициализации.
    public let format: LogFormat
    /// :nodoc: see `LogDestination`
    public let limitOutputLevel: LogLevel

    /// Создает выход для логгера, направляющий все сообщений в дебаг вывод.
    /// - Parameters:
    ///   - format: формат, в текстовом представлении, сообщений от логгера в каком виде они будут записываться в файл.
    ///   - limitOutputLevel: Максимальный уровень сообщений, который может быть записан.
    public convenience init(format: String, limitOutputLevel: LogLevel) {
        self.init(format: LogFormat.format(by: format), limitOutputLevel: limitOutputLevel)
    }

    /// Создает выход для логгера, направляющий все сообщений в дебаг вывод.
    /// - Parameters:
    ///   - format: формат сообщений от логгера в каком виде они будут записываться в файл.
    ///   - limitOutputLevel: Максимальный уровень сообщений, который может быть записан.
    public init(format: LogFormat, limitOutputLevel: LogLevel) {
        self.format = format
        self.limitOutputLevel = limitOutputLevel
    }

    /// :nodoc: see `LogDestination`
    open func process(_ msg: LogMessage) {
        let message = msg.string(use: format)
        // Актуально для xcode 15+ и iOS 17+
        if #available(iOS 17.0, watchOS 7.0, *) {
            let log = os.Logger(subsystem: msg.package, category: "")
            log.log(level: msg.level.osLevel, "\(message)")
        } else {
            print(message)
        }

    }
}
