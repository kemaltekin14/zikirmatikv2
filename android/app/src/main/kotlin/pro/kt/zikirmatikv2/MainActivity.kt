package pro.kt.zikirmatikv2

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
    private var feedbackSoundPool: SoundPool? = null
    private var successSoundId: Int = 0
    private var counterTickSoundId: Int = 0
    private var beadCollisionSoundId: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        disableSystemTouchSounds(window.decorView)
        window.decorView.post {
            disableSystemTouchSounds(window.decorView)
        }
        prepareFeedbackSounds()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pro.kt.zikirmatikv2/feedback"
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
                "playCounterTickSound" -> {
                    playCounterTickSound()
                    result.success(null)
                }
                "playBeadCollisionSound" -> {
                    playBeadCollisionSound()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        feedbackSoundPool?.release()
        feedbackSoundPool = null
        successSoundId = 0
        counterTickSoundId = 0
        beadCollisionSoundId = 0
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

    private fun prepareFeedbackSounds() {
        if (feedbackSoundPool != null) return

        feedbackSoundPool = SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(feedbackAudioAttributes())
            .build()
            .also { pool ->
                successSoundId = pool.load(this, R.raw.success_chime, 1)
                counterTickSoundId = pool.load(this, R.raw.counter_tick, 1)
                beadCollisionSoundId = pool.load(this, R.raw.glass_tesbih_click, 1)
            }
    }

    private fun playSuccessSound() {
        val pool = feedbackSoundPool ?: return
        if (successSoundId == 0) return
        pool.play(successSoundId, 0.58f, 0.58f, 1, 0, 1.0f)
    }

    private fun playCounterTickSound() {
        val pool = feedbackSoundPool ?: return
        if (counterTickSoundId == 0) return
        pool.play(counterTickSoundId, 0.42f, 0.42f, 1, 0, 1.0f)
    }

    private fun playBeadCollisionSound() {
        val pool = feedbackSoundPool ?: return
        if (beadCollisionSoundId == 0) return
        pool.play(beadCollisionSoundId, 0.46f, 0.46f, 1, 0, 1.0f)
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
            val effect = VibrationEffect.createOneShot(
                duration,
                amplitude.coerceIn(1, 255)
            )
            vibrator.vibrate(effect, feedbackAudioAttributes())
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(duration)
        }
    }

    private fun feedbackAudioAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }
}
