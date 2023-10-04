//
//  LogFileDestination.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 23.09.2023.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import Foundation

/// Позволяет записывать сообщения от логгера в файл, по указанному URL.
open class LogFileDestination: LogDestination {
    /// Указанный формат логирования при инициализации.
    public let format: LogFormat
    /// :nodoc: see `LogDestination`
    public let limitOutputLevel: LogLevel

    private let fileHandler: FileHandle

    /// Создает выход для логгера, направляющий все сообщений в файл.
    /// - Parameters:
    ///   - format: формат, в текстовом представлении, сообщений от логгера в каком виде они будут записываться в файл.
    ///   - limitOutputLevel: Максимальный уровень сообщений, который может быть записан.
    ///   - fileUrl: URL файла куда будут записываться сообщения.
    public convenience init?(format: String, limitOutputLevel: LogLevel, fileUrl: URL) {
        self.init(format: LogFormat.format(by: format), limitOutputLevel: limitOutputLevel, fileUrl: fileUrl)
    }

    /// Создает выход для логгера, направляющий все сообщений в файл.
    /// - Parameters:
    ///   - format: формат сообщений от логгера в каком виде они будут записываться в файл.
    ///   - limitOutputLevel: Максимальный уровень сообщений, который может быть записан.
    ///   - fileUrl: URL файла куда будут записываться сообщения.
    public init?(format: LogFormat, limitOutputLevel: LogLevel, fileUrl: URL) {
        self.format = format
        self.limitOutputLevel = limitOutputLevel

        let attributes: [FileAttributeKey: Any] = [
            FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        if !FileManager.default.createFile(atPath: fileUrl.path, contents: nil, attributes: attributes) {
            return nil
        }

        guard let handler = try? FileHandle(forWritingTo: fileUrl) else {
            return nil
        }

        self.fileHandler = handler
    }

    deinit {
        self.fileHandler.synchronizeFile()
        self.fileHandler.closeFile()
    }

    /// :nodoc: see `LogDestination`
    open func process(_ msg: LogMessage) {
        guard let data = "\(msg.string(use: format))\n".data(using: .utf8) else {
            return
        }

        fileHandler.write(data)
    }

}
