# Firebase App Check

## Estado actual: modo debug-token (indefinido)

Se decidió no crear todavía una cuenta de Google Play Console (pago único de
USD 25) necesaria para el proveedor Play Integrity. Mientras tanto, App
Check corre en **modo debug-token**.

**Importante para entender la seguridad real de la app:** en modo
debug-token, App Check no bloquea nada — es solo para desarrollo. La
protección real contra accesos no autorizados a Firestore/Storage sigue
siendo, 100%, las [Reglas de Firestore](../firebase/firestore.rules) y de
[Storage](../firebase/storage.rules). App Check es una capa **adicional**
que se suma después, no la que reemplaza a las reglas.

## Cómo migrar a Play Integrity (enforced) más adelante

Cuando tengan la cuenta de Play Console:

1. **Registrar la app en Play Console** (no hace falta publicarla):
   - Play Console → Crear app → completar nombre "Biters", tipo app,
     gratis. Se puede dejar en el track **Interno** (testing) sin publicar
     nunca a producción — alcanza para que Play Integrity emita verdicts
     válidos.
   - Subir el primer APK release firmado (el que genera GitHub Actions) al
     track interno, aunque sea solo para un tester interno (ustedes
     mismos).
   - Google necesita algunos días para "vincular" la app en Play Integrity
     tras el primer upload.

2. **En Firebase Console → App Check**:
   - Registrar la app Android con el proveedor **Play Integrity**.
   - Copiar el nombre de paquete (`com.biters.app`) y la huella SHA-256 del
     certificado de firma release (la misma que se registra en Firebase
     Auth/Play Console — ver `docs/KEYSTORE.md` para cómo obtenerla con
     `keytool -list -v`).

3. **En el código** (`lib/firebase_app_check_setup.dart` o donde se
   inicialice): cambiar el provider de `AndroidProvider.debug` a
   `AndroidProvider.playIntegrity`.

4. **En Firebase Console → App Check → Firestore / Storage**: pasar el
   modo de "No aplicado" a **"Aplicado" (enforced)** recién después de
   confirmar que la app real (compilada y firmada con el keystore de
   producción) obtiene tokens válidos — probarlo primero en modo
   "monitoreado" (metrics) antes de aplicar, para no bloquear a los propios
   usuarios por error.

5. Quitar cualquier debug token que se haya registrado para desarrollo
   (Firebase Console → App Check → Apps → Administrar tokens de depuración).
