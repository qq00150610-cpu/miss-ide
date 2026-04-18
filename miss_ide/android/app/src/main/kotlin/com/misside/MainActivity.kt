// android/app/src/main/kotlin/com/misside/MainActivity.kt
package com.misside

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.misside.engine.JadxEnginePlugin
import com.misside.external.ExternalToolPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册 Jadx 引擎插件
        flutterEngine.plugins.add(JadxEnginePlugin())
        
        // 注册外部工具插件
        flutterEngine.plugins.add(ExternalToolPlugin())
    }
}
