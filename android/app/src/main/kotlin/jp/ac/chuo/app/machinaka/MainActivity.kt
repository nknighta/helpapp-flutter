package jp.ac.chuo.app.machinaka

import android.content.Intent
import android.net.Uri
import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    private val CHANNEL = "helpapp.deep_links"
    private val TAG = "DeepLinkMainActivity"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Allow Dart to request the initial deep link via method channel:
        // - method call: "getInitialLink" -> returns String? initial URI or null
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    val initialUri = intent?.dataString ?: kotlin.run {
                        // fallback to persisted deep link (if saved earlier).
                        // Check both the plain key and the flutter-prefixed key.
                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        (prefs.getString("deep_link_uri", null) ?: prefs.getString("flutter.deep_link_uri", null))
                    }
                    Log.d(TAG, "getInitialLink requested, initialUri=")
                    Log.d(TAG, "  -> $initialUri")
                    result.success(initialUri)
                }
                "simulateDeepLink" -> {
                    // Accepts a map payload or a URI string from Dart, persists, and forwards to onDeepLink
                    val args = call.arguments
                    try {
                        val payloadMap: MutableMap<String, Any?>? = when (args) {
                            is Map<*, *> -> {
                                val out = HashMap<String, Any?>()
                                for ((k, v) in args.entries) {
                                    if (k != null) out[k.toString()] = v
                                }
                                out
                            }
                            is String -> {
                                // raw URI string passed, parse into payload
                                val uri = Uri.parse(args)
                                val m = HashMap<String, Any?>()
                                m["action"] = uri.getQueryParameter("viewmap")
                                m["lat"] = uri.getQueryParameter("lat")
                                m["lng"] = uri.getQueryParameter("lng")
                                m["login"] = uri.getQueryParameter("login")
                                m
                            }
                            else -> null
                        }

                        if (payloadMap != null) {
                            // Persist fallback keys to SharedPreferences for Flutter to read
                            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                            val json = JSONObject()
                            json.put("action", payloadMap["action"]?.toString())
                            json.put("lat", payloadMap["lat"]?.toString())
                            json.put("lng", payloadMap["lng"]?.toString())
                            json.put("login", payloadMap["login"]?.toString())
                            prefs.edit().putString("deep_link_map", json.toString()).apply()
                            prefs.edit().putString("flutter.deep_link_map", json.toString()).apply()

                            val rawUri = "helpapp://?viewmap=${payloadMap["action"] ?: ""}${payloadMap["lat"]?.let { "&lat=$it" } ?: ""}${payloadMap["lng"]?.let { "&lng=$it" } ?: ""}&login=${payloadMap["login"] ?: "false"}"
                            prefs.edit().putString("deep_link_uri", rawUri).apply()
                            prefs.edit().putString("flutter.deep_link_uri", rawUri).apply()

                            Log.d(TAG, "simulateDeepLink: persisted payload and rawUri=$rawUri")

                            // Forward event back to Flutter as an onDeepLink event to simulate native behavior
                            try {
                                methodChannel.invokeMethod("onDeepLink", payloadMap)
                                result.success(true)
                            } catch (invokeErr: Exception) {
                                Log.e(TAG, "simulateDeepLink: failed to invoke onDeepLink method: ${invokeErr.message}")
                                result.error("INVOKE_ERR", invokeErr.message, null)
                            }
                        } else {
                            result.error("ARG_ERROR", "simulateDeepLink requires a Map or a URI string", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "simulateDeepLink error: ${e.message}")
                        result.error("SIM_ERR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // If the activity was launched by an Intent containing a deep link, send it through the channel
        Log.d(TAG, "configureFlutterEngine: checking initial intent=${intent?.data}")
        sendDeepLinkFromIntent(intent, false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Ensure the activity's intent is updated
        setIntent(intent)
        Log.d(TAG, "onNewIntent: intent=${intent?.data}")
        sendDeepLinkFromIntent(intent, true)
    }

    /**
     * Parse the intent data and send a method channel message to Flutter.
     * Expected query params: viewmap (view|navigate), lat, lng, login (true|false)
     */
    private fun sendDeepLinkFromIntent(intent: Intent?, invokeMethod: Boolean = true) {
        try {
            val uri: Uri? = intent?.data
            Log.d(TAG, "sendDeepLinkFromIntent called; intentUri=${uri?.toString()}")
            if (uri != null && ::methodChannel.isInitialized) {
                val viewmap = uri.getQueryParameter("viewmap")
                val lat = uri.getQueryParameter("lat")
                val lng = uri.getQueryParameter("lng")
                val login = uri.getQueryParameter("login")
                Log.d(TAG, "Parsed deep link params: viewmap=$viewmap, lat=$lat, lng=$lng, login=$login")

                val payload: MutableMap<String, Any?> = HashMap()
                payload["action"] = viewmap
                payload["lat"] = lat
                payload["lng"] = lng
                payload["login"] = login

                // Persist deep link payload JSON and raw URI to the same SharedPreferences file used by Flutter plugin,
                // so Flutter can read it via SharedPreferences fallback if necessary.
                try {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val json = JSONObject()
                    json.put("action", viewmap)
                    json.put("lat", lat)
                    json.put("lng", lng)
                    json.put("login", login)
                    Log.d(TAG, "Persisting deep link payload to prefs: ${json.toString()}")
                    prefs.edit().putString("deep_link_map", json.toString()).apply()
                    prefs.edit().putString("flutter.deep_link_map", json.toString()).apply()
                    prefs.edit().putString("deep_link_uri", uri.toString()).apply()
                    prefs.edit().putString("flutter.deep_link_uri", uri.toString()).apply()
                } catch (je: Exception) {
                    // If JSON building or saving fails, print and continue to dispatch to Flutter anyway.
                    je.printStackTrace()
                }

                // Send event to Flutter (only if requested, prevents duplicate initial channel events)
                if (invokeMethod && ::methodChannel.isInitialized) {
                    methodChannel.invokeMethod("onDeepLink", payload)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "DeepLink processing failed", e)
        }
    }
}
