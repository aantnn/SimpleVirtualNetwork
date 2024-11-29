package ru.valishin.nativevpn

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import java.io.File
import java.io.IOException

class NativeVpn(private val applicationInfo: ApplicationInfo, private val context: Context) {
    companion object {
        private const val TAG = "NativeVpn"
        private const val HAMCORE_FILENAME = "hamcore.se2.so"
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
            setTmpDir(temporaryDir)
            setLogDir(temporaryDir)
            setDbDir(databaseDir)
            copyHamcore()
        } catch (e: IOException) {
            Log.e(TAG, "Failed to initialize VPN directories", e)
            throw VpnInitializationException("Failed to initialize VPN", e)
        }
    }

    private fun copyHamcore() {
        try {
            File(temporaryDir).mkdirs()
            context.resources.openRawResource(R.raw.hamcore).use { input ->
                File(temporaryDir, HAMCORE_FILENAME).apply {
                    outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
            }
        } catch (e: IOException) {
            Log.e(TAG, "Failed to copy hamcore file", e)
            throw VpnInitializationException("Failed to copy hamcore file", e)
        }
    }

    external fun closeFd(fd: Int)

    private external fun setTmpDir(dir: String)
    private external fun setLogDir(dir: String)
    private external fun setDbDir(dir: String)
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
