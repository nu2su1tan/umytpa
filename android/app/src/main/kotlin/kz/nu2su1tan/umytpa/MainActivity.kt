package kz.nu2su1tan.umytpa

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hands "add a task" requests from outside (the share sheet, the widget's "+")
 * to Flutter: they wait here until Dart asks with `take`.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: Map<String, String?>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "umytpa/entry")
        ch.setMethodCallHandler { call, result ->
            if (call.method == "take") {
                result.success(pending)
                pending = null
            } else {
                result.notImplemented()
            }
        }
        channel = ch
        capture(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (capture(intent)) {
            channel?.invokeMethod("changed", null)
        }
    }

    private fun capture(intent: Intent?): Boolean {
        if (intent == null) return false
        val entry: Map<String, String?>? = when {
            intent.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true ->
                mapOf("kind" to "share", "text" to intent.getStringExtra(Intent.EXTRA_TEXT))
            intent.action == ACTION_NEW_TASK -> mapOf("kind" to "new")
            else -> null
        }
        if (entry == null) return false
        pending = entry
        // Handled once: a rotation must not open the form again.
        setIntent(Intent())
        return true
    }

    companion object {
        const val ACTION_NEW_TASK = "kz.nu2su1tan.umytpa.NEW_TASK"
    }
}
