import Flutter
import UIKit
import ExternalAccessory


struct ZebreResult: Codable {
    var type: String?
    var success: Bool?
    var message: String?
    var content: String?
}

struct ZebraPrinterInfo: Codable {
    var address: String?
    var availableInterfaces, availableLanguages: [String]?
    var darkness, firmwareVer: String?
    var jsonPortNumber: Int
    var linkOSMajorVer: String?
    var primaryLanguage, productName, serialNumber: String?
}


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
//        case "onGetPrinterInfo":
//            onGetPrinterInfo(call, result: result)
//            break
        default:
            break
        }
        result("iOS " + UIDevice.current.systemVersion)
    }
    
    public func createTCPConnection(ipAddress: String, port: Int) -> TcpPrinterConnection{
        return TcpPrinterConnection(address: ipAddress, andWithPort: port)
    }
    
    public func onPrZplDataOverTcp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        let ipAddr = arguments["ip"] as! String
        let data = arguments["data"] as! String
//        let conn = createTCPConnection(ipAddress: ipAddr, port: 9100)
        let thePrinterConn = TcpPrinterConnection(address: ipAddr, andWithPort: 9100)
        let success = thePrinterConn?.open() ?? false
        //    let zplData = "^XA^FO20,20^A0N,25,25^FDThis is a ZPL test.^FS^XZ"
        //    var errorData: Error? = nil
        let rep = thePrinterConn?.write(data.data(using: .utf8), error: nil)
        result("rep"+rep!.description+success.description)
        thePrinterConn?.close()
    }
    
    public func onDiscovery(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let info = Dictionary<String,AnyObject>()
            let printers = try NetworkDiscoverer.localBroadcast()
            debugPrint("printers: \(printers).")
            for printer in printers {
                let priObj = printer as! DiscoveredPrinterNetwork
                let zebraPrinterInfo = ZebraPrinterInfo(address: priObj.toString(), jsonPortNumber: priObj.port, productName: priObj.dnsName)
                let zInfo = onGetPrinterInfoByIP(ipAddr: priObj.toString())
                debugPrint("zebraPrinterInfo: \(zebraPrinterInfo).")
            }
            result(info)
        } catch{
            debugPrint("Unexpected error: \(error).")
        }
    }
    
    private func onGetPrinterInfoByIP(ipAddr: String) -> AnyObject {
        do {
            let conn = createTCPConnection(ipAddress: ipAddr, port: 9100)
            conn.open()
            let a = try conn.read()
            debugPrint("a: \(a).")
            return a as AnyObject
        } catch{
            debugPrint("Unexpected error: \(error).")
        }
        return "A" as AnyObject
    }
}
