package com.tlt.flutter_zebra_sdk

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.zebra.sdk.comm.BluetoothConnectionInsecure
import com.zebra.sdk.comm.Connection
import com.zebra.sdk.comm.ConnectionException
import com.zebra.sdk.comm.TcpConnection
import com.zebra.sdk.printer.discovery.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** FlutterZebraSdkPlugin */
class FlutterZebraSdkPlugin : FlutterPlugin, MethodCallHandler {
  // / The MethodChannel that will the communication between Flutter and native Android
  // /
  // / This local reference serves to register the plugin with the Flutter Engine and unregister it
  // / when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private var logTag: String = "ZebraSDK"
  var printers: MutableList<DiscoveredPrinter> = ArrayList()
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_zebra_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull rawResult: Result) {
    val result: MethodResultWrapper = MethodResultWrapper(rawResult)
    Thread(MethodRunner(call, result)).start()
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  inner class MethodRunner(call: MethodCall, result: Result) : Runnable, DiscoveryHandler {
    private val call: MethodCall = call
    private val result: Result = result

    override fun run() {
      when (call.method) {
        "printZPLOverTCPIP" -> {
          onPrintZPLOverTCPIP(call, result)
        }
        "printZPLOverBluetooth" -> {
          onPrintZplDataOverBluetooth(call, result)
        }
        "onDiscovery" -> {
          onDiscovery(call, result)
        }
        "onGetPrinterInfo" -> {
          onGetPrinterInfo(call, result)
        }
        else -> result.notImplemented()
      }
    }

    override fun foundPrinter(p0: DiscoveredPrinter) {
      Log.d(logTag, "foundPrinter $p0")
      printers.add(p0)
    }

    override fun discoveryFinished() {
      Log.d(logTag, "discoveryFinished $printers")
      var res = { printers }
      result.success(res)
    }

    override fun discoveryError(p0: String?) {
      Log.d(logTag, "discoveryError $p0")
      result.error("discoveryError", "discoveryError", p0)
    }
  }

  class MethodResultWrapper(methodResult: Result) : Result {

    private val methodResult: Result = methodResult
    private val handler: Handler = Handler(Looper.getMainLooper())

    public override fun success(result: Any?) {
      handler.post { methodResult.success(result) }
    }

    public override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
      handler.post { methodResult.error(errorCode, errorMessage, errorDetails) }
    }

    public override fun notImplemented() {
      handler.post { methodResult.notImplemented() }
    }
  }

  private fun createTcpConnect(ip: String, port: Int): TcpConnection {
    return TcpConnection(ip, port)
  }

  private fun onPrintZPLOverTCPIP(@NonNull call: MethodCall, @NonNull result: Result) {
    var ipE: String? = call.argument("ip")
    var data: String? = call.argument("data")
    var rep = HashMap<String, Any>()
    var ipAddress: String = ""
    if(ipE != null){
      ipAddress = ipE
    } else {
      result.error("PrintZPLOverTCPIP", "IP Address is required", "Data Content")
      return
    }
    val conn: Connection = createTcpConnect(ipAddress, TcpConnection.DEFAULT_ZPL_TCP_PORT)
    Log.d(logTag, "onPrintZPLOverTCPIP $ipAddress $data ${TcpConnection.DEFAULT_ZPL_TCP_PORT}")
    if (data == null) {
      result.error("PrintZPLOverTCPIP", "Data is required", "Data Content")
    }
    try {
      // Open the connection - physical connection is established here.
      conn.open()
      // Send the data to printer as a byte array.
      conn.write(data?.toByteArray())
      rep["success"] = true
      rep["message"] = "Successfully!"
      result.success(rep)
    } catch (e: ConnectionException) {
      // Handle communications error here.
      e.printStackTrace()
      result.error("Error", "onPrintZPLOverTCPIP", e)
    } finally {
      // Close the connection to release resources.
      conn.close()
    }
  }

  private fun onPrintZplDataOverBluetooth(@NonNull call: MethodCall, @NonNull result: Result) {
    var macAddress: String? = call.argument("mac")
    var data: String? = call.argument("data")
    Log.d(logTag, "onPrintZplDataOverBluetooth $macAddress $data")
    if (data == null) {
      result.error("onPrintZplDataOverBluetooth", "Data is required", "Data Content")
    }
    try {
      // Instantiate insecure connection for given Bluetooth&reg; MAC Address.
      val conn: Connection = BluetoothConnectionInsecure(macAddress, 5000, 0)

      // Initialize
      Looper.prepare()

      // Open the connection - physical connection is established here.
      conn.open()

      // Send the data to printer as a byte array.
      conn.write(data?.toByteArray())

      // Make sure the data got to the printer before closing the connection
      Thread.sleep(500)

      // Close the insecure connection to release resources.
      conn.close()
      Looper.myLooper()!!.quit()
    } catch (e: Exception) {
      // Handle communications error here.
      e.printStackTrace()
      result.error("Error", "onPrintZplDataOverBluetooth", e)
    }

  }

  private fun onGetPrinterInfo(@NonNull call: MethodCall, @NonNull result: Result) {
    var ipE: String? = call.argument("ip")
    var ipAddress: String = ""
    var rep = HashMap<String, Any>()
    if(ipE != null){
      ipAddress = ipE
    } else {
      result.error("PrintZPLOverTCPIP", "IP Address is required", "Data Content")
      return
    }
    val conn: Connection = createTcpConnect(ipAddress, TcpConnection.DEFAULT_ZPL_TCP_PORT)
    try {
      // Open the connection - physical connection is established here.
      conn.open()
      // Send the data to printer as a byte array.
      val discoveryData = DiscoveryUtil.getDiscoveryDataMap(conn)
      Log.d(logTag, "onGetIPInfo $discoveryData")
      rep["success"] = true
      rep["message"] = "Successfully!"
      rep["content"] = discoveryData
      result.success(rep)


    } catch (e: ConnectionException) {
      // Handle communications error here.
      e.printStackTrace()
      result.error("Error", "onPrintZPLOverTCPIP", e)
    } finally {
      // Close the connection to release resources.
      conn.close()
    }
  }

  private fun onDiscovery(@NonNull call: MethodCall, @NonNull result: Result) {
    var handleNet = object : DiscoveryHandler {

      override fun foundPrinter(p0: DiscoveredPrinter) {
        Log.d(logTag, "foundPrinter $p0")
        printers.add(p0)
      }

      override fun discoveryFinished() {
        Log.d(logTag, "discoveryFinished $printers")
//        var res = { printers }
        result.success("Success")
      }

      override fun discoveryError(p0: String?) {
        Log.d(logTag, "discoveryError $p0")
        result.error("discoveryError", "discoveryError", p0)
      }
    }
    try {
      NetworkDiscoverer.findPrinters(handleNet)
    } catch (e: Exception) {
      e.printStackTrace()
      result.error("Error", "onDiscovery", e)
    }
     var net =  DiscoveredPrinterNetwork("a", 1)

  }


}
