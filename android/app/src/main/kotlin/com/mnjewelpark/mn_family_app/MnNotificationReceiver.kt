package com.mnjewelpark.mn_family_app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject
import kotlin.concurrent.thread

class MnNotificationReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_SYNC = "com.mnjewelpark.mn_family_app.ACTION_SYNC_NOTIFICATIONS"
        private const val CHAT_CHANNEL_ID = "mn_family_channel_chat"
        private const val CHAT_CHANNEL_NAME = "MN Family Chat & Messages"
        private const val ALERT_CHANNEL_ID = "mn_family_channel_high"
        private const val ALERT_CHANNEL_NAME = "MN Family Official Notifications"
        private const val INTERVAL_MS = 2500L // 2.5-second ultra-low latency interval

        fun scheduleNext(context: Context, delayMs: Long = INTERVAL_MS) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val intent = Intent(context, MnNotificationReceiver::class.java).apply {
                    action = ACTION_SYNC
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    888,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val triggerAt = SystemClock.elapsedRealtime() + delayMs
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent)
                }
            } catch (e: Exception) {
                // Ignore if exact alarm permission restricted
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        // Ensure notification channels exist
        createNotificationChannels(context)

        // Run sync on background worker thread
        thread(start = true) {
            try {
                performSync(context)
            } catch (_: Exception) {
            } finally {
                // Schedule next periodic sync to keep continuous closed-app monitoring
                scheduleNext(context)
            }
        }
    }

    private fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return

            val chatChannel = NotificationChannel(
                CHAT_CHANNEL_ID,
                CHAT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Instant direct messages, group chat alerts and @mentions"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(chatChannel)

            val alertChannel = NotificationChannel(
                ALERT_CHANNEL_ID,
                ALERT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Official corporate alerts, directives, and reminders"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(alertChannel)
        }
    }

    private fun performSync(context: Context) {
        val prefs = context.getSharedPreferences("mn_app_prefs", Context.MODE_PRIVATE)
        val activeEmpId = prefs.getString("active_emp_id", "") ?: ""
        if (activeEmpId.isEmpty()) return

        val notifiedKey = "notified_ids_$activeEmpId"
        val notifiedSet = HashSet(prefs.getStringSet(notifiedKey, emptySet()) ?: emptySet())

        // 1. Sync Chats
        val chatsUrl = "https://firestore.googleapis.com/v1/projects/mn-family/databases/(default)/documents/mn_team_chats?pageSize=50"
        val chatsJson = httpGet(chatsUrl)
        if (chatsJson != null) {
            val docs = chatsJson.optJSONArray("documents")
            if (docs != null) {
                for (i in 0 until docs.length()) {
                    val doc = docs.optJSONObject(i) ?: continue
                    val docPath = doc.optString("name", "")
                    val docId = docPath.substringAfterLast("/")
                    if (docId.isEmpty() || notifiedSet.contains(docId)) continue

                    val fields = doc.optJSONObject("fields") ?: continue
                    val senderId = fields.optJSONObject("senderId")?.optString("stringValue", "") ?: ""
                    val senderName = fields.optJSONObject("senderName")?.optString("stringValue", "Colleague") ?: "Colleague"
                    val receiverId = fields.optJSONObject("receiverId")?.optString("stringValue", "") ?: ""
                    val text = fields.optJSONObject("text")?.optString("stringValue", "") ?: ""

                    // Sender never receives push notification for their own message
                    if (!senderId.equals(activeEmpId, ignoreCase = true)) {
                        val isForMe = receiverId.equals(activeEmpId, ignoreCase = true) || receiverId.equals("ALL_HANDS", ignoreCase = true)
                        if (isForMe && text.isNotEmpty()) {
                            val title = if (receiverId.equals("ALL_HANDS", ignoreCase = true)) {
                                "💬 $senderName (MN All-Hands)"
                            } else {
                                "💬 $senderName"
                            }
                            showNativeNotification(context, docId, CHAT_CHANNEL_ID, title, text)
                        }
                    }

                    notifiedSet.add(docId)
                }
            }
        }

        // 2. Sync Company Notifications
        val notifsUrl = "https://firestore.googleapis.com/v1/projects/mn-family/databases/(default)/documents/company_notifications?pageSize=50"
        val notifsJson = httpGet(notifsUrl)
        if (notifsJson != null) {
            val docs = notifsJson.optJSONArray("documents")
            if (docs != null) {
                for (i in 0 until docs.length()) {
                    val doc = docs.optJSONObject(i) ?: continue
                    val docPath = doc.optString("name", "")
                    val docId = docPath.substringAfterLast("/")
                    if (docId.isEmpty() || notifiedSet.contains(docId)) continue

                    val fields = doc.optJSONObject("fields") ?: continue
                    val title = fields.optJSONObject("title")?.optString("stringValue", "MN Family Alert") ?: "MN Family Alert"
                    val content = fields.optJSONObject("content")?.optString("stringValue", "") ?: ""
                    val targetEmpId = fields.optJSONObject("targetEmpId")?.optString("stringValue", "") ?: ""

                    if (targetEmpId.isEmpty() || targetEmpId.equals(activeEmpId, ignoreCase = true)) {
                        if (content.isNotEmpty()) {
                            showNativeNotification(context, docId, ALERT_CHANNEL_ID, title, content)
                        }
                    }

                    notifiedSet.add(docId)
                }
            }
        }

        // Save updated notified IDs
        prefs.edit().putStringSet(notifiedKey, notifiedSet).apply()
    }

    private fun showNativeNotification(
        context: Context,
        idString: String,
        channelId: String,
        title: String,
        body: String
    ) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            idString.hashCode() and 0x7FFFFFFF,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(idString.hashCode() and 0x7FFFFFFF, notification)
    }

    private fun httpGet(urlStr: String): JSONObject? {
        var conn: HttpURLConnection? = null
        return try {
            val url = URL(urlStr)
            conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "GET"
            conn.connectTimeout = 8000
            conn.readTimeout = 8000
            conn.setRequestProperty("Accept", "application/json")
            if (conn.responseCode == 200) {
                val reader = BufferedReader(InputStreamReader(conn.inputStream))
                val sb = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    sb.append(line)
                }
                reader.close()
                JSONObject(sb.toString())
            } else {
                null
            }
        } catch (_: Exception) {
            null
        } finally {
            conn?.disconnect()
        }
    }
}
