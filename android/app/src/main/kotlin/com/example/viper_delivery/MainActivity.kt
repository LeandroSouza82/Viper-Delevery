package com.example.viper_delivery

import android.graphics.Color
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 1. Desativa o modo edge-to-edge que a Xiaomi força (Android 14 fix)
        WindowCompat.setDecorFitsSystemWindows(window, true)
        
        // 2. Garante que as barras desenhem o fundo de forma imperativa
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        
        // 3. Pinta as barras de PRETO no nível mais baixo de hardware
        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK
        
        // 4. Força os ícones (hora/bateria) a serem BRANCOS para contraste absoluto
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.isAppearanceLightStatusBars = false
        controller.isAppearanceLightNavigationBars = false
    }
}
