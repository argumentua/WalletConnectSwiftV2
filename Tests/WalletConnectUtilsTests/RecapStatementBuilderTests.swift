import XCTest
@testable import WalletConnectUtils

class RecapStatementBuilderTests: XCTestCase {
    func testSingleResourceKey() {
        let decodedRecap: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [],
                    "request/personal_sign": []
                ]
            ]
        ]

        let encoded = try! JSONEncoder().encode(decodedRecap).base64EncodedString()
        let urn = try! RecapUrn(urn: "urn:recap:\(encoded)")

        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'."

        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testInvertedAction() {
        let decodedRecap: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155": [
                    "request/personal_sign": [],
                    "request/eth_sendTransaction": []
                ]
            ]
        ]
        let encoded = try! JSONEncoder().encode(decodedRecap).base64EncodedString()
        let urn = try! RecapUrn(urn: "urn:recap:\(encoded)")

        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'."

        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testMultipleRecaps() {
        // First recap structure
        let decodedRecap1: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [],
                    "request/personal_sign": []
                ]
            ]
        ]

        // Second recap structure, as provided
        let decodedRecap2: [String: [String: [String: [String]]]] = [
            "att": [
                "https://example.com/pictures/": [
                    "crud/delete": [],
                    "crud/update": [],
                    "other/action": []
                ]
            ]
        ]

        // Encoding both recaps
        let encoded1 = try! JSONEncoder().encode(decodedRecap1).base64EncodedString()
        let encoded2 = try! JSONEncoder().encode(decodedRecap2).base64EncodedString()

        // Creating URNs
        let urn1 = try! RecapUrn(urn: "urn:recap:\(encoded1)")
        let urn2 = try! RecapUrn(urn: "urn:recap:\(encoded2)")

        // Expected statement combining both recaps
        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'. (2) 'crud': 'delete', 'update' for 'https://example.com/pictures/'. (3) 'other': 'action' for 'https://example.com/pictures/'."

        // Generating the recap statement from both URNs
        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn1, urn2])

        // Asserting the generated statement against the expected statement
        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testComplexRecap() {
        // JSON string
        let jsonString = """
        {
           "att":{
              "https://example.com/pictures/":{
                 "crud/delete": [{}],
                 "crud/update": [{}],
                 "other/action": [{}]
              },
              "mailto:username@example.com":{
                  "msg/receive": [{
                      "max_count": 5,
                      "templates": ["newsletter", "marketing"]
                  }],
                  "msg/send": [{"to": "someone@email.com"}, {"to": "joe@email.com"}]
              }
           },
           "prf":["bafybeigk7ly3pog6uupxku3b6bubirr434ib6tfaymvox6gotaaaaaaaaa"]
        }
        """

        // Convert JSON string to Data
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to Data")
            return
        }

        // Base64 encode the JSON data
        let base64EncodedJson = jsonData.base64EncodedString()

        // Create a URN with the encoded JSON
        let urn = try! RecapUrn(urn: "urn:recap:\(base64EncodedJson)")

        // Expected statement
        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'crud': 'delete', 'update' for 'https://example.com/pictures/'. (2) 'other': 'action' for 'https://example.com/pictures/'. (3) 'msg': 'receive', 'send' for 'mailto:username@example.com'."

        // Generating the recap statement from the URN
        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        // Asserting the generated statement against the expected statement
        XCTAssertEqual(recapStatement, expectedStatement)
    }



}
