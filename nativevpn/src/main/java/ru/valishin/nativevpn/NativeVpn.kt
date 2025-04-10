package ru.valishin.nativevpn

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import java.io.File
import java.io.IOException

class NativeVpn(private val applicationInfo: ApplicationInfo, private val context: Context) {
    companion object {
        private const val TAG = "NativeVpn"
        private const val HAMCORE_FILENAME = "hamcore_se2_v${BuildConfig.SOFTETHERVPN_VERSION}"
        private const val SE_TMP_DIR = "se_tmp"
        private const val SE_DB_DIR = "se_db"

        init {
            System.loadLibrary("nativevpn")
        }
    }

    private val executablePath: String = "${applicationInfo.nativeLibraryDir}/libnativevpn.so"
    private val temporaryDir: String = "${context.cacheDir.absolutePath}/$SE_TMP_DIR"
    private val databaseDir: String = "${context.filesDir.absolutePath}/$SE_DB_DIR"

    init {
        initializeDirectories()
    }

    private fun initializeDirectories() {
        try {
            setTemporaryDirectory(temporaryDir)
            setLogDirectory(temporaryDir)
            setDatabaseDirectory(databaseDir)
            copyHamcore()
        } catch (e: IOException) {
            Log.e(TAG, "Failed to initialize VPN directories", e)
            throw VpnInitializationException("Failed to initialize VPN", e)
        }
    }

    private fun copyHamcore() {
        try {
            File(temporaryDir).mkdirs()
            val hamcoreFile = File(temporaryDir, HAMCORE_FILENAME)
            
            if (!hamcoreFile.exists()) {
                val resourceId = try {
                    context.resources.getIdentifier(
                        HAMCORE_FILENAME,
                        "raw",
                        context.packageName
                    )
                } catch (e: Exception) {
                    throw VpnInitializationException("Failed to find hamcore resource for version ${HAMCORE_FILENAME}", e)
                }

                context.resources.openRawResource(resourceId).use { input ->
                    hamcoreFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
            }
            Thread {
                try {
                    File(temporaryDir).listFiles()?.forEach { file ->
                        if (file.name.startsWith("hamcore_se2_v") && file.name != HAMCORE_FILENAME) {
                            file.delete()
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to clean up old hamcore files", e)
                }
            }.start()
        } catch (e: IOException) {
            Log.e(TAG, "Failed to copy hamcore file", e)
            throw VpnInitializationException("Failed to copy hamcore file", e)
        }
    }

    external fun closeFd(fd: Int)

    private external fun setTemporaryDirectory(dir: String)
    private external fun setLogDirectory(dir: String)
    private external fun setDatabaseDirectory(dir: String)
    private external fun nativeStartVpnClient(args: Array<String>)

    @JvmOverloads
    fun startVpnClient(additionalArgs: Array<String> = emptyArray()) {
        try {
            val args = arrayOf(executablePath) + additionalArgs
            nativeStartVpnClient(args)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN client", e)
            throw VpnStartException("Failed to start VPN client", e)
        }
    }

    class VpnInitializationException(message: String, cause: Throwable? = null) :
        RuntimeException(message, cause)

    class VpnStartException(message: String, cause: Throwable? = null) :
        RuntimeException(message, cause)
}
