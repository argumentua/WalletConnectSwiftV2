import Foundation

public protocol GenericPasswordConvertible {
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
    var rawRepresentation: Data { get }
}

extension String: GenericPasswordConvertible {

    enum Errors: Error {
        case notUTF8
    }

    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        let buffer = data.withUnsafeBytes { Data($0) }
        guard let string = String(data: buffer, encoding: .utf8) else {
            throw Errors.notUTF8
        }
        self = string
    }

    public var rawRepresentation: Data {
        return data(using: .utf8) ?? Data()
    }
}
