package id.nhasix.kuron_native.kuron_native

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import java.io.File
import kotlin.math.roundToInt

object SystemInfoUtils {

    fun getMemoryInfo(context: Context): Map<String, Any> {
        val memoryInfo = ActivityManager.MemoryInfo()
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        activityManager.getMemoryInfo(memoryInfo)

        val totalMem = memoryInfo.totalMem
        val availMem = memoryInfo.availMem
        val usedMem = totalMem - availMem
        val percent = (usedMem.toDouble() / totalMem.toDouble() * 100).roundToInt()

        return mapOf(
            "total" to totalMem,
            "available" to availMem,
            "used" to usedMem,
            "percent" to percent
        )
    }

    fun getStorageInfo(): Map<String, Any> {
        val path = Environment.getDataDirectory()
        val stat = StatFs(path.path)
        val blockSize = stat.blockSizeLong
        val totalBlocks = stat.blockCountLong
        val availableBlocks = stat.availableBlocksLong

        val total = totalBlocks * blockSize
        val available = availableBlocks * blockSize
        val used = total - available
        val percent = (used.toDouble() / total.toDouble() * 100).roundToInt()

        return mapOf(
            "total" to total,
            "available" to available,
            "used" to used,
            "percent" to percent
        )
    }

    fun getBatteryInfo(context: Context): Map<String, Any> {
        val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
            context.registerReceiver(null, ifilter)
        }

        val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPct = level * 100 / scale.toFloat()
        
        val status: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL

        return mapOf(
            "percent" to batteryPct.roundToInt(),
            "isCharging" to isCharging
        )
    }
}
