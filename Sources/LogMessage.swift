//
//  LogMessage.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 05.10.2023.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import Foundation

/// Класс содержит полную информацию о сообщении, и позволяет её отформатировать по указанному формату.
public final class LogMessage: @unchecked Sendable {
    public let level: LogLevel
    public let package: String
    public let path: StaticString
    public let line: UInt
    public let method: StaticString
    public let date: Date
    public let msg: String

    public private(set) lazy var file: String = {
        return ("\(path)" as NSString).lastPathComponent
    }()

    internal init(level: LogLevel, package: String, path: StaticString, line: UInt, method: StaticString, date: Date, msg: String) {
        self.level = level
        self.package = package
        self.path = path
        self.line = line
        self.method = method
        self.date = date
        self.msg = msg
    }

    /// Форматирует сообщение согласно указанному формату.
    public func string(use format: LogFormat) -> String {
        var result: String = ""

        for item in format {
            switch item {
            case .date(let dateFormat):
                switch dateFormat {
                case .debug: result += debugFormatter.string(from: date)
                case .nano: result += nanoFormatter.string(from: date)
                case .any: result += anyFormatter.string(from: date)
                case .file: result += fileFormatter.string(from: date)
                case .custom(let formatter): result += formatter.string(from: date)
                }
            case .level(let levelFormat):
                switch levelFormat {
                case .long: result += level.name
                case .short: result += level.shortName
                case .emoji: result += level.emoji
                }
            case .package: result += package
            case .file: result += file
            case .line: result += "\(line)"
            case .method: result += "\(method)"
            case .message: result += msg
            case .string(let str): result += str
            }
        }

        return result
    }
}

private let debugFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    return formatter
}()
private let nanoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()
private let anyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()
private let fileFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm:ss"
    return formatter
}()


extension LogLevel {
    fileprivate var name: String {
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

    fileprivate var shortName: String {
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

    fileprivate var emoji: String {
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
