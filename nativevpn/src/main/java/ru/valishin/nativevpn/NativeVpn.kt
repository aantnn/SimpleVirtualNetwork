package ru.valishin.nativevpn

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import java.io.File
import java.io.IOException

class NativeVpn(private val applicationInfo: ApplicationInfo, private val context: Context) {
    companion object {
        private const val TAG = "NativeVpn"
        private const val HAMCORE_FILENAME = "hamcore_se2_${BuildConfig.SOFTETHERVPN_VERSION}"
        private const val TARGET_HAMCORE_FILENAME = "hamcore.se2"
        private const val HAMCORE_VERSION_FILENAME = "hamcore_version.txt"
        private const val SE_TMP_DIR = "se_tmp"
        private const val SE_DB_DIR = "se_db"

        init {
            System.loadLibrary("nativevpn")
        }
    }
    private val currentApkHamcoreResourceName = "hamcore_se2_${BuildConfig.SOFTETHERVPN_VERSION}"

    private val executablePath: String = "${applicationInfo.nativeLibraryDir}/libnativevpn.so"
    private val temporaryDir: String = "${context.cacheDir.absolutePath}/$SE_TMP_DIR"
    private val databaseDir: String = "${context.filesDir.absolutePath}/$SE_DB_DIR"

    init {
        initializeDirectories()
    }

    private fun initializeDirectories() {
        try {
            File(temporaryDir).mkdirs()
            setTemporaryDirectory(temporaryDir)
            setLogDirectory(temporaryDir)
            setDatabaseDirectory(databaseDir)
            copyHamcore()
        } catch (e: IOException) {
            Log.e(TAG, "Failed to initialize VPN directories", e)
            throw VpnInitializationException("Failed to initialize VPN", e)
        } catch (e: Exception) { // Catch other potential exceptions during init
            Log.e(TAG, "Unexpected error during VPN initialization", e)
            throw VpnInitializationException("Unexpected error during VPN initialization", e)
        }
    }

    private fun copyHamcore() {
        val targetHamcoreFile = File(temporaryDir, "hamcore.se2")
        val versionFile = File(temporaryDir, "hamcore_se2.ver")
        val currentApkVersion = BuildConfig.SOFTETHERVPN_VERSION
        try {
            var shouldCopy = true // Assume we need to copy by default

            if (targetHamcoreFile.exists() && versionFile.exists()) {
                val storedVersion = versionFile.readText().trim()
                if (storedVersion == currentApkVersion) {
                    Log.i(TAG, "Hamcore version $currentApkVersion is already up to date.")
                    shouldCopy = false
                } else {
                    Log.i(TAG, "Hamcore update detected. Stored: $storedVersion, APK: $currentApkVersion. Will replace.")
                }
            } else {
                Log.i(TAG, "No existing hamcore or version file found. Will copy from APK.")
            }

            if (shouldCopy) {
                Log.d(TAG, "Attempting to copy hamcore resource: $currentApkHamcoreResourceName to $TARGET_HAMCORE_FILENAME")
                val resourceId = try {
                    context.resources.getIdentifier(
                        currentApkHamcoreResourceName, // Use the dynamically constructed resource name
                        "raw",
                        context.packageName
                    )
                } catch (e: android.content.res.Resources.NotFoundException) {
                    Log.e(TAG, "Hamcore resource not found in APK: $currentApkHamcoreResourceName", e)
                    throw VpnInitializationException("Failed to find hamcore resource $currentApkHamcoreResourceName in APK", e)
                } catch (e: Exception) {
                    Log.e(TAG, "Error getting identifier for hamcore resource $currentApkHamcoreResourceName", e)
                    throw VpnInitializationException("Error finding hamcore resource $currentApkHamcoreResourceName", e)
                }

                if (resourceId == 0) {
                    Log.e(TAG, "Hamcore resource $currentApkHamcoreResourceName not found (ID was 0). Package: ${context.packageName}")
                    throw VpnInitializationException("Hamcore resource $currentApkHamcoreResourceName not found in APK (ID was 0)")
                }

                Log.d(TAG, "Resource ID for $currentApkHamcoreResourceName is $resourceId")

                context.resources.openRawResource(resourceId).use { inputStream ->
                    targetHamcoreFile.outputStream().use { outputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
                // Update the version file with the new version
                versionFile.writeText(currentApkVersion)
                Log.i(TAG, "Successfully copied hamcore $currentApkHamcoreResourceName to $TARGET_HAMCORE_FILENAME and updated version to $currentApkVersion.")
            }


        } catch (e: IOException) {
            Log.e(TAG, "IOException during hamcore copy/versioning process for $currentApkHamcoreResourceName", e)
            throw VpnInitializationException("Failed to copy/version hamcore file due to IO error", e)
        } catch (e: VpnInitializationException) {
            // Re-throw specific exceptions if already a VpnInitializationException
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during hamcore copy/versioning for $currentApkHamcoreResourceName", e)
            throw VpnInitializationException("An unexpected error occurred during hamcore setup", e)
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
