//
//  LogDestination.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 22/02/2019.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

/// Протокол от которого должны наследоваться все потоки вывода.
public protocol LogDestination: AnyObject {
    /// Максимально допустимый уровень логирования - выше этого уровня логи не будут приходить в функцию process.
    var limitOutputLevel: LogLevel { get }

    /// Обработчик нового сообщения от логгера.
    ///
    /// - Parameters:
    ///   - message: Полная информация о сообщение от логгера - где, когда, и почему. При необходимости можно отформатировать в обычную строку.
    func process(_ message: LogMessage)
}
