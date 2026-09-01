# Modelo de datos (Firestore)

## `users/{uid}`

| Campo | Tipo | Notas |
|---|---|---|
| `nombre` | string | editable desde Perfil |
| `email` | string | de Firebase Auth |
| `fotoUrl` | string? | `Storage: avatars/{uid}/...` |
| `fechaCreacion` | timestamp | |
| `fondoPersonalId` | string | fund creado automáticamente al verificar el email |
| `fondoCompartidoId` | string? | reservado la primera vez que se genera un código de invitación (ver abajo); `null` hasta entonces |
| `tema` | string | `"claro" \| "oscuro" \| "auto"` |

## `funds/{fundId}`

| Campo | Tipo | Notas |
|---|---|---|
| `tipo` | string | `"personal" \| "compartido"` |
| `members` | array\<uid\> | tamaño 1 (personal) o 2 (compartido) |
| `fechaCreacion` | timestamp | |
| `creadoConCodigo` | string? | solo en fondos compartidos: el código de invitación que se canjeó para crearlo. Se usa server-side para validar la creación (ver `firestore.rules`); también se muestra en Perfil como "Miembro desde". |

### Por qué el fondo compartido se crea "tarde"

Según el brief: *"Nosotros" no se crea solo, se genera cuando alguien invita
y el otro se une.* Para que esto funcione sin Cloud Functions, ni dejar
huecos de seguridad:

1. La primera vez que un usuario toca "Invitar a tu pareja", el cliente
   genera un **id de documento reservado** (`fondoCompartidoId`, vía
   `FirebaseFirestore.instance.collection('funds').doc().id` — no escribe el
   documento, solo reserva el id) y lo guarda en `users/{uid}.fondoCompartidoId`.
2. Si el código vence sin usarse y el usuario genera uno nuevo, se reutiliza
   el mismo `fondoCompartidoId` ya reservado (no se pisan ids).
3. Recién cuando el otro usuario **canjea** el código, se crea de verdad el
   documento `funds/{fondoCompartidoId}` con `members: [creador, joiner]`,
   en la misma operación que marca el `invite` como usado. La regla de
   Firestore valida ese `create` contra el invite real (ver
   `firebase/firestore.rules`).

## `funds/{fundId}/transactions/{transactionId}`

| Campo | Tipo | Notas |
|---|---|---|
| `tipo` | string | `"gasto" \| "ingreso" \| "deposito"` |
| `monto` | number | > 0, tope 500.000.000 Gs. |
| `descripcion` | string | máx. 140 caracteres |
| `categoria` | string | libre, base + custom por fondo |
| `modo` | string? | solo en `gasto`: `"rapido" \| "detallado"` |
| `items` | array\<{subcategoria, monto}\>? | solo si `modo == "detallado"` |
| `registradoPor` | uid | quien cargó el movimiento (inmutable tras crear) |
| `registradoPorNombre` | string | nombre desnormalizado — evita depender de leer `users/{uid}` de otro miembro |
| `depositante` | uid? | solo en `deposito`; en fondo personal siempre el propio uid |
| `fecha` | timestamp | fecha/hora del movimiento |
| `mesReferencia` | string | `"YYYY-MM"`, derivado de `fecha`, define el ciclo mensual |
| `createdAt` / `updatedAt` | timestamp | auditoría |

`ingreso` solo es válido si el fondo padre es `tipo == "personal"` (validado
en las reglas).

**Saldo disponible del mes** = suma de `deposito` (+ `ingreso` si es fondo
personal) − suma de `gasto`, filtrando por `mesReferencia == mes actual`.
Se recalcula en tiempo real vía un listener (`snapshots()`) sobre la
subcolección, sin necesidad de refrescar manualmente.

## `funds/{fundId}/categories/config`

Documento único por fondo con las categorías custom agregadas por sus
miembros (además de una lista base predefinida en el cliente, igual para
todos los fondos, que no necesita estar en Firestore).

| Campo | Tipo |
|---|---|
| `gastoCategorias` | array\<{nombre, icono}\> |
| `ingresoCategorias` | array\<{nombre, icono}\> (solo se usa en fondo personal) |

## `invites/{codigoDe6Digitos}`

El **id del documento es el código mismo** (string de 6 dígitos), no un id
autogenerado — así `get(/invites/{code})` es una lectura puntual directa.

| Campo | Tipo | Notas |
|---|---|---|
| `fundIdDestino` | string | el `fondoCompartidoId` reservado del creador |
| `creadoPor` | uid | quien invita |
| `expiresAt` | timestamp | `fechaCreacion + 24h` |
| `used` | bool | arranca en `false` |
| `usedBy` | uid? | quien canjeó el código |
| `fechaCreacion` | timestamp | |

La colección **no admite `list`** (ver reglas) — es la única forma de evitar
que alguien enumere o descargue todos los códigos vigentes desde un cliente
con la config pública de Firebase.
