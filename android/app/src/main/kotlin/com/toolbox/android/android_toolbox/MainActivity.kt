package com.toolbox.android.android_toolbox

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.toolbox.android/system_tools"
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    // Barometer Sensor
    private var sensorManager: SensorManager? = null
    private var pressureSensor: Sensor? = null
    private var currentPressure: Float = 0f
    private var pressureListener: SensorEventListener? = null

    // Tone Player
    private var activeAudioTrack: AudioTrack? = null
    @Volatile private var isPlayingTone = false

    // Microphone Recorder
    private var mediaRecorder: MediaRecorder? = null
    private var audioRecordFile: File? = null
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initPressureSensor()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledPackages" -> {
                    val includeSystem = call.argument<Boolean>("includeSystem") ?: false
                    executor.execute {
                        try {
                            val list = getInstalledPackagesList(includeSystem)
                            mainHandler.post { result.success(list) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    executor.execute {
                        try {
                            val base64Icon = getAppIconBase64(packageName)
                            mainHandler.post { result.success(base64Icon) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getAppDetails" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    executor.execute {
                        try {
                            val details = getAppDetailsMap(packageName)
                            mainHandler.post { result.success(details) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "extractApk" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    executor.execute {
                        try {
                            val extractedPath = extractApkInternal(packageName)
                            mainHandler.post { result.success(extractedPath) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val intent = packageManager.getLaunchIntentForPackage(packageName)
                    if (intent != null) {
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "openAppSettings" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    try {
                        val intent = Intent(Intent.ACTION_DELETE).apply {
                            data = Uri.fromParts("package", packageName, null)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getAdvancedBatteryInfo" -> {
                    try {
                        val info = getAdvancedBatteryInfoInternal()
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getHardwareDeviceInfo" -> {
                    try {
                        val info = getHardwareDeviceInfoInternal()
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getDangerousPermissionsAudit" -> {
                    executor.execute {
                        try {
                            val audit = getDangerousPermissionsAuditInternal()
                            mainHandler.post { result.success(audit) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "openDevSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "scanMediaFile" -> {
                    try {
                        val path = call.argument<String>("path") ?: ""
                        if (path.isNotEmpty()) {
                            MediaScannerConnection.scanFile(this, arrayOf(path), null) { _, _ -> }
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openAllFilesAccessSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "openWirelessDebuggingSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openPrivateDnsSettings" -> {
                    try {
                        var intent = Intent("android.settings.NETWORK_OPERATOR_SETTINGS").apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        if (packageManager.resolveActivity(intent, 0) == null) {
                            intent = Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                        }
                        if (packageManager.resolveActivity(intent, 0) == null) {
                            intent = Intent(Settings.ACTION_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "isShizukuInstalled" -> {
                    try {
                        packageManager.getPackageInfo("moe.shizuku.privileged.api", 0)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getSystemLogcat" -> {
                    val maxLines = call.argument<Int>("maxLines") ?: 100
                    executor.execute {
                        try {
                            val logs = readLogcatInternal(maxLines)
                            mainHandler.post { result.success(logs) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "vibrateDevice" -> {
                    val durationMs = (call.argument<Number>("durationMs") ?: 100).toLong()
                    try {
                        vibrateInternal(durationMs)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                // --- New Hardware Testing Methods ---
                "hasBarometerSensor" -> {
                    val hasSensor = pressureSensor != null
                    result.success(hasSensor)
                }
                "getBarometerPressure" -> {
                    result.success(currentPressure.toDouble())
                }
                "playTone" -> {
                    val freq = (call.argument<Number>("frequency") ?: 165.0).toDouble()
                    val duration = (call.argument<Number>("durationMs") ?: 10000).toLong()
                    val channel = call.argument<String>("channel") ?: "both"
                    playToneInternal(freq, duration, channel)
                    result.success(true)
                }
                "stopTone" -> {
                    stopToneInternal()
                    result.success(true)
                }
                "startRecordingMic" -> {
                    try {
                        val path = startRecordingMicInternal()
                        result.success(path)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "stopRecordingMic" -> {
                    val path = stopRecordingMicInternal()
                    result.success(path)
                }
                "getMaxMicAmplitude" -> {
                    val amp = getMaxMicAmplitudeInternal()
                    result.success(amp)
                }
                "playRecordedMic" -> {
                    val success = playRecordedMicInternal()
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initPressureSensor() {
        if (sensorManager == null) {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            pressureSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_PRESSURE)
        }
        if (pressureSensor != null && pressureListener == null) {
            pressureListener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent?) {
                    if (event?.sensor?.type == Sensor.TYPE_PRESSURE) {
                        currentPressure = event.values[0]
                    }
                }
                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
            }
            sensorManager?.registerListener(pressureListener, pressureSensor, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onDestroy() {
        pressureListener?.let { sensorManager?.unregisterListener(it) }
        stopToneInternal()
        stopRecordingMicInternal()
        mediaPlayer?.release()
        super.onDestroy()
    }

    private fun getInstalledPackagesList(includeSystem: Boolean): List<Map<String, Any>> {
        val pm = packageManager
        val packages = pm.getInstalledPackages(0)
        val list = mutableListOf<Map<String, Any>>()

        for (pkg in packages) {
            val appInfo = pkg.applicationInfo ?: continue
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (!includeSystem && isSystem) continue

            val appName = pm.getApplicationLabel(appInfo).toString()
            val apkFile = File(appInfo.sourceDir)
            val apkSize = if (apkFile.exists()) apkFile.length() else 0L

            val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    pm.getInstallSourceInfo(pkg.packageName).installingPackageName
                } catch (_: Exception) {
                    @Suppress("DEPRECATION")
                    pm.getInstallerPackageName(pkg.packageName)
                }
            } else {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(pkg.packageName)
            }

            val isFromPlayStore = installer == "com.android.vending"
            val isSideloaded = !isSystem && !isFromPlayStore

            val installerSource = when {
                isFromPlayStore -> "Google Play Store"
                installer == null || installer.isEmpty() -> "Cài từ file APK"
                installer.contains("packageinstaller") -> "Trình cài đặt tệp APK"
                installer.contains("chrome") -> "Trình duyệt Chrome"
                installer.contains("zalo") -> "Zalo"
                installer.contains("telegram") -> "Telegram"
                else -> installer
            }

            val item = mutableMapOf<String, Any>(
                "packageName" to pkg.packageName,
                "appName" to appName,
                "versionName" to (pkg.versionName ?: ""),
                "versionCode" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pkg.longVersionCode else pkg.versionCode.toLong(),
                "isSystemApp" to isSystem,
                "installerPackageName" to (installer ?: ""),
                "installerSource" to installerSource,
                "isFromPlayStore" to isFromPlayStore,
                "isSideloaded" to isSideloaded,
                "apkPath" to appInfo.sourceDir,
                "apkSize" to apkSize,
                "firstInstallTime" to pkg.firstInstallTime,
                "lastUpdateTime" to pkg.lastUpdateTime,
                "targetSdkVersion" to appInfo.targetSdkVersion,
                "minSdkVersion" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) appInfo.minSdkVersion else 21
            )
            list.add(item)
        }
        return list.sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun getAppIconBase64(packageName: String): String {
        val pm = packageManager
        val appInfo = pm.getApplicationInfo(packageName, 0)
        val drawable = pm.getApplicationIcon(appInfo)
        val bitmap = drawableToBitmap(drawable)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
        val byteArray = stream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun getAppDetailsMap(packageName: String): Map<String, Any> {
        val pm = packageManager
        val pkg = pm.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
        val appInfo = pkg.applicationInfo ?: throw Exception("App info not found")

        val requestedPermissions = pkg.requestedPermissions?.toList() ?: emptyList()
        val permissionsGranted = mutableListOf<String>()
        val permissionsDenied = mutableListOf<String>()

        for (perm in requestedPermissions) {
            if (pm.checkPermission(perm, packageName) == PackageManager.PERMISSION_GRANTED) {
                permissionsGranted.add(perm)
            } else {
                permissionsDenied.add(perm)
            }
        }

        val apkFile = File(appInfo.sourceDir)

        val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                pm.getInstallSourceInfo(packageName).installingPackageName
            } catch (_: Exception) {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(packageName)
            }
        } else {
            @Suppress("DEPRECATION")
            pm.getInstallerPackageName(packageName)
        }

        val isFromPlayStore = installer == "com.android.vending"

        return mapOf(
            "packageName" to pkg.packageName,
            "appName" to pm.getApplicationLabel(appInfo).toString(),
            "versionName" to (pkg.versionName ?: ""),
            "versionCode" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pkg.longVersionCode else pkg.versionCode.toLong(),
            "sourceDir" to appInfo.sourceDir,
            "dataDir" to appInfo.dataDir,
            "apkSize" to if (apkFile.exists()) apkFile.length() else 0L,
            "targetSdkVersion" to appInfo.targetSdkVersion,
            "minSdkVersion" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) appInfo.minSdkVersion else 21,
            "permissionsGranted" to permissionsGranted,
            "permissionsDenied" to permissionsDenied,
            "firstInstallTime" to pkg.firstInstallTime,
            "lastUpdateTime" to pkg.lastUpdateTime,
            "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
            "installerPackageName" to (installer ?: ""),
            "isFromPlayStore" to isFromPlayStore,
            "isSideloaded" to (!((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) && !isFromPlayStore)
        )
    }

    private fun extractApkInternal(packageName: String): String {
        val pm = packageManager
        val appInfo = pm.getApplicationInfo(packageName, 0)
        val sourceApk = File(appInfo.sourceDir)
        if (!sourceApk.exists()) throw Exception("Source APK not found")

        val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val targetDir = File(downloadDir, "AndroidToolbox_APKs")
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }

        val appLabel = pm.getApplicationLabel(appInfo).toString().replace(Regex("[^a-zA-Z0-9.-]"), "_")
        val pkg = pm.getPackageInfo(packageName, 0)
        val vName = pkg.versionName ?: "1.0"
        val targetFileName = "${appLabel}_v${vName}.apk"
        val targetFile = File(targetDir, targetFileName)

        FileInputStream(sourceApk).use { input ->
            FileOutputStream(targetFile).use { output ->
                input.copyTo(output)
            }
        }

        return targetFile.absolutePath
    }

    private fun readSysfs(path: String): String? {
        return try {
            val file = File(path)
            if (file.exists() && file.canRead()) {
                file.readText().trim()
            } else null
        } catch (_: Exception) {
            null
        }
    }

    private fun getAdvancedBatteryInfoInternal(): Map<String, Any> {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val intent = registerReceiver(null, filter)
        val bm = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager

        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val tempRaw = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        val tech = intent?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "Li-ion"

        val healthRaw = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN) ?: 0
        val health = when (healthRaw) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
            BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
            else -> "Good"
        }

        val statusRaw = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, BatteryManager.BATTERY_STATUS_UNKNOWN) ?: BatteryManager.BATTERY_STATUS_UNKNOWN
        val pluggedRaw = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0

        // Device is strictly charging only when Android OS reports CHARGING or FULL with power plugged in
        val isCharging = when (statusRaw) {
            BatteryManager.BATTERY_STATUS_CHARGING -> true
            BatteryManager.BATTERY_STATUS_FULL -> pluggedRaw > 0
            BatteryManager.BATTERY_STATUS_DISCHARGING, BatteryManager.BATTERY_STATUS_NOT_CHARGING -> false
            else -> pluggedRaw > 0
        }

        val status = when (statusRaw) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "Full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not Charging"
            else -> if (isCharging) "Charging" else "Discharging"
        }

        val plugged = when (pluggedRaw) {
            BatteryManager.BATTERY_PLUGGED_AC -> "AC Charger"
            BatteryManager.BATTERY_PLUGGED_USB -> "USB Port"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
            else -> "Unplugged"
        }

        val currentNow = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW) ?: 0
        val currentAverage = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_AVERAGE) ?: 0
        val capacity = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: level

        // Deep Battery Health via sysfs
        val cycleCountSys = readSysfs("/sys/class/power_supply/battery/cycle_count")?.toIntOrNull()
        val cycleCount = cycleCountSys ?: (
            if (Build.VERSION.SDK_INT >= 34) {
                intent?.getIntExtra("android.os.extra.CYCLE_COUNT", 0) ?: 0
            } else 0
        )

        val chargeFullUah = readSysfs("/sys/class/power_supply/battery/charge_full")?.toLongOrNull() ?: 0L
        val chargeFullDesignUah = readSysfs("/sys/class/power_supply/battery/charge_full_design")?.toLongOrNull() ?: 0L

        // Design Capacity in mAh
        var designCapacityMah = if (chargeFullDesignUah > 0) (chargeFullDesignUah / 1000.0) else 0.0
        if (designCapacityMah <= 0.0) {
            try {
                val powerProfileClass = Class.forName("com.android.internal.os.PowerProfile")
                val powerProfile = powerProfileClass.getConstructor(Context::class.java).newInstance(this)
                designCapacityMah = powerProfileClass.getMethod("getBatteryCapacity").invoke(powerProfile) as Double
            } catch (_: Exception) {}
        }
        if (designCapacityMah <= 0.0) designCapacityMah = 5000.0 // Reasonable modern Android default

        // Actual Full Capacity in mAh
        val actualFullCapacityMah = if (chargeFullUah > 0) (chargeFullUah / 1000.0) else designCapacityMah

        // Health percentage & wear level
        val healthPercent = if (designCapacityMah > 0) {
            Math.min(100.0, Math.max(10.0, (actualFullCapacityMah / designCapacityMah) * 100.0))
        } else 100.0
        val wearLevel = Math.max(0.0, 100.0 - healthPercent)

        // Instant Wattage: V * A
        val volts = voltage / 1000.0
        val amps = Math.abs(currentNow) / 1000000.0
        val wattage = volts * amps

        return mapOf(
            "level" to (if (level >= 0 && scale > 0) (level * 100 / scale) else level),
            "temperature" to (tempRaw / 10.0),
            "voltage" to voltage,
            "technology" to tech,
            "health" to health,
            "status" to status,
            "isCharging" to isCharging,
            "statusRaw" to statusRaw,
            "pluggedRaw" to pluggedRaw,
            "plugged" to plugged,
            "currentNow" to currentNow,
            "currentAverage" to currentAverage,
            "capacity" to capacity,
            "cycleCount" to cycleCount,
            "designCapacityMah" to designCapacityMah,
            "actualFullCapacityMah" to actualFullCapacityMah,
            "healthPercent" to healthPercent,
            "wearLevel" to wearLevel,
            "wattage" to wattage
        )
    }

    private fun getHardwareDeviceInfoInternal(): Map<String, Any> {
        val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        actManager.getMemoryInfo(memInfo)

        val stat = StatFs(Environment.getDataDirectory().path)
        val totalStorage = stat.blockSizeLong * stat.blockCountLong
        val freeStorage = stat.blockSizeLong * stat.availableBlocksLong

        val socManufacturer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MANUFACTURER else "N/A"
        val socModel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MODEL else "N/A"

        return mapOf(
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "device" to Build.DEVICE,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "securityPatch" to (Build.VERSION.SECURITY_PATCH ?: "N/A"),
            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
            "socManufacturer" to socManufacturer,
            "socModel" to socModel,
            "totalRam" to memInfo.totalMem,
            "availableRam" to memInfo.availMem,
            "isLowRam" to memInfo.lowMemory,
            "totalStorage" to totalStorage,
            "freeStorage" to freeStorage
        )
    }

    private fun getDangerousPermissionsAuditInternal(): List<Map<String, Any>> {
        val dangerousPermissions = listOf(
            "android.permission.CAMERA" to "Camera",
            "android.permission.RECORD_AUDIO" to "Microphone",
            "android.permission.ACCESS_FINE_LOCATION" to "Location",
            "android.permission.READ_CONTACTS" to "Contacts",
            "android.permission.READ_SMS" to "SMS Messages",
            "android.permission.READ_CALL_LOG" to "Call Log",
            "android.permission.READ_EXTERNAL_STORAGE" to "Storage Read",
            "android.permission.WRITE_EXTERNAL_STORAGE" to "Storage Write"
        )

        val pm = packageManager
        val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        val auditList = mutableListOf<Map<String, Any>>()

        for (pkg in packages) {
            val appInfo = pkg.applicationInfo ?: continue
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (isSystem) continue

            val grantedDangerous = mutableListOf<String>()
            val reqPerms = pkg.requestedPermissions ?: continue

            for (p in reqPerms) {
                if (dangerousPermissions.any { it.first == p }) {
                    if (pm.checkPermission(p, pkg.packageName) == PackageManager.PERMISSION_GRANTED) {
                        val label = dangerousPermissions.first { it.first == p }.second
                        grantedDangerous.add(label)
                    }
                }
            }

            if (grantedDangerous.isNotEmpty()) {
                auditList.add(mapOf(
                    "packageName" to pkg.packageName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "permissions" to grantedDangerous,
                    "riskScore" to calculateRisk(grantedDangerous)
                ))
            }
        }

        return auditList.sortedByDescending { it["riskScore"] as Int }
    }

    private fun calculateRisk(permissions: List<String>): Int {
        var score = 0
        if (permissions.contains("Location")) score += 3
        if (permissions.contains("Camera")) score += 3
        if (permissions.contains("Microphone")) score += 4
        if (permissions.contains("Contacts")) score += 2
        if (permissions.contains("SMS Messages")) score += 4
        if (permissions.contains("Call Log")) score += 3
        if (permissions.contains("Storage Read")) score += 1
        return score
    }

    private fun readLogcatInternal(maxLines: Int): List<String> {
        val logs = mutableListOf<String>()
        val process = Runtime.getRuntime().exec("logcat -d -v time -t $maxLines")
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        var line: String? = reader.readLine()
        while (line != null) {
            logs.add(line)
            line = reader.readLine()
        }
        reader.close()
        return logs
    }

    private fun vibrateInternal(durationMs: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            val vibrator = vibratorManager?.defaultVibrator
            vibrator?.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(durationMs)
            }
        }
    }

    // --- Audio Tone Generator (Water Eject / Speaker Test) ---
    private fun playToneInternal(frequency: Double, durationMs: Long, channel: String = "both") {
        stopToneInternal()
        isPlayingTone = true
        executor.execute {
            try {
                val sampleRate = 44100
                val numSamples = (durationMs * sampleRate / 1000).toInt()
                val sample = ShortArray(numSamples * 2)

                for (i in 0 until numSamples) {
                    if (!isPlayingTone) break
                    val t = 2.0 * Math.PI * i / (sampleRate / frequency)
                    val s = (Math.sin(t) * Short.MAX_VALUE * 0.95).toInt().toShort()

                    when (channel) {
                        "left" -> {
                            sample[2 * i] = s
                            sample[2 * i + 1] = 0
                        }
                        "right" -> {
                            sample[2 * i] = 0
                            sample[2 * i + 1] = s
                        }
                        else -> {
                            sample[2 * i] = s
                            sample[2 * i + 1] = s
                        }
                    }
                }

                val bufferSize = sample.size * 2
                val track = AudioTrack(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .build(),
                    bufferSize,
                    AudioTrack.MODE_STREAM,
                    AudioManager.AUDIO_SESSION_ID_GENERATE
                )
                activeAudioTrack = track
                track.play()
                track.write(sample, 0, sample.size)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun stopToneInternal() {
        isPlayingTone = false
        try {
            activeAudioTrack?.stop()
            activeAudioTrack?.release()
            activeAudioTrack = null
        } catch (_: Exception) {}
    }

    // --- Microphone Test Methods ---
    private fun startRecordingMicInternal(): String {
        stopRecordingMicInternal()
        val file = File(cacheDir, "mic_test_record.m4a")
        audioRecordFile = file
        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setOutputFile(file.absolutePath)
            prepare()
            start()
        }
        return file.absolutePath
    }

    private fun stopRecordingMicInternal(): String {
        try {
            mediaRecorder?.stop()
            mediaRecorder?.release()
            mediaRecorder = null
        } catch (_: Exception) {}
        return audioRecordFile?.absolutePath ?: ""
    }

    private fun getMaxMicAmplitudeInternal(): Int {
        return try {
            mediaRecorder?.maxAmplitude ?: 0
        } catch (_: Exception) {
            0
        }
    }

    private fun playRecordedMicInternal(): Boolean {
        val file = audioRecordFile ?: return false
        if (!file.exists()) return false
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(file.absolutePath)
                prepare()
                start()
            }
            return true
        } catch (_: Exception) {
            return false
        }
    }
}
