//
//  SocPingError.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Foundation

enum SocPingError: Error {
    case NoHostValue
    case AlreadyAddressExist
    case ReservedAddress
    case AddressExceeded
    case DontDeleteAny
    case UnexpectedRevents(events: Int32)
    case DeviceNotAvail
    case NoValue
    case InvalidValue
    case CantOpenURL
    case InternalError
}

extension SocPingError: LocalizedError {
    var message: String {
        switch self {
        case .NoHostValue: return NSLocalizedString("Message_NoHostValue", comment: "")
        case .AlreadyAddressExist: return NSLocalizedString("Message_AlreadyAddressExist", comment: "")
        case .ReservedAddress: return NSLocalizedString("Message_ReservedAddress", comment: "")
        case .AddressExceeded: return NSLocalizedString("Message_AddressExceeded", comment: "")
        case .DontDeleteAny: return NSLocalizedString("Message_DontDeleteAny", comment: "")
        case .UnexpectedRevents(let events): return NSLocalizedString("Message_UnexpectedRevents", comment: "") + SocLogger.getEventsMask(events)
        case .DeviceNotAvail: return NSLocalizedString("Message_DeviceNotAvail", comment: "")
        case .NoValue: return NSLocalizedString("Message_NoValue", comment: "")
        case .InvalidValue: return NSLocalizedString("Message_InvalidValue", comment: "")
        case .CantOpenURL: return NSLocalizedString("Message_CantOpenURL", comment: "")
        default: return NSLocalizedString("Message_InternalError", comment: "")
        }
    }
}
