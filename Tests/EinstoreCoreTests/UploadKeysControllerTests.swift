//
//  ApiKeyTests.swift
//  EinstoreCoreTests
//
//  Created by Ondrej Rafaj on 04/03/2018.
//

import XCTest
import Vapor
import VaporTestTools
import FluentTestTools
import ApiCoreTestTools
import EinstoreCoreTestTools
@testable import ApiCore
@testable import EinstoreCore


class ApiKeysControllerTests: XCTestCase, ApiKeyTestCaseSetup, LinuxTests {
    
    var app: Application!
    
    var user1: User!
    var user2: User!
    
    var adminTeam: Team!
    var team1: Team!
    var team2: Team!
    
    var key1: ApiKey!
    var key2: ApiKey!
    var key3: ApiKey!
    var key4: ApiKey!
    
    var team4: Team!
    
    
    // MARK: Linux
    
    static let allTests: [(String, Any)] = [
        ("testGetApiKeysForUser", testGetApiKeysForUser),
        ("testGetApiKeysForTeam", testGetApiKeysForTeam),
        ("testCreateApiKey", testCreateApiKey),
        ("testChangeApiKeyName", testChangeApiKeyName),
        ("testDeleteApiKey", testDeleteApiKey),
        ("testGetOneApiKey", testGetOneApiKey),
        ("testLinuxTests", testLinuxTests)
    ]
    
    func testLinuxTests() {
        doTestLinuxTestsAreOk()
    }
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        app = Application.testable.newBoostTestApp()
        
        app.testable.delete(allFor: Token.self)
        
        setupApiKeys()
    }
    
    // MARK: Tests
    
    func testGetApiKeysForUser() {
        let req = HTTPRequest.testable.get(uri: "/keys", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let keys = r.response.testable.content(as: [ApiKey.Display].self)!
        
        XCTAssertEqual(keys.count, 3, "There should be right amount of keys for the user")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testGetApiKeysForTeam() {
        let req = HTTPRequest.testable.get(uri: "/teams/\(team1.id!.uuidString)/keys", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let keys = r.response.testable.content(as: [ApiKey.Display].self)!
        
        XCTAssertEqual(keys.count, 2, "There should be right amount of keys for the team")
        
        keys.forEach { (key) in
            XCTAssertEqual(key.teamId, team1.id!, "Team ID doesn't match")
        }
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testCreateApiKey() {
        // Test setup
        var count = app.testable.count(allFor: ApiKey.self)
        XCTAssertEqual(count, 4, "There should be two team entries in the db at the beginning")
        
        // Execute request
        let expiryDate = Date(timeIntervalSince1970: 23412342342)
        let post = ApiKey.New(name: "new key", type: 0, expires: expiryDate)
        let postData = try! post.asJson()
        let req = HTTPRequest.testable.post(uri: "/teams/\(team1.id!.uuidString)/keys", data: postData, headers: [
            "Content-Type": "application/json; charset=utf-8"
            ] , authorizedUser: user1, on: app
        )
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let key = r.response.testable.content(as: ApiKey.self)!
        let privateKey = UUID(uuidString: key.token)
        
        XCTAssertNotNil(privateKey, "Token should have been created properly")
        XCTAssertEqual(key.teamId, team1.id!, "Team ID doesn't match")
        XCTAssertEqual(key.expires, expiryDate, "Team Expity doesn't match")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .created), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
        
        count = app.testable.count(allFor: ApiKey.self)
        XCTAssertEqual(count, 5, "There should be two team entries in the db at the beginning")
    }
    
    func testChangeApiKeyName() {
        let expiryDate = Date(timeIntervalSince1970: 20000042342)
        let post = ApiKey.New(name: "updated key", type: 0, expires: expiryDate)
        let postData = try! post.asJson()
        let req = HTTPRequest.testable.put(uri: "/keys/\(key1.id!.uuidString)", data: postData, headers: [
            "Content-Type": "application/json; charset=utf-8"
            ] , authorizedUser: user1, on: app
        )
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let key = app.testable.one(for: ApiKey.self, id: key1.id!)!
        
        XCTAssertEqual(key.name, post.name, "Name hasn't been updated")
        
        let formatter = DateFormatter()
        
        XCTAssertEqual(formatter.string(from: key.expires!), formatter.string(from: post.expires!), "Expiry date hasn't been updated")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testDeleteApiKey() {
        var count = app.testable.count(allFor: ApiKey.self)
        XCTAssertEqual(count, 4, "There should be two team entries in the db at the beginning")
        
        let req = HTTPRequest.testable.delete(uri: "/keys/\(key2.id!.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        XCTAssertTrue(r.response.testable.has(statusCode: .noContent), "Wrong status code")
        
        app.testable.all(for: ApiKey.self).forEach { (key) in
            XCTAssertNotEqual(key.id!, key2.id!, "Key has not been deleted")
        }
        
        count = app.testable.count(allFor: ApiKey.self)
        XCTAssertEqual(count, 3, "There should be two team entries in the db at the end")
    }
    
    func testGetOneApiKey() {
        let req = HTTPRequest.testable.get(uri: "/keys/\(key4.id!.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let key = r.response.testable.content(as: ApiKey.Display.self)!
        
        XCTAssertEqual(key.id!, key4.id!, "Key has not been retrieved")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
}


