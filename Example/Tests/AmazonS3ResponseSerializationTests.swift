//
//  AmazonS3ResponseSerializationTests.swift
//  AmazonS3RequestManager
//
//  Created by Anthony Miller on 10/6/15.
//  Copyright © 2015 Anthony Miller. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Alamofire
import SWXMLHash

@testable import AmazonS3RequestManager

class AmazonS3ResponseSerializationTests: XCTestCase {
    
    /*
     *  MARK: - Utilities
     */
    
    class MockResponseObject: ResponseObjectSerializable {
        
        required init?(response: HTTPURLResponse, representation: XMLIndexer) {
            if representation["fail"].element !=  nil { return nil }
        }
        
    }
    
    /*
     *  MARK: XMLResponseSerializer
     */
    
    func test__XMLResponseSerializer__givenNilData_returnsFailure() {
        // given
        let expectedErrorCode = AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)._code
        
        // when
        do {
            let _ = try XMLResponseSerializer().serialize(request: nil, response: nil, data: nil, error: nil)
        } catch let error {
            // then
            expect(error._code).to(equal(expectedErrorCode))
        }
    }
    
    func test__XMLResponseSerializer__givenXMLString_returnsXMLIndexer() {
        // given
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<XMLData>" +
            "<XMLElement>test</XMLElement>" +
        "</XMLData>"
        let data = xml.data(using: String.Encoding.utf8)
        
        // when
        let result = try! XMLResponseSerializer().serialize(request: nil, response: nil, data: data, error: nil)
        let testContent = result["XMLData"]["XMLElement"].element?.text
        
        // then
        expect(testContent).to(equal("test"))
    }
    
    /*
     *  MARK: - S3DataResponseSerializer
     */
    
    func test__s3DataResponseSerializer__givenPreviousError_returnsError() {
        // given
        let data = Data(base64Encoded: "", options: .ignoreUnknownCharacters)
        let expectedError = NSError(domain: "test", code: 0, userInfo: nil)
        
        do {
            // when
            let _ = try S3DataResponseSerializer().serialize(request: nil, response: nil, data: data, error: expectedError)
        } catch let error {
            // then
            expect(error as NSError?).to(equal(expectedError))
        }
    }
    
    func test__s3DataResponseSerializer__givenNoData_returnsError() {
        // given
        let expectedError = AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        
        do {
            // when
            let _ = try S3DataResponseSerializer().serialize(request: nil, response: nil, data: nil, error: expectedError)
        } catch let error {
            // then
            expect(error._code).to(equal(expectedError._code))
        }
    }
    
    func test__s3DataResponseSerializer__givenNoError_returnsSuccessWithData() {
        // given
        let data = Data(base64Encoded: "Test Data", options: .ignoreUnknownCharacters)
        
        // when
        let result = try! S3DataResponseSerializer().serialize(request: nil, response: nil, data: data, error: nil)
        
        // then
        expect(result).to(beIdenticalTo(data))
    }
    
    func test__s3DataResponseSerializer__givenEmptyStringResponse_returnsSuccessWithData() {
        // given
        let data = Data(base64Encoded: "", options: .ignoreUnknownCharacters)
        
        // when
        let result = try! S3DataResponseSerializer().serialize(request: nil, response: nil, data: data, error: nil)
        
        // then
        expect(result).to(beIdenticalTo(data))
    }
    
    func test__s3DataResponseSerializer__givenXMLErrorStringResponse_returnsError() {
        // given
        let expectedError = S3Error.noSuchKey.error(failureReason: "The resource you requested does not exist")
        
        let xmlError = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<Error>" +
            "<Code>NoSuchKey</Code>" +
            "<Message>The resource you requested does not exist</Message>" +
            "<Resource>/mybucket/myfoto.jpg</Resource>" +
            "<RequestId>4442587FB7D0A2F9</RequestId>" +
        "</Error>"
        
        let data = xmlError.data(using: String.Encoding.utf8)
        
        do {
            // when
            let _ = try S3DataResponseSerializer().serialize(request: nil, response: nil, data: data, error: nil)
        } catch let error {
            // then
            expect(error as NSError?).to(equal(expectedError))
        }
    }
    
    func test__s3DataResponseSerializer__givenXMLErrorStringResponseAndPreviousError_returnsXMLErrorError() {
        // given
        let previousError = NSError(domain: "test", code: 0, userInfo: nil)
        let expectedError = S3Error.noSuchKey.error(failureReason: "The resource you requested does not exist")
        
        let xmlError = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<Error>" +
            "<Code>NoSuchKey</Code>" +
            "<Message>The resource you requested does not exist</Message>" +
            "<Resource>/mybucket/myfoto.jpg</Resource>" +
            "<RequestId>4442587FB7D0A2F9</RequestId>" +
        "</Error>"
        
        let data = xmlError.data(using: String.Encoding.utf8)
        
        do {
            // when
            let _ =  try S3DataResponseSerializer().serialize(request: nil, response: nil, data: data, error: previousError)
        } catch let error {
            // then
            expect(error as NSError?).to(equal(expectedError))
        }
    }
    
    /*
     *  MARK: - S3ObjectResponseSerializer
     */
    
    func test__s3ObjectResponseSerializer__givenPreviousError_returnsError() {
        // given
        let expectedError = NSError(domain: "test", code: 0, userInfo: nil)
        
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        let data = xml.data(using: String.Encoding.utf8)
        
        // when
        let result: Result<MockResponseObject> = DataRequest
            .s3ObjectResponseSerializer().serialize(nil, HTTPURLResponse(), data, expectedError)
        
        // then
        expect(result.error as NSError?).to(equal(expectedError))
    }
    
    func test__s3ObjectResponseSerializer__givenXMLRepresentation_responseObjectSerializedSuccessfully__returnsResponseObject() {
        // given
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        let data = xml.data(using: String.Encoding.utf8)
        
        // when
        let result: Result<MockResponseObject> = DataRequest
            .s3ObjectResponseSerializer().serialize(nil, HTTPURLResponse(), data, nil)
        
        // then
        expect(result.value).toNot(beNil())
    }
    
    func test__s3ObjectResponseSerializer__givenXMLRepresentation_responseObjectFailsToSerialize__returnsError() {
        // given
        let expectedErrorCode = AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)._code
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><fail>"
        let data = xml.data(using: String.Encoding.utf8)
        
        // when
        let result: Result<MockResponseObject> = DataRequest
            .s3ObjectResponseSerializer().serialize(nil, HTTPURLResponse(), data, nil)
        
        // then
        expect(result.error?._code).to(equal(expectedErrorCode))
    }
    
    func test__s3ObjectResponseSerializer__givenXMLErrorStringResponse_returnsError() {
        // given
        let expectedError = S3Error.noSuchKey.error(failureReason: "The resource you requested does not exist")
        
        let xmlError = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<Error>" +
            "<Code>NoSuchKey</Code>" +
            "<Message>The resource you requested does not exist</Message>" +
            "<Resource>/mybucket/myfoto.jpg</Resource>" +
            "<RequestId>4442587FB7D0A2F9</RequestId>" +
        "</Error>"
        
        let data = xmlError.data(using: String.Encoding.utf8)
        
        // when
        let result: Result<MockResponseObject> = DataRequest
            .s3ObjectResponseSerializer().serialize(nil, nil, data, nil)
        
        // then
        expect(result.error as NSError?).to(equal(expectedError))
    }
    
    func test__s3ObjectResponseSerializer__givenXMLErrorStringResponseAndPreviousError_returnsXMLErrorError() {
        // given
        let previousError = NSError(domain: "test", code: 0, userInfo: nil)
        let expectedError = S3Error.noSuchKey.error(failureReason: "The resource you requested does not exist")
        
        let xmlError = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<Error>" +
            "<Code>NoSuchKey</Code>" +
            "<Message>The resource you requested does not exist</Message>" +
            "<Resource>/mybucket/myfoto.jpg</Resource>" +
            "<RequestId>4442587FB7D0A2F9</RequestId>" +
        "</Error>"
        
        let data = xmlError.data(using: String.Encoding.utf8)
        
        // when
        let result: Result<MockResponseObject> = DataRequest
            .s3ObjectResponseSerializer().serialize(nil, nil, data, previousError)
        
        // then
        expect(result.error as NSError?).to(equal(expectedError))
    }
    
    /*
     *  MARK: - S3MetaDataResponseSerializer
     */
    
    func test__s3MetaDataResponseSerializer__givenPreviousError_returnsError() {
        // given
        let expectedError = NSError(domain: "test", code: 0, userInfo: nil)
        
        // when
        let result = DataRequest.s3MetaDataResponseSerializer().serialize(nil, nil, nil, expectedError)
        
        // then
        expect(result.error as NSError?).to(equal(expectedError))
    }
    
    func test__s3MetaDataResponseSerializer__givenNoError_noResponse_returnsError() {
        // given
        let expectedErrorCode = AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)._code
        
        // when
        let result = DataRequest.s3MetaDataResponseSerializer().serialize(nil, nil, nil, nil)
        
        // then
        expect(result.error?._code).to(equal(expectedErrorCode))
    }
    
    func test__s3MetaDataResponseSerializer__givenResponse_returnsSuccessWithMetaData() {
        // given
        let headers = ["x-amz-meta-test1" : "foo", "x-amz-meta-test2" : "bar"]
        let response = HTTPURLResponse(url: URL(string: "http://www.test.com")!, statusCode: 200, httpVersion: nil, headerFields: headers)
        
        // when
        let result = DataRequest.s3MetaDataResponseSerializer().serialize(nil, response, nil, nil)
        let metaDataObject = result.value
        
        // then
        expect(metaDataObject?.metaData["test1"]).to(equal("foo"))
        expect(metaDataObject?.metaData["test2"]).to(equal("bar"))
    }
    
    func test__s3MetaDataResponseSerializer__givenResponseWithNoHeaders_returnsError() {
        // given
        let failureReason = "No meta data was found."
        
        let userInfo: [String: Any] = [NSLocalizedFailureReasonErrorKey: failureReason]
        let expectedError = NSError(domain: S3Error.Domain,
                                    code: AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)._code,
                                    userInfo: userInfo)
        
        let response = HTTPURLResponse(url: URL(string: "http://www.test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // whenS
        let result = DataRequest.s3MetaDataResponseSerializer().serialize(nil, response, nil, nil)
        
        // then
        expect(result.error as NSError?).to(equal(expectedError))
    }
    
}
