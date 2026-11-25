package com.orthodox.app.orthodox_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder

/**
 * Native Android MediaSession + Foreground MediaStyle Notification Service.
 * Automatically integrates with:
 *   - Android Notification Shade & Quick Settings Media Player
 *   - Lock Screen Media Controls
 *   - Xiaomi HyperOS Dynamic Island / Pill & Samsung Now Bar
 *   - Bluetooth / Headset Play/Pause/Next/Previous buttons
 */
class HymnMediaService : Service() {

    companion object {
        const val CHANNEL_ID = "orthoxia_hymn_media_channel"
        const val NOTIFICATION_ID = 7701

        const val ACTION_UPDATE = "com.orthodox.app.MEDIA_UPDATE"
        const val ACTION_PLAY = "com.orthodox.app.MEDIA_PLAY"
        const val ACTION_PAUSE = "com.orthodox.app.MEDIA_PAUSE"
        const val ACTION_TOGGLE = "com.orthodox.app.MEDIA_TOGGLE"
        const val ACTION_NEXT = "com.orthodox.app.MEDIA_NEXT"
        const val ACTION_PREV = "com.orthodox.app.MEDIA_PREV"
        const val ACTION_STOP = "com.orthodox.app.MEDIA_STOP"

        const val EXTRA_TITLE = "title"
        const val EXTRA_CANTOR = "cantor"
        const val EXTRA_IS_PLAYING = "isPlaying"
        const val EXTRA_DURATION_MS = "durationMs"
        const val EXTRA_POSITION_MS = "positionMs"

        @Volatile
        var actionListener: ((String) -> Unit)? = null

        fun startOrUpdate(
            context: Context,
            title: String,
            cantor: String,
            isPlaying: Boolean,
            durationMs: Long,
            positionMs: Long
        ) {
            val intent = Intent(context, HymnMediaService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_CANTOR, cantor)
                putExtra(EXTRA_IS_PLAYING, isPlaying)
                putExtra(EXTRA_DURATION_MS, durationMs)
                putExtra(EXTRA_POSITION_MS, positionMs)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Exception) {
                try {
                    context.startService(intent)
                } catch (_: Exception) {}
            }
        }

        fun stopService(context: Context) {
            try {
                context.stopService(Intent(context, HymnMediaService::class.java))
            } catch (_: Exception) {}
        }
    }

    private var mediaSession: MediaSession? = null
    private var currentTitle: String = "ألحان أرثوذكسيا"
    private var currentCantor: String = "الكنيسة القبطية الأرثوذكسية"
    private var isPlaying: Boolean = false
    private var durationMs: Long = 0L
    private var positionMs: Long = 0L

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        mediaSession = MediaSession(this, "OrthoxiaHymnSession").apply {
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    dispatchToFlutter("play")
                }

                override fun onPause() {
                    dispatchToFlutter("pause")
                }

                override fun onStop() {
                    dispatchToFlutter("stop")
                    stopSelfSafely()
                }

                override fun onSkipToNext() {
                    dispatchToFlutter("next")
                }

                override fun onSkipToPrevious() {
                    dispatchToFlutter("previous")
                }

                override fun onSeekTo(pos: Long) {
                    dispatchToFlutter("seek:$pos")
                }
            })
            isActive = true
        }
    }

    private fun dispatchToFlutter(cmd: String) {
        try {
            actionListener?.invoke(cmd)
        } catch (_: Exception) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_UPDATE -> {
                currentTitle = intent.getStringExtra(EXTRA_TITLE)?.ifBlank { "ألحان أرثوذكسيا" }
                    ?: currentTitle
                currentCantor = intent.getStringExtra(EXTRA_CANTOR)?.ifBlank { "أرثوذكسيا" }
                    ?: currentCantor
                isPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, false)
                durationMs = intent.getLongExtra(EXTRA_DURATION_MS, durationMs)
                positionMs = intent.getLongExtra(EXTRA_POSITION_MS, positionMs)
                updateSessionAndNotification()
            }
            ACTION_PLAY -> {
                isPlaying = true
                updateSessionAndNotification()
                dispatchToFlutter("play")
            }
            ACTION_PAUSE -> {
                isPlaying = false
                updateSessionAndNotification()
                dispatchToFlutter("pause")
            }
            ACTION_TOGGLE -> {
                isPlaying = !isPlaying
                updateSessionAndNotification()
                dispatchToFlutter(if (isPlaying) "play" else "pause")
            }
            ACTION_NEXT -> dispatchToFlutter("next")
            ACTION_PREV -> dispatchToFlutter("previous")
            ACTION_STOP -> {
                dispatchToFlutter("stop")
                stopSelfSafely()
            }
            else -> updateSessionAndNotification()
        }
        return START_NOT_STICKY
    }

    private fun stopSelfSafely() {
        try {
            mediaSession?.isActive = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {}
        stopSelf()
    }

    private fun updateSessionAndNotification() {
        val session = mediaSession ?: return
        val actionsMask = PlaybackState.ACTION_PLAY or
            PlaybackState.ACTION_PAUSE or
            PlaybackState.ACTION_PLAY_PAUSE or
            PlaybackState.ACTION_STOP or
            PlaybackState.ACTION_SKIP_TO_NEXT or
            PlaybackState.ACTION_SKIP_TO_PREVIOUS or
            PlaybackState.ACTION_SEEK_TO

        val pbState = PlaybackState.Builder()
            .setActions(actionsMask)
            .setState(
                if (isPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,
                positionMs,
                if (isPlaying) 1.0f else 0.0f
            )
            .build()
        session.setPlaybackState(pbState)

        val appIcon = try {
            BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        } catch (_: Exception) {
            null
        }

        val metaBuilder = MediaMetadata.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, currentTitle)
            .putString(MediaMetadata.METADATA_KEY_ARTIST, currentCantor)
            .putString(MediaMetadata.METADATA_KEY_ALBUM, "أرثوذكسيا • ألحان الكنيسة القبطية")
        if (durationMs > 0L) {
            metaBuilder.putLong(MediaMetadata.METADATA_KEY_DURATION, durationMs)
        }
        if (appIcon != null) {
            metaBuilder.putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, appIcon)
            metaBuilder.putBitmap(MediaMetadata.METADATA_KEY_ART, appIcon)
        }
        session.setMetadata(metaBuilder.build())
        session.isActive = true

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPi = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevAction = Notification.Action.Builder(
            android.R.drawable.ic_media_previous,
            "السابق",
            servicePendingIntent(ACTION_PREV, 1)
        ).build()

        val playPauseAction = Notification.Action.Builder(
            if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
            if (isPlaying) "إيقاف مؤقت" else "تشغيل",
            servicePendingIntent(ACTION_TOGGLE, 2)
        ).build()

        val nextAction = Notification.Action.Builder(
            android.R.drawable.ic_media_next,
            "التالي",
            servicePendingIntent(ACTION_NEXT, 3)
        ).build()

        val stopAction = Notification.Action.Builder(
            android.R.drawable.ic_menu_close_clear_cancel,
            "إغلاق",
            servicePendingIntent(ACTION_STOP, 4)
        ).build()

        val mediaStyle = Notification.MediaStyle()
            .setMediaSession(session.sessionToken)
            .setShowActionsInCompactView(0, 1, 3)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(currentTitle)
            .setContentText(currentCantor)
            .setSubText("أرثوذكسيا")
            .setContentIntent(contentPi)
            .setDeleteIntent(servicePendingIntent(ACTION_STOP, 5))
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(isPlaying)
            .setOnlyAlertOnce(true)
            .addAction(prevAction)
            .addAction(playPauseAction)
            .addAction(nextAction)
            .addAction(stopAction)
            .setStyle(mediaStyle)

        if (appIcon != null) {
            builder.setLargeIcon(appIcon)
        }

        val notification = builder.build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun servicePendingIntent(actionStr: String, reqCode: Int): PendingIntent {
        val intent = Intent(this, HymnMediaService::class.java).apply {
            action = actionStr
        }
        return PendingIntent.getService(
            this,
            reqCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = nm.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val ch = NotificationChannel(
                    CHANNEL_ID,
                    "مشغل الألحان القبطية",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "التحكم في تشغيل وإيقاف الألحان من الإشعارات وشاشة القفل"
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(ch)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        try {
            mediaSession?.isActive = false
            mediaSession?.release()
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
