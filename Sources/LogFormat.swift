//
//  LogFormat.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 05.10.2023.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import Foundation

/// Описывает из чего может состоять форматирование сообщения для лога.
public enum LogFormatItem {
    /// Варианты вывода даты+времени.
    public enum DateFormat {
        /// Форматирует согласно такой маске: `mm:ss.SSS`. 
        /// Для текстового представления используется `%Dd`.
        case debug
        /// Форматирует согласно такой маске: `HH:mm:ss.SSS`. 
        /// Для текстового представления используется `%Dn`.
        case nano
        ///  `yyyy-MM-dd HH:mm:ss.SSS`. 
        ///  Для текстового представления используется `%Da`.
        case any
        /// Форматирует согласно такой маске: `MM-dd HH:mm:ss`.  
        /// Для текстового представления используется `%Df`.
        case file
        /// Позволяет задать кастомный форматтер даты. Для использования в обязательном порядке надо указать верную строчку для `dateFormat` у форматтера.
        /// Текстового представления нет.
        case custom(DateFormatter)
    }

    /// Варианты вывода уровня логирования.
    public enum LevelFormat {
        /// Полный вариант названия уровня логирования заглавными буквами. "FATAL", "ASSERT", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE".
        /// Для текстового представления используется `%L`
        case long
        /// Короткий вариант названия уровня логирования. "FTL", "AST", "ERR", "WRG", "INF", "DBG", "TRC".
        /// Для текстового представления используется `%s`
        case short
        /// Эмодзи для указания уровня логирования. "🛑", "⁉️", "❗️", "⚠️", "🔹", "▶️", "🗯".
        /// Для текстового представления используется `%e`
        case emoji
    }

    /// Вывод даты+времени когда было событие.
    case date(DateFormat)
    /// Вывод уровня логирования.
    case level(LevelFormat)
    /// Вывод названия пакета, в случае если он указан.
    /// Для текстового представления используется `%p`
    case package
    /// Вывод названия файла, из которого происходит вызов функции логирования.
    /// Для текстового представления используется `%f`
    case file
    /// Вывод строчки кода, на которой происходит вызов функции логирования.
    /// Для текстового представления используется `%l`
    case line
    /// Название метода из которого вызывается вызов функции логирования.
    /// Для текстового представления используется `%M`
    case method

    /// Сообщение которое было передано в функцию логирования.
    /// Для текстового представления используется `%m`
    case message

    /// Кастомная строка. Используется для добавления пробелов и других символов.
    /// В текстовом представлении это просто символы которые не попали под другие категории.
    case string(String)
}

public typealias LogFormat = [LogFormatItem]

extension LogFormat {
    /// Генерирует описание формата по текстовому представлению.
    public static func format(by string: String) -> LogFormat {
        let characters = string.map { "\($0)" }

        var result: [LogFormatItem] = []
        var cacheStr: String = ""
        var index = 0
        while index < characters.count {
            func getFormat() -> (item: LogFormatItem, size: Int)? {
                if characters[index] == "%" && index + 1 < characters.count {
                    switch characters[index+1] {
                    case "D":
                        if index + 2 < characters.count {
                            switch characters[index+2] {
                            case "d": return (.date(.debug), 2)
                            case "n": return (.date(.nano), 2)
                            case "a": return (.date(.any), 2)
                            case "f": return (.date(.file), 2)
                            default: return nil
                            }
                        }
                        return nil
                    case "L": return (.level(.long), 1)
                    case "s": return (.level(.short), 1)
                    case "e": return (.level(.emoji), 1)
                    case "p": return (.package, 1)
                    case "f": return (.file, 1)
                    case "l": return (.line, 1)
                    case "M": return (.method, 1)
                    case "m": return (.message, 1)
                    default: return nil
                    }
                }
                return nil
            }

            if let (item, offset) = getFormat() {
                if !cacheStr.isEmpty {
                    result.append(.string(cacheStr))
                    cacheStr = ""
                }
                result.append(item)
                index += 1 + offset
            } else {
                cacheStr += characters[index]
                index += 1
            }
        }

        if !cacheStr.isEmpty {
            result.append(.string(cacheStr))
        }

        return result
    }
}
