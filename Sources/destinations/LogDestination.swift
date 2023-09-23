//
//  LogDestination.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 22/02/2019.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

/// Протокол от которого должны наследоваться все потоки вывода.
public protocol LogDestination: AnyObject {
    /// формат:
    /// %Dx - вывод даты варианты:
    ///   %Dd (debug) - mm:ss.SSS
    ///   %Dn (nano) - HH:mm:ss.SSS
    ///   %Da (any) - yyyy-MM-dd HH:mm:ss.SSS
    ///   %Df (file) - MM-dd HH:mm:ss
    /// %L - (long) вывод уровня логирования
    /// %s - (short) вывод уровня логирования в коротком варианте
    /// %e - (emoji) вывод уровня логирования используя emoji
    /// %F - (file) вывод имени файла
    /// %l - (line) вывод строчки
    /// %M - (method) вывод метода
    /// %m - (message) вывод сообщения
    /// %p - (package) вывод названия модуля
    var format: String { get }

    /// Максимально допустимый уровень логирования - выше этого уровня логи не будут приходить в функцию process.
    var limitOutputLevel: LogLevel { get }

    /// Обработчик нового сообщения от логгера. Сообщение приходит в конечном варианте - отформатированным.
    ///
    /// - Parameters:
    ///   - msg: Отформатированное сообщение.
    ///   - package: Имя модуля\пакета из которого идет логирование.
    ///   - level: Уровень логирования для этого сообщения.
    func process(_ msg: String, package: String, level: LogLevel)
}
