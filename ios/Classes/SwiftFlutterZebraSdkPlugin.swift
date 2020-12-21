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
    default:
        break
    }
    result("iOS " + UIDevice.current.systemVersion)
  }

  public func onPrZplDataOverTcp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as! Dictionary<String, AnyObject>
    let theIpAddress = arguments["ip"] as! String
    let data = arguments["data"] as! String
    let thePrinterConn = TcpPrinterConnection(address: theIpAddress, andWithPort: 9100)
    let success = thePrinterConn?.open() ?? false
//    let zplData = "^XA^FO20,20^A0N,25,25^FDThis is a ZPL test.^FS^XZ"
//    var errorData: Error? = nil
    let rep = thePrinterConn?.write(data.data(using: .utf8), error: nil)
    result("rep"+rep!.description+success.description)
    thePrinterConn?.close()
  }
}
