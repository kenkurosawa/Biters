# Keystore de firma y Secrets de GitHub Actions

El keystore (`.jks`) es el certificado que firma cada build release de
Biters. **Nunca va al repositorio** — si lo perdés (el archivo o la
contraseña), no vas a poder publicar una actualización de la app bajo el
mismo `applicationId` sin desinstalarla y reinstalarla desde cero en cada
teléfono, así que hacé una copia de respaldo del archivo `.jks` y de sus
contraseñas en un lugar seguro fuera de este repo (Drive, gestor de
contraseñas, etc.), apenas se genere.

## 1. Generar el keystore

```bash
keytool -genkeypair -v \
  -keystore biters-release.jks \
  -alias biters \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "<STORE_PASSWORD>" \
  -keypass "<KEY_PASSWORD>" \
  -J-Dkeystore.pkcs12.legacy=true
```

Va a pedir algunos datos (nombre, organización, país) — se pueden dejar
genéricos, no afectan la seguridad. El archivo resultante (`biters-release.jks`)
se guarda **fuera del control de versiones** (está en `.gitignore`).

> **`-J-Dkeystore.pkcs12.legacy=true` es obligatorio.** Sin este flag, JDKs
> recientes (17+) generan el PKCS12 con un cifrado más nuevo que el
> parser de firma que usa Android Gradle Plugin en los runners de GitHub
> Actions no puede leer — el build falla en `:app:packageRelease` con
> `KeytoolException: ... Tag number over 30 is not supported`. Con el flag,
> el keystore queda en el formato PKCS12 "legacy" compatible con todo.
> (Nos pasó en el primer intento de este proyecto: quedó documentado acá
> para no repetir el error si algún día hay que regenerar el keystore.)

## 2. Configurar `android/key.properties` (local, nunca se commitea)

```properties
storePassword=<STORE_PASSWORD>
keyPassword=<KEY_PASSWORD>
keyAlias=biters
storeFile=../../biters-release.jks
```

`android/app/build.gradle` está configurado para leer este archivo si
existe y firmar el build release con él; si no existe, cae al firmado debug
(para que `flutter run`/`flutter build apk --debug` sigan funcionando sin
necesidad de este archivo).

## 3. Cargar los Secrets en GitHub Actions

`Settings → Secrets and variables → Actions → New repository secret` (o con
`gh secret set`, una vez autenticado):

| Secret | Valor |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 biters-release.jks` (el archivo entero, codificado) |
| `KEYSTORE_PASSWORD` | el `storePassword` |
| `KEY_PASSWORD` | el `keyPassword` |
| `KEY_ALIAS` | `biters` |

Con `gh` autenticado:

```bash
gh secret set KEYSTORE_BASE64 --body "$(base64 -w0 biters-release.jks)"
gh secret set KEYSTORE_PASSWORD --body "<STORE_PASSWORD>"
gh secret set KEY_PASSWORD --body "<KEY_PASSWORD>"
gh secret set KEY_ALIAS --body "biters"
```

Estos Secrets viajan encriptados y solo se descifran dentro del runner de
GitHub Actions durante el build (`.github/workflows/build-release.yml`),
nunca quedan expuestos en logs ni en el repo.

## 4. Obtener la huella SHA-256 (para Play Integrity más adelante)

```bash
keytool -list -v -keystore biters-release.jks -alias biters -storepass "<STORE_PASSWORD>"
```

Copiar el `SHA256:` que imprime — se usa al registrar la app en Firebase
App Check con el proveedor Play Integrity (ver `docs/APP_CHECK.md`).
