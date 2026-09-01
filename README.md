# Biters

**El pozo de nosotros dos, para cenas y salidas.**

App Android (Flutter + Firebase) para llevar el fondo compartido de pareja para
salidas, y el fondo personal privado de cada uno para sus propios gastos.

- Diseño de referencia: [`docs/Biters_Diseno_App.pdf`](docs/Biters_Diseno_App.pdf) (18 pantallas, paleta, tipografía).
- Backend: Firebase (Auth + Firestore + Storage), plan Spark (gratis), **sin Cloud Functions**.
- Distribución: APK firmado, publicado automáticamente en [Releases](../../releases) por GitHub Actions. No pasa por Google Play.

---

## Índice

- [Cómo instalar el APK](#cómo-instalar-el-apk)
- [Primeros pasos en la app](#primeros-pasos-en-la-app)
- [Seguridad — qué es seguro exponer en este repo público y qué no](#seguridad)
- [Arquitectura y modelo de datos](#arquitectura-y-modelo-de-datos)
- [Desarrollo local](#desarrollo-local)
- [CI/CD](#cicd)

---

## Cómo instalar el APK

1. Andá a la pestaña [**Releases**](../../releases) de este repositorio.
2. Descargá el `.apk` de la última versión (`biters-latest.apk` o `biters-vX.Y.Z.apk`).
3. En tu Android: **Configuración → Seguridad → Instalar apps desconocidas** (el texto exacto varía según el fabricante) → habilitá esa opción para la app que usaste para descargar el archivo (Chrome, Archivos, etc.).
4. Abrí el APK descargado y confirmá la instalación.

Android va a advertirte que es una app fuera de Play Store — es esperado, es
como se distribuye Biters a propósito (ver sección de Seguridad más abajo
sobre por qué esto no compromete tus datos).

## Primeros pasos en la app

1. **Crear cuenta**: nombre, email, contraseña (mínimo 8 caracteres).
2. **Verificar el email**: te llega un correo de Firebase; la app te va a
   pedir que lo confirmes antes de dejarte usar nada (botón "Ya lo
   verifiqué" una vez que lo hiciste).
3. Al verificar, se te crea automáticamente tu **"Mi fondo"** personal
   (vacío).
4. Para armar el fondo compartido **"Nosotros"**: desde Perfil → "Invitar a
   tu pareja", generás un código de 6 dígitos (vence en 24hs) y se lo
   mandás por WhatsApp/SMS con el botón de compartir.
5. Tu pareja, ya con su propia cuenta creada y verificada, va a "Unirme a un
   fondo" e ingresa el código. Listo: quedan compartiendo "Nosotros", sin
   perder cada uno su fondo personal privado.

---

## Seguridad

El código de este repositorio es **público**. Eso es intencional y no
compromete la seguridad de la app, porque la protección real no depende de
ocultar nada del cliente, sino de reglas del lado del servidor. Detalle:

### Qué SÍ es seguro que esté en este repo

- **`android/app/google-services.json`**: el `apiKey` de Firebase que contiene
  **no es un secreto**. Identifica de qué proyecto de Firebase es la app,
  pero no otorga ningún permiso por sí solo — quien intente usarlo para leer
  o escribir datos choca con las [Reglas de Firestore](firebase/firestore.rules)
  y de [Storage](firebase/storage.rules), que son las que de verdad deciden
  quién puede leer o escribir qué. Google [documenta esto explícitamente](https://firebase.google.com/docs/projects/api-keys).

### Qué NUNCA está en este repo

- El keystore de firma (`*.jks` / `*.keystore`).
- `android/key.properties` (contraseñas del keystore).
- Cualquier credencial de Firebase Admin SDK / service account.

Todos estos están excluidos en [`.gitignore`](.gitignore). El keystore y sus
contraseñas viven únicamente como **GitHub Actions Secrets** (encriptados),
usados solo durante el build en `.github/workflows/build-release.yml`. Ver
[`docs/KEYSTORE.md`](docs/KEYSTORE.md) para el paso a paso de cómo se generó
y cargó.

### Reglas de Firestore — resumen

Ver el archivo completo comentado en [`firebase/firestore.rules`](firebase/firestore.rules).
Denegar todo por defecto, habilitar caso por caso:

- `users/{uid}`: cada quien lee/escribe únicamente su propio documento.
- `funds/{fundId}`: solo lectura/escritura para los uids listados en
  `members`. El fondo personal se crea automáticamente (1 miembro = el
  dueño); el fondo compartido solo se crea como parte del canje válido de
  un código de invitación (verificado server-side contra `invites/{code}`,
  no contra lo que mande el cliente).
- `funds/{fundId}/transactions/{id}`: solo miembros del fondo padre, con
  validación de tipos/rangos (montos numéricos positivos con tope,
  descripciones con largo máximo).
- `invites/{code}`: **sin `list`** — nadie puede enumerar códigos vigentes,
  solo hacer `get` de un código puntual. Un código solo es legible si no
  venció y no fue usado; el canje lo marca `used` de forma atómica.

### Reglas de Storage — resumen

Ver [`firebase/storage.rules`](firebase/storage.rules). Cada usuario solo
puede escribir en `avatars/{su-propio-uid}/`, con validación de tipo de
archivo (jpg/png/webp) y tamaño máximo (5 MB).

### App Check

Preparado con `firebase_app_check`, arrancando en **modo debug-token**
(decisión consciente para no requerir una cuenta de Google Play Console de
entrada). En este modo, App Check no bloquea nada por sí solo — la
protección real sigue siendo 100% las reglas de arriba. El día que se quiera
pasar a Play Integrity enforced, es un cambio de configuración, documentado
en [`docs/APP_CHECK.md`](docs/APP_CHECK.md).

---

## Arquitectura y modelo de datos

Ver [`docs/MODELO_DE_DATOS.md`](docs/MODELO_DE_DATOS.md) para el detalle de
colecciones de Firestore (`users`, `funds`, `funds/{id}/transactions`,
`funds/{id}/categories`, `invites`).

## Desarrollo local

```bash
flutter pub get
flutter run
```

Requiere `android/app/google-services.json` (ya incluido en este repo — ver
sección de Seguridad sobre por qué es seguro) y `android/key.properties`
**solo** si vas a generar un build release firmado localmente (no hace
falta para `flutter run` en debug).

## CI/CD

Cada push a `main` compila un APK release firmado y lo publica como el
Release `latest` (siempre se sobreescribe con la build más reciente). Cada
tag `vX.Y.Z` genera además un Release versionado y permanente. Ver
[`.github/workflows/build-release.yml`](.github/workflows/build-release.yml).
