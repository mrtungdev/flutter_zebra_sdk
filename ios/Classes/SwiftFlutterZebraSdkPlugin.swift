import Flutter
import UIKit
import ExternalAccessory

public class SwiftFlutterZebraSdkPlugin: NSObject, FlutterPlugin {
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_zebra_sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterZebraSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "printZPLOverTCPIP":
            onPrZplDataOverTcp(call, result: result)
            break
        case "onDiscovery":
            onDiscovery(call, result: result)
            break
        case "onGetPrinterInfo":
            onGetPrinterInfo(call, result: result)
            break
        case "isPrinterConnected":
            isPrinterConnected(call, result: result)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    public func createTCPConnection(ipAddress: String, port: Int) -> TcpPrinterConnection{
        return TcpPrinterConnection(address: ipAddress, andWithPort: port)
    }
    
    public func onPrZplDataOverTcp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var resp = ZebreResult()
        do {
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let ipAddr = arguments["ip"] as! String
            let data = arguments["data"] as! String
            let port = arguments["port"] as? Int
            let printPort = port ?? 9100
            let conn = createTCPConnection(ipAddress: ipAddr, port: printPort)
            conn.open()
            let rep = conn.write(data.data(using: .utf8), error: nil)
            conn.close()
            resp.message = "Successfully!"
            resp.success = true
            resp.content = rep.description;
            let respJson = try resp.jsonString()
            result(respJson)
        } catch{
            debugPrint("Unexpected error: \(error).")
            result(FlutterError.init(code: "ON_PRINT_ZPL_DATA_OVER_TCP", message: error.localizedDescription, details: nil))
        }
    }
    
    public func onDiscovery(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var resp = ZebreResult()
        do {
            let printers = try NetworkDiscoverer.localBroadcast()
            debugPrint("Printers found: \(printers).")
            var printerArr: [ZebraPrinterInfo] = []
            for printer in printers {
                let priObj = printer as! DiscoveredPrinterNetwork
                var zebraInfo = ZebraPrinterInfo()
                zebraInfo.address = priObj.toString()
                zebraInfo.jsonPortNumber = priObj.port
                zebraInfo.productName = priObj.dnsName
                debugPrint("Printer Info: \(zebraInfo).")
                printerArr.append(zebraInfo)
            }
            let printerEncode = try JSONEncoder().encode(printerArr)
            let printJSON = String(bytes: printerEncode, encoding: .utf8)
            
            resp.success = true
            resp.message = "Successfully!"
            resp.content = printJSON
            let respJson = try resp.jsonString()
            result(respJson)
        } catch{
            debugPrint("Unexpected error: \(error).")
            result(FlutterError.init(code: "ON_DISCOVERY", message: error.localizedDescription, details: nil))
        }
    }
    
    public func isPrinterConnected(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var resp = ZebreResult()
        do {
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let ipAddr = arguments["ip"] as! String
            let port = arguments["port"] as? Int
            let printPort = port ?? 9100
            let conn = createTCPConnection(ipAddress: ipAddr, port: printPort)
            conn.open()
            let isConnected = conn.isConnected()
            resp.success = isConnected;
            resp.message = isConnected ? "Connected!" : "Unconnected"
            let respJson = try resp.jsonString()
            result(respJson)
        } catch{
            debugPrint("Unexpected error: \(error).")
            result(FlutterError.init(code: "ON_PRINT_ZPL_DATA_OVER_TCP", message: error.localizedDescription, details: nil))
        }
    }
    
    private func onGetPrinterInfoByIP(ipAddr: String, port: Int) -> ZebraPrinterInfo {
        var zeb = ZebraPrinterInfo()
        let disPrint = DiscoveredPrinterNetwork(address: ipAddr, andWithPort: port)
        zeb.address = disPrint?.toString()
        zeb.productName = disPrint?.dnsName
        zeb.jsonPortNumber = port
        return zeb
    }
    
    public func onGetPrinterInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var resp = ZebreResult()
        do {
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let ipAddr = arguments["ip"] as! String
            let port = arguments["port"] as? Int
            let printPort = port ?? 9100
            let zebra = onGetPrinterInfoByIP(ipAddr: ipAddr, port: printPort)
            if(zebra.address != nil){
                let zebraJson = try zebra.jsonString()
                resp.success = true;
                resp.message = "Successfully!"
                resp.content = zebraJson
            } else {
                resp.success = false;
                resp.message = "Printer is not connect or available."
            }
            let respJson = try resp.jsonString()
            result(respJson)
        } catch{
            debugPrint("Unexpected error: \(error).")
            result(FlutterError.init(code: "ON_PRINT_ZPL_DATA_OVER_TCP", message: error.localizedDescription, details: nil))
        }
    }

}


struct ZebraPrinterInfo: Codable {
    var address: String?
    var availableInterfaces, availableLanguages: [String]?
    var darkness, jsonPortNumber: Int?
    var firmwareVer: String?
    var linkOSMajorVer: Int?
    var primaryLanguage, productName, serialNumber: String?
}

// MARK: ZebraPrinterInfo convenience initializers and mutators

extension ZebraPrinterInfo {
    init(data: Data) throws {
        let me = try newJSONDecoder().decode(ZebraPrinterInfo.self, from: data)
        self.init(address: me.address, availableInterfaces: me.availableInterfaces, availableLanguages: me.availableLanguages, darkness: me.darkness, jsonPortNumber: me.jsonPortNumber, firmwareVer: me.firmwareVer, linkOSMajorVer: me.linkOSMajorVer, primaryLanguage: me.primaryLanguage, productName: me.productName, serialNumber: me.serialNumber)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        address: String?? = nil,
        availableInterfaces: [String]?? = nil,
        availableLanguages: [String]?? = nil,
        darkness: Int?? = nil,
        jsonPortNumber: Int?? = nil,
        firmwareVer: String?? = nil,
        linkOSMajorVer: Int?? = nil,
        primaryLanguage: String?? = nil,
        productName: String?? = nil,
        serialNumber: String?? = nil
    ) -> ZebraPrinterInfo {
        return ZebraPrinterInfo(
            address: address ?? self.address,
            availableInterfaces: availableInterfaces ?? self.availableInterfaces,
            availableLanguages: availableLanguages ?? self.availableLanguages,
            darkness: darkness ?? self.darkness,
            jsonPortNumber: jsonPortNumber ?? self.jsonPortNumber,
            firmwareVer: firmwareVer ?? self.firmwareVer,
            linkOSMajorVer: linkOSMajorVer ?? self.linkOSMajorVer,
            primaryLanguage: primaryLanguage ?? self.primaryLanguage,
            productName: productName ?? self.productName,
            serialNumber: serialNumber ?? self.serialNumber
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ZebreResult
struct ZebreResult: Codable {
    var type: String?
    var success: Bool?
    var message, content: String?
}

// MARK: ZebreResult convenience initializers and mutators

extension ZebreResult {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ZebreResult.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        type: String?? = nil,
        success: Bool?? = nil,
        message: String?? = nil,
        content: String?? = nil
    ) -> ZebreResult {
        return ZebreResult(
            type: type ?? self.type,
            success: success ?? self.success,
            message: message ?? self.message,
            content: content ?? self.content
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}


// MARK: - Helper functions for creating encoders and decoders
func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
