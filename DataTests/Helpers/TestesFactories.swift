
import Foundation


func makeInvalidData() -> Data {
    return Data("invalid data".utf8)
}

func makeValidData() -> Data {
    return Data("{\"name\":\"Matheus\"}".utf8)
}

func makeUrl() -> URL {
    return URL(string: "http://any-url.com")!
}

func makeError() -> Error {
    return NSError(domain: "any_error", code: 0)
}

