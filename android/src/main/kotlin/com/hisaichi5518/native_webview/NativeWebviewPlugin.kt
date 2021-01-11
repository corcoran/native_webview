package com.hisaichi5518.native_webview

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.webkit.WebChromeClient
import androidx.annotation.NonNull;
import com.hisaichi5518.native_webview.Locator.Companion.REQUEST_SELECT_FILE
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformViewRegistry

class NativeWebviewPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
    private var cookieManager: MyCookieManager? = null
    private var webviewManager: WebViewManager? = null
    private var pluginBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Locator.binding = binding

        onAttachedToEngine(
            binding.binaryMessenger,
            binding.platformViewRegistry
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Locator.binding = null
    }

    private fun onAttachedToEngine(messenger: BinaryMessenger, registry: PlatformViewRegistry) {
        registry.registerViewFactory(
            "com.hisaichi5518/native_webview",
            FlutterWebViewFactory(messenger)
        )
        cookieManager = MyCookieManager(messenger)
        webviewManager = WebViewManager(messenger)
    }

    override fun onDetachedFromActivity() {
        Locator.activity = null
        cookieManager?.dispose()
        cookieManager = null
        webviewManager?.dispose()
        webviewManager = null
        pluginBinding?.removeActivityResultListener(this)
        pluginBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Locator.activity = binding.activity
        pluginBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Locator.activity = null
        pluginBinding?.removeActivityResultListener(this)
        pluginBinding = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_SELECT_FILE) {
            if (resultCode != Activity.RESULT_OK) {
                Log.e("NativeWebviewPlugin", "Activity result failed: $requestCode | $resultCode")
                Locator.uploadMessage?.onReceiveValue(arrayOf(Uri.EMPTY));
            } else {
                Locator.uploadMessage?.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(resultCode, data))
            }
            Locator.uploadMessage = null
            return true
        }
        return false
    }
}
