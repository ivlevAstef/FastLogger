//
//  LogLevel+osLog.swift
//  FastLogger
//
//  Created by Alexander Ivlev on 23.09.2023.
//  Copyright © 2023 Alexander Ivlev. All rights reserved.
//

import OSLog

extension LogLevel {
    var osLevel: OSLogType {
        switch self {
        case .none: return .default
        case .fatal: return .fault
        case .assert: return .fault
        case .error: return .error
        case .warning: return .error
        case .info: return .info
        case .debug: return .debug
        case .trace: return .debug
        }
    }
}
