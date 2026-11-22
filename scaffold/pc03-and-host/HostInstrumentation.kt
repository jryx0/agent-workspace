package app.pcryoxy.andhost

import android.app.Activity
import android.app.Instrumentation
import android.content.Context
import android.os.Bundle
import android.util.Base64
import app.pcryoxy.secure.SecretStoreDeviceChecks
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore

class HostInstrumentation : Instrumentation() {
    private var phase: String? = null
    private var arguments: Bundle? = null

    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        this.arguments = arguments
        phase = arguments?.getString("phase")
        start()
    }

    override fun onStart() {
        val selectedPhase = phase
        val result = Bundle()
        result.putString("phase", selectedPhase ?: "missing")

        try {
            when (selectedPhase) {
                "prepare" -> {
                    val proof = prepare(targetContext)
                    result.putString("namespace", proof.namespace)
                    result.putString("ciphertextSha256", proof.ciphertextSha256)
                }
                "verify" -> result.putString(
                    "ciphertextSha256",
                    SecretStoreDeviceChecks.verify(targetContext, readProof(targetContext))
                )
                "export-ct" -> {
                    val proof = readProof(targetContext)
                    val ciphertext = SecretStoreDeviceChecks.exportCiphertext(targetContext, proof)
                    result.putString("ciphertextSha256", sha256(ciphertext))
                    result.putString("ciphertextBase64", Base64.encodeToString(ciphertext, Base64.NO_WRAP))
                }
                "probe-old-ct" -> {
                    val namespace = arguments?.getString("namespace") ?: error("missing_namespace")
                    val expectedSha256 = arguments?.getString("sha256") ?: error("missing_sha256")
                    val encoded = arguments?.getString("ciphertextBase64") ?: error("missing_ciphertext")
                    val probe = SecretStoreDeviceChecks.probeOldCiphertext(
                        targetContext,
                        namespace,
                        Base64.decode(encoded, Base64.DEFAULT),
                        expectedSha256
                    )
                    result.putString("ciphertextSha256", probe.ciphertextSha256)
                    result.putInt("failureCode", probe.failureCode)
                }
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

    private fun prepare(context: Context): SecretStoreDeviceChecks.Proof {
        val state = stateFile(context)
        check(!state.exists())
        val proof = SecretStoreDeviceChecks.prepare(context)
        try {
            val namespace = proof.namespace.toByteArray(Charsets.US_ASCII)
            check(namespace.size == NAMESPACE_BYTES)
            FileOutputStream(state).use { output ->
                output.write(namespace)
                output.write(proof.version)
                output.write(proof.ciphertextSha256.toByteArray(Charsets.US_ASCII))
                output.fd.sync()
            }
            return proof
        } catch (error: Exception) {
            SecretStoreDeviceChecks.cleanup(context, proof)
            throw error
        }
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
        check(bytes.size == NAMESPACE_BYTES + VERSION_BYTES + HASH_BYTES)
        val namespace = String(bytes, 0, NAMESPACE_BYTES, Charsets.US_ASCII)
        check(namespace.matches(Regex("pc03test-[a-f0-9]{32}")))
        val versionEnd = NAMESPACE_BYTES + VERSION_BYTES
        val versionProof = bytes.copyOfRange(NAMESPACE_BYTES, versionEnd)
        val hash = String(bytes, versionEnd, HASH_BYTES, Charsets.US_ASCII)
        check(hash.matches(Regex("[a-f0-9]{64}")))
        return SecretStoreDeviceChecks.Proof(namespace, versionProof, hash)
    }

    private fun stateFile(context: Context): File =
        File(context.noBackupFilesDir, STATE_FILE)

    private fun sha256(bytes: ByteArray): String =
        java.security.MessageDigest.getInstance("SHA-256").digest(bytes)
            .joinToString("") { "%02x".format(it.toInt() and 255) }

    private companion object {
        const val STATE_FILE = "pc03-host-proof.bin"
        const val NAMESPACE_BYTES = 41
        const val VERSION_BYTES = 16
        const val HASH_BYTES = 64
    }
}
