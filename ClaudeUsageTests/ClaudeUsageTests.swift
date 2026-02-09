import XCTest
@testable import ClaudeUsage

final class ClaudeUsageTests: XCTestCase {
    func testAppLaunches() throws {
        XCTAssertTrue(true)
    }

    // MARK: - UsageData Decoding Tests

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            // Fallback without fractional seconds
            let basic = ISO8601DateFormatter()
            basic.formatOptions = [.withInternetDateTime]
            if let date = basic.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }

    func testDecodeFullResponse() throws {
        let json = """
        {
            "five_hour": {"utilization": 17.0, "resets_at": "2026-02-08T18:59:59.661633+00:00"},
            "seven_day": {"utilization": 11.0, "resets_at": "2026-02-14T16:59:59.661657+00:00"},
            "seven_day_oauth_apps": null,
            "seven_day_opus": null,
            "seven_day_sonnet": {"utilization": 0.0, "resets_at": null},
            "seven_day_cowork": null,
            "iguana_necktie": null,
            "extra_usage": null
        }
        """

        let data = json.data(using: .utf8)!
        let usage = try decoder.decode(UsageData.self, from: data)

        XCTAssertEqual(usage.fiveHour.utilization, 17.0)
        XCTAssertNotNil(usage.fiveHour.resetsAt)
        XCTAssertEqual(usage.sevenDay.utilization, 11.0)
        XCTAssertNotNil(usage.sevenDay.resetsAt)
        XCTAssertNotNil(usage.sevenDaySonnet)
        XCTAssertEqual(usage.sevenDaySonnet?.utilization, 0.0)
        XCTAssertNil(usage.sevenDaySonnet?.resetsAt)
        XCTAssertNil(usage.sevenDayOpus)
        XCTAssertNil(usage.sevenDayOauthApps)
        XCTAssertNil(usage.sevenDayCowork)
        XCTAssertNil(usage.iguanaNecktie)
        XCTAssertNil(usage.extraUsage)
    }

    func testDecodeWithNullOptionalFields() throws {
        let json = """
        {
            "five_hour": {"utilization": 50.0, "resets_at": "2026-02-08T12:00:00+00:00"},
            "seven_day": {"utilization": 25.0, "resets_at": "2026-02-14T12:00:00+00:00"},
            "seven_day_oauth_apps": null,
            "seven_day_opus": null,
            "seven_day_sonnet": null,
            "seven_day_cowork": null,
            "iguana_necktie": null,
            "extra_usage": null
        }
        """

        let data = json.data(using: .utf8)!
        let usage = try decoder.decode(UsageData.self, from: data)

        XCTAssertEqual(usage.fiveHour.utilization, 50.0)
        XCTAssertEqual(usage.sevenDay.utilization, 25.0)
        XCTAssertNil(usage.sevenDaySonnet)
        XCTAssertNil(usage.sevenDayOpus)
        XCTAssertNil(usage.sevenDayOauthApps)
        XCTAssertNil(usage.sevenDayCowork)
        XCTAssertNil(usage.iguanaNecktie)
        XCTAssertNil(usage.extraUsage)
    }

    func testDecodeWithAllFieldsPresent() throws {
        let json = """
        {
            "five_hour": {"utilization": 80.0, "resets_at": "2026-02-08T18:00:00+00:00"},
            "seven_day": {"utilization": 60.0, "resets_at": "2026-02-14T18:00:00+00:00"},
            "seven_day_sonnet": {"utilization": 10.0, "resets_at": "2026-02-14T18:00:00+00:00"},
            "seven_day_opus": {"utilization": 5.0, "resets_at": "2026-02-14T18:00:00+00:00"},
            "seven_day_oauth_apps": {"utilization": 2.0, "resets_at": null},
            "seven_day_cowork": {"utilization": 3.0, "resets_at": null},
            "iguana_necktie": {"utilization": 0.0, "resets_at": null},
            "extra_usage": {"utilization": 1.0, "resets_at": null}
        }
        """

        let data = json.data(using: .utf8)!
        let usage = try decoder.decode(UsageData.self, from: data)

        XCTAssertEqual(usage.fiveHour.utilization, 80.0)
        XCTAssertEqual(usage.sevenDay.utilization, 60.0)
        XCTAssertEqual(usage.sevenDaySonnet?.utilization, 10.0)
        XCTAssertEqual(usage.sevenDayOpus?.utilization, 5.0)
        XCTAssertEqual(usage.sevenDayOauthApps?.utilization, 2.0)
        XCTAssertEqual(usage.sevenDayCowork?.utilization, 3.0)
        XCTAssertEqual(usage.iguanaNecktie?.utilization, 0.0)
        XCTAssertEqual(usage.extraUsage?.utilization, 1.0)
    }

    func testUtilizationValues() throws {
        let json = """
        {
            "five_hour": {"utilization": 17.0, "resets_at": "2026-02-08T18:59:59.661633+00:00"},
            "seven_day": {"utilization": 11.0, "resets_at": "2026-02-14T16:59:59.661657+00:00"},
            "seven_day_sonnet": {"utilization": 0.0, "resets_at": null},
            "seven_day_opus": null,
            "seven_day_oauth_apps": null,
            "seven_day_cowork": null,
            "iguana_necktie": null,
            "extra_usage": null
        }
        """

        let data = json.data(using: .utf8)!
        let usage = try decoder.decode(UsageData.self, from: data)

        XCTAssertEqual(usage.fiveHour.utilization, 17.0, accuracy: 0.001)
        XCTAssertEqual(usage.sevenDay.utilization, 11.0, accuracy: 0.001)
        XCTAssertEqual(usage.sevenDaySonnet!.utilization, 0.0, accuracy: 0.001)
    }
}

// MARK: - UsageService Tests

final class UsageServiceTests: XCTestCase {

    // MARK: - URLProtocol Mock

    private class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
        static var capturedRequest: URLRequest?

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            MockURLProtocol.capturedRequest = request

            guard let handler = MockURLProtocol.requestHandler else {
                client?.urlProtocolDidFinishLoading(self)
                return
            }

            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private var mockSession: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        MockURLProtocol.capturedRequest = nil
        MockURLProtocol.requestHandler = nil
    }

    override func tearDown() {
        mockSession = nil
        MockURLProtocol.capturedRequest = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private let sampleJSON = """
    {
        "five_hour": {"utilization": 17.0, "resets_at": "2026-02-08T18:59:59.661633+00:00"},
        "seven_day": {"utilization": 11.0, "resets_at": "2026-02-14T16:59:59.661657+00:00"},
        "seven_day_oauth_apps": null,
        "seven_day_opus": null,
        "seven_day_sonnet": {"utilization": 0.0, "resets_at": null},
        "seven_day_cowork": null,
        "iguana_necktie": null,
        "extra_usage": null
    }
    """

    // MARK: - Request Construction

    func testRequestConstruction() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.sampleJSON.data(using: .utf8)!)
        }

        let service = UsageService(sessionKey: "sk-ant-test123", orgId: "org-abc", session: mockSession)
        _ = try await service.fetchUsage()

        let captured = MockURLProtocol.capturedRequest!
        XCTAssertEqual(captured.url?.absoluteString, "https://claude.ai/api/organizations/org-abc/usage")
        XCTAssertEqual(captured.httpMethod, "GET")
        XCTAssertEqual(captured.value(forHTTPHeaderField: "accept"), "*/*")
        XCTAssertEqual(captured.value(forHTTPHeaderField: "content-type"), "application/json")
        XCTAssertEqual(captured.value(forHTTPHeaderField: "anthropic-client-platform"), "web_claude_ai")
        XCTAssertEqual(captured.value(forHTTPHeaderField: "Cookie"), "sessionKey=sk-ant-test123")
    }

    // MARK: - JSON Decoding

    func testDecodesUsageDataFromMockResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.sampleJSON.data(using: .utf8)!)
        }

        let service = UsageService(sessionKey: "sk-ant-test123", orgId: "org-abc", session: mockSession)
        let (usageData, newKey) = try await service.fetchUsage()

        XCTAssertEqual(usageData.fiveHour.utilization, 17.0, accuracy: 0.001)
        XCTAssertEqual(usageData.sevenDay.utilization, 11.0, accuracy: 0.001)
        XCTAssertNotNil(usageData.sevenDaySonnet)
        XCTAssertEqual(usageData.sevenDaySonnet?.utilization, 0.0)
        XCTAssertNil(usageData.sevenDayOpus)
        XCTAssertNil(newKey)
    }

    // MARK: - Set-Cookie Parsing

    func testSetCookieParsingExtractsNewSessionKey() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Set-Cookie": "sessionKey=sk-ant-new456; Path=/; HttpOnly; Secure"]
            )!
            return (response, self.sampleJSON.data(using: .utf8)!)
        }

        let service = UsageService(sessionKey: "sk-ant-old123", orgId: "org-abc", session: mockSession)
        let (_, newKey) = try await service.fetchUsage()

        XCTAssertEqual(newKey, "sk-ant-new456")
    }

    // MARK: - Auth Error Handling

    func testAuthError401() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = UsageService(sessionKey: "expired-key", orgId: "org-abc", session: mockSession)

        do {
            _ = try await service.fetchUsage()
            XCTFail("Expected authError to be thrown")
        } catch let error as UsageServiceError {
            XCTAssertEqual(error, .authError(statusCode: 401))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testAuthError403() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = UsageService(sessionKey: "forbidden-key", orgId: "org-abc", session: mockSession)

        do {
            _ = try await service.fetchUsage()
            XCTFail("Expected authError to be thrown")
        } catch let error as UsageServiceError {
            XCTAssertEqual(error, .authError(statusCode: 403))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
