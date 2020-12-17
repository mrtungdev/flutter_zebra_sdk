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
    result("iOS " + UIDevice.current.systemVersion)
  }

  public func sendZplOverTcp(_ call: FlutterMethodCall, result: @escaping FlutterResult, _ theIpAddress: String?) {

//    weak var thePrinterConn = TcpPrinterConnection(address: theIpAddress, andWithPort: 9100) as? (ZebraPrinterConnection & NSObjectProtocol)
//    var success = thePrinterConn?.open() ?? false
//    let zplData = "^XA^FO20,20^A0N,25,25^FDThis is a ZPL test.^FS^XZ"
//    var error: Error? = nil
//    success = success && thePrinterConn?.write(zplData.data(using: .utf8), error: &error) != nil
//    if success != true || error != nil {
//        result("OK")
//    }
//    thePrinterConn?.close()
  }
}
