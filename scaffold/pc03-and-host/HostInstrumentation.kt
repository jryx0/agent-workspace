package app.pcryoxy.andhost

import android.app.Activity
import android.app.Instrumentation
import android.content.Context
import android.os.Bundle
import app.pcryoxy.secure.SecretStoreDeviceChecks
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore

class HostInstrumentation : Instrumentation() {
    private var phase: String? = null

    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        phase = arguments?.getString("phase")
    }

    override fun onStart() {
        val selectedPhase = phase
        val result = Bundle()
        result.putString("phase", selectedPhase ?: "missing")

        try {
            when (selectedPhase) {
                "prepare" -> prepare(targetContext)
                "verify" -> verify(targetContext)
                "cleanup" -> cleanup(targetContext)
                else -> throw IllegalArgumentException("invalid_phase")
            }
            result.putString("result", "PASS")
            finish(Activity.RESULT_OK, result)
        } catch (error: Exception) {
            result.putString("result", "FAIL")
            result.putString("errorClass", error.javaClass.simpleName)
            finish(Activity.RESULT_CANCELED, result)
        }
    }

    private fun prepare(context: Context) {
        val state = stateFile(context)
        check(!state.exists())
        val proof = SecretStoreDeviceChecks.prepare(context)
        try {
            val namespace = proof.namespace.toByteArray(Charsets.US_ASCII)
            check(namespace.size == NAMESPACE_BYTES)
            FileOutputStream(state).use { output ->
                output.write(namespace)
                output.write(proof.version)
                output.fd.sync()
            }
        } catch (error: Exception) {
            SecretStoreDeviceChecks.cleanup(context, proof)
            throw error
        }
    }

    private fun verify(context: Context) {
        SecretStoreDeviceChecks.verify(context, readProof(context))
    }

    private fun cleanup(context: Context) {
        val proof = readProof(context)
        SecretStoreDeviceChecks.cleanup(context, proof)

        val keys = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        for (suffix in listOf("aes", "hmac")) {
            check(!keys.containsAlias("pCryoxy.secure.v1.${proof.namespace}.$suffix"))
        }
        check(!File(context.noBackupFilesDir, proof.namespace).exists())
        check(stateFile(context).delete())
    }

    private fun readProof(context: Context): SecretStoreDeviceChecks.Proof {
        val bytes = stateFile(context).readBytes()
        check(bytes.size == NAMESPACE_BYTES + VERSION_BYTES)
        val namespace = String(bytes, 0, NAMESPACE_BYTES, Charsets.US_ASCII)
        check(namespace.matches(Regex("pc03test-[a-f0-9]{32}")))
        val version = bytes.copyOfRange(NAMESPACE_BYTES, bytes.size)
        return SecretStoreDeviceChecks.Proof(namespace, version)
    }

    private fun stateFile(context: Context): File =
        File(context.noBackupFilesDir, STATE_FILE)

    private companion object {
        const val STATE_FILE = "pc03-host-proof.bin"
        const val NAMESPACE_BYTES = 41
        const val VERSION_BYTES = 16
    }
}
