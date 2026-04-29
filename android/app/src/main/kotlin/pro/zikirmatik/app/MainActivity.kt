package pro.zikirmatik.app

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var successSoundPool: SoundPool? = null
    private var successSoundId: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        disableSystemTouchSounds(window.decorView)
        window.decorView.post {
            disableSystemTouchSounds(window.decorView)
        }
        prepareSuccessSound()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pro.zikirmatik.app/feedback"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    val durationMs = call.argument<Int>("durationMs")?.toLong() ?: 24L
                    val amplitude = call.argument<Int>("amplitude") ?: 110
                    vibrate(durationMs, amplitude)
                    result.success(null)
                }
                "playSuccessSound" -> {
                    playSuccessSound()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        successSoundPool?.release()
        successSoundPool = null
        successSoundId = 0
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun disableSystemTouchSounds(view: View) {
        view.isSoundEffectsEnabled = false
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                disableSystemTouchSounds(view.getChildAt(index))
            }
        }
    }

    private fun prepareSuccessSound() {
        if (successSoundPool != null) return

        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        successSoundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(attributes)
            .build()
            .also { pool ->
                successSoundId = pool.load(this, R.raw.success_chime, 1)
            }
    }

    private fun playSuccessSound() {
        val pool = successSoundPool ?: return
        if (successSoundId == 0) return
        pool.play(successSoundId, 0.58f, 0.58f, 1, 0, 1.0f)
    }

    private fun vibrate(durationMs: Long, amplitude: Int) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (!vibrator.hasVibrator()) return

        val duration = durationMs.coerceAtLeast(1L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    duration,
                    amplitude.coerceIn(1, 255)
                )
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(duration)
        }
    }
}
