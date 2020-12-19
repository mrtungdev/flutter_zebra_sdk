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

  public func onPrZplDataOverTcp(_ call: FlutterMethodCall, result: @escaping FlutterResult, _ theIpAddress: String?) {
        
    let thePrinterConn = TcpPrinterConnection(address: theIpAddress, andWithPort: 9100)
    let success = thePrinterConn?.open() ?? false
    let zplData = "^XA^FO20,20^A0N,25,25^FDThis is a ZPL test.^FS^XZ"
//    var errorData: Error? = nil
    let rep = thePrinterConn?.write(zplData.data(using: .utf8), error: nil)
    result("rep"+rep!.description+success.description)
    thePrinterConn?.close()
  }
}
