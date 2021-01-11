package com.hisaichi5518.native_webview

import android.app.Activity
import android.net.Uri
import android.webkit.ValueCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin

class Locator {
    companion object {
        const val REQUEST_SELECT_FILE = 1066
        var activity: Activity? = null
        var binding: FlutterPlugin.FlutterPluginBinding? = null
        var uploadMessage: ValueCallback<Array<Uri>>? = null
    }
}