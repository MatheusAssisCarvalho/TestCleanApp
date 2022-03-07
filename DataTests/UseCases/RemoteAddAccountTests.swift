import XCTest
import Domain
import Data


class RemoteAddAccountTests: XCTestCase {
    func test_add_should_call_httpClient_with_correct_url() {
        let url = URL(string: "http://any-url.com")!
        let (sut, httpClientSpy) = makeSut(url: url)
        sut.add(addAccountModel: makeAddAcountModel()) { _ in }
        
        XCTAssertEqual(httpClientSpy.urls, [url])
    }
    
    func test_add_should_call_httpClient_with_correct_data() {
        let (sut, httpClientSpy) = makeSut()
        let addAccountModel = makeAddAcountModel()
        sut.add(addAccountModel: addAccountModel) { _ in }
        let data = try? JSONEncoder().encode(addAccountModel)
        
        XCTAssertEqual(httpClientSpy.data, data)
    }
    
    func test_add_should_complete_with_error_if_client_completes_with_error() {
        let (sut, httpClientSpy) = makeSut()
        let exp = expectation(description: "waiting")
        sut.add(addAccountModel: makeAddAcountModel()) { result in
            switch result {
            case .failure(let error): XCTAssertEqual(error, .unexpected)
            case .success: XCTFail("Expected error receive success instead")
            }
            exp.fulfill()
        }
        httpClientSpy.completeWithError(.noConnectivity)
        wait(for: [exp], timeout: 1)
        
    }
    
    func test_add_should_complete_with_error_if_client_completes_with_data() {
        let (sut, httpClientSpy) = makeSut()
        let exp = expectation(description: "waiting")
        let expectedAccount = makeAcountModel()
        sut.add(addAccountModel: makeAddAcountModel()) { result in
            switch result {
            case .failure: XCTFail("Expected error receive failure instead")
            case .success(let receivedAccount): XCTAssertEqual(receivedAccount, expectedAccount)
            }
            exp.fulfill()
        }
        httpClientSpy.completeWithData(expectedAccount.toData()!)
        wait(for: [exp], timeout: 1)
        
    }
    
    func test_add_should_complete_with_error_if_client_completes_with_invalid_data() {
        let (sut, httpClientSpy) = makeSut()
        let exp = expectation(description: "waiting")
        sut.add(addAccountModel: makeAddAcountModel()) { result in
            switch result {
            case .failure(let error): XCTAssertEqual(error, .unexpected)
            case .success: XCTFail("Expected error receive success instead")
            }
            exp.fulfill()
        }
        httpClientSpy.completeWithData(Data("invalid data".utf8))
        wait(for: [exp], timeout: 1)
        
    }
}

extension RemoteAddAccountTests {
    func makeSut(url: URL = URL(string: "http://any-url.com")!) -> (sut: RemoteAddAccount, httpClientSpy: HttpClientSpy) {
        let httpClientSpy = HttpClientSpy()
        let sut = RemoteAddAccount(url: url, httpPostClient: httpClientSpy)
        return (sut, httpClientSpy)
    }
    
    func makeAddAcountModel() -> AddAccountModel {
        return AddAccountModel(name: "Nome legal", email: "emailLegal@estudo.com", password: "22930293", passwordConfirmation: "22930293")
    }
    
    func makeAcountModel() -> AccountModel {
        return AccountModel(id: "um id", name: "Nome legal", email: "emailLegal@estudo.com", password: "22930293")
    }
    
    class HttpClientSpy: HttpPostClient {
        var urls = [URL]()
        var data: Data?
        var completion: ((Result<Data, HttpError>) -> Void)?
        
        func post(to url: URL, with data: Data?, completion: @escaping (Result<Data, HttpError>) -> Void) {
            self.urls.append(url)
            self.data = data
            self.completion = completion
        }
        
        func completeWithError (_ error: HttpError) {
            completion?(.failure(.noConnectivity))
        }
        func completeWithData (_ data: Data) {
            completion?(.success(data))
        }
    }
}
