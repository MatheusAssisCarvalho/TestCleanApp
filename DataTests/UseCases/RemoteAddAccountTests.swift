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
        expect(sut, completeWith: .failure(.unexpected), when: {
            httpClientSpy.completeWithError(.noConnectivity)
        })
    }
    
    func test_add_should_complete_with_error_if_client_completes_with_data() {
        let (sut, httpClientSpy) = makeSut()
        let account = makeAcountModel()
        expect(sut, completeWith: .success(account), when: {
            httpClientSpy.completeWithData(account.toData()!)
        })
        
    }
    
    func test_add_should_complete_with_error_if_client_completes_with_invalid_data() {
        let (sut, httpClientSpy) = makeSut()
        expect(sut, completeWith: .failure(.unexpected), when: {
            httpClientSpy.completeWithData(Data("invalid data".utf8))
        })
        
    }
}

extension RemoteAddAccountTests {
    func makeSut(url: URL = URL(string: "http://any-url.com")!) -> (sut: RemoteAddAccount, httpClientSpy: HttpClientSpy) {
        let httpClientSpy = HttpClientSpy()
        let sut = RemoteAddAccount(url: url, httpPostClient: httpClientSpy)
        return (sut, httpClientSpy)
    }
    
    func expect(_ sut: RemoteAddAccount, completeWith expectedResult: Result<AccountModel, DomainError>, when action: () -> Void) {
        let exp = expectation(description: "waiting")
        sut.add(addAccountModel: makeAddAcountModel()) { receivedResult in
            switch (expectedResult, receivedResult) {
            case (.failure(let expectedError), .failure(let receivedError)): XCTAssertEqual(expectedError, receivedError)
            case (.success(let expectedAccount), .success(let receivedAccount)): XCTAssertEqual(expectedAccount, receivedAccount)
                
            default: XCTFail("Expected \(expectedResult) receivedResult \(receivedResult) instead")
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1)
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
