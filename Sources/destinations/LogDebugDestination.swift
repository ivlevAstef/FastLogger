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
    /// :nodoc: see `LogDestination`
    public let format: String
    /// :nodoc: see `LogDestination`
    public let limitOutputLevel: LogLevel

    /// Создает выход для логгера, направляющий все сообщений в дебаг вывод.
    /// - Parameters:
    ///   - format: формат сообщений от логгера в каком виде они будут записываться в файл.
    ///   - limitOutputLevel: Максимальный уровень сообщений, который может быть записан.
    public init(format: String, limitOutputLevel: LogLevel) {
        self.format = format
        self.limitOutputLevel = .trace
    }

    /// :nodoc: see `LogDestination`
    open func process(_ msg: String, package: String, level: LogLevel) {
        // Актуально для xcode 15+ и iOS 17+
        if #available(iOS 17.0, *) {
            let log = os.Logger(subsystem: package, category: "")
            log.log(level: level.osLevel, "\(msg)")
        } else {
            print(msg)
        }

    }
}
