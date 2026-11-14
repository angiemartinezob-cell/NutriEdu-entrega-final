# NutriEdu · Módulo de catálogo y recomendación personalizada de recetas

API REST del módulo de **recetas personalizadas** de NutriEdu. Está construida con **arquitectura hexagonal (puertos y adaptadores)** en TypeScript, Express y PostgreSQL.

El módulo permite:

- **Administrar el catálogo de recetas:** crear, consultar, actualizar, publicar o archivar y eliminar.
- **Recomendar recetas a cada usuario** según sus restricciones, metas nutricionales y objetivo, explicando el porqué de cada recomendación.

| Documento | Ubicación |
|---|---|
| **Aplicación web (interfaz visual)** | **http://localhost:3000** (con la API en ejecución) |
| Documentación interactiva de la API (Swagger UI) | **http://localhost:3000/api-docs** (con la API en ejecución) |
| Especificación OpenAPI 3 | [`docs/openapi.yaml`](docs/openapi.yaml) · `http://localhost:3000/api-docs/openapi.json` |
| Colección de Postman (flujo de la sustentación) | [`docs/NutriEdu-Recetas.postman_collection.json`](docs/NutriEdu-Recetas.postman_collection.json) |
| Documento de arquitectura | [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) |
| Guía de sustentación | [`docs/GUIA_SUSTENTACION.md`](docs/GUIA_SUSTENTACION.md) |

---

## 1. Requisitos

| Herramienta | Versión | Comprobar |
|---|---|---|
| Node.js | 20 o superior (probado con 22) | `node -v` |
| npm | 10 o superior | `npm -v` |
| PostgreSQL | 14 o superior (probado con 16) | `psql --version` |
| Docker Desktop *(opcional, alternativa B)* | 24 o superior | `docker -v` |

## 2. Instalación y ejecución

### Alternativa A: Node.js + PostgreSQL local (recomendada)

```bash
# 1. Instalar dependencias
npm install

# 2. Crear el archivo de configuración
cp .env.example .env          # En Windows (cmd): copy .env.example .env

# 3. Crear la base de datos (o créela desde pgAdmin con el nombre nutriedu_recetas)
psql -U postgres -c "CREATE DATABASE nutriedu_recetas"
```

Si su usuario o contraseña de PostgreSQL no son `postgres`/`postgres`, edite `DB_USER` y `DB_PASSWORD` en `.env`.

```bash
# 4. Crear las tablas y cargar los datos de ejemplo
npm run db:setup

# 5. Iniciar la API
npm run dev
```

La consola debe mostrar:

```
NutriEdu · API de recetas escuchando en http://localhost:3000
Documentación Swagger: http://localhost:3000/api-docs
Persistencia: postgres
```

### Alternativa B: Docker Compose (sin instalar PostgreSQL)

```bash
docker compose up --build
```

Este comando levanta PostgreSQL 16 y la API. Al arrancar, aplica las migraciones y carga los datos de ejemplo. La API queda en http://localhost:3000/api-docs. Para detener: `docker compose down` (con `-v` también se borran los datos).

### Alternativa C: modo en memoria (solo para pruebas rápidas)

```bash
npm install
cp .env.example .env
npm run dev:memory
```

Usa los adaptadores en memoria en lugar de PostgreSQL. Los datos se pierden al detener la API. Este modo demuestra que el núcleo no depende de la base de datos.

### Usar la aplicación web

Con la API en ejecución, abra **http://localhost:3000**. La interfaz se sirve desde la misma API, así que no hay que instalar nada más.

- **Usuarios (Ana, Luis, Sofía, Carlos):**
  - En *Para ti* aparecen las recomendaciones con su puntaje, las razones y las advertencias, junto al perfil y las restricciones de cada uno.
  - En *Recetario* se abre cualquier receta y se ve si es apta. Si no lo es, aparece el sello "No apta para ti" con el ingrediente que causa el conflicto.
- **Administrador:**
  - Tabla del catálogo para crear, editar, publicar, archivar y eliminar recetas.
  - El formulario calcula en vivo si las calorías cuadran con los macronutrientes (regla R2).
  - Los errores de la API (409, 422) se muestran con su código y su explicación.

La interfaz está en `public/` (HTML, CSS y JavaScript sin dependencias). Es un cliente más de la API, igual que Swagger o Postman, y no contiene reglas de negocio.

### Verificar que funciona

```bash
curl http://localhost:3000/health
# {"status":"ok","persistence":"postgres","database":"up"}
```

## 3. Usuarios de ejemplo

| Correo | Contraseña | Rol | Perfil alimentario |
|---|---|---|---|
| admin@nutriedu.co | `Admin123*` | admin | — |
| ana@nutriedu.co | `Ana12345*` | user | Celíaca → sin gluten · objetivo pérdida de grasa · 4 comidas · 30 min máx. |
| luis@nutriedu.co | `Luis12345*` | user | Vegetariano + alergia al maní · objetivo masa muscular · 5 comidas |
| sofia@nutriedu.co | `Sofia12345*` | user | Vegana · objetivo cardiometabólico |
| carlos@nutriedu.co | `Carlos12345*` | user | Sin perfil (usa el perfil neutro) |

Las credenciales son solo para el entorno local de demostración.

**Cómo autenticarse en Swagger:**

1. Ejecute `POST /auth/login`.
2. Copie el `accessToken`.
3. Pulse **Authorize** y pegue el token.

## 4. Endpoints

Base: `http://localhost:3000/api/v1`. Todos requieren `Authorization: Bearer <token>`, excepto el inicio de sesión.

| Método | Ruta | Rol | Descripción | Códigos |
|---|---|---|---|---|
| POST | `/auth/login` | público | Inicia sesión y devuelve un JWT | 200, 400, 401, 429 |
| GET | `/recipes` | user/admin | Lista con filtros (`mealType`, `q`, `maxPrepTime`, `status`) y paginación | 200, 400, 401 |
| GET | `/recipes/{id}` | user/admin | Consulta una receta | 200, 400, 401, 404 |
| POST | `/recipes` | admin | Crea una receta (queda en `draft`) | 201, 400, 401, 403, 409, 422 |
| PUT | `/recipes/{id}` | admin | Reemplaza los datos de una receta | 200, 400, 401, 403, 404, 409, 422 |
| PATCH | `/recipes/{id}/status` | admin | Publica, archiva o devuelve a borrador | 200, 400, 401, 403, 404, 409, 422 |
| DELETE | `/recipes/{id}` | admin | Elimina (solo `draft` o `archived`) | 204, 401, 403, 404, 409 |
| GET | `/recipes/recommendations` | user/admin | Ranking personalizado y explicable | 200, 400, 401 |
| GET | `/recipes/{id}/compatibility` | user/admin | ¿Es compatible esta receta conmigo? | 200, 400, 401, 404 |
| GET | `/ingredients` | user/admin | Catálogo de ingredientes y sus restricciones | 200, 401 |

Además: `GET /health` (estado y base de datos) y `GET /api-docs` (Swagger UI).

### Reglas de negocio

- **R1, seguridad alimentaria.** Una receta que contenga un ingrediente incompatible con las restricciones efectivas del usuario **nunca se recomienda**. Las restricciones efectivas suman tres fuentes: las declaradas, las derivadas del estilo alimentario (vegetariano, vegano) y las derivadas de condiciones clínicas (celiaquía, intolerancia a la lactosa). Ningún puntaje compensa la incompatibilidad.
- **R2, publicación con datos confiables.** Para publicar una receta, sus calorías, proteína, carbohidratos y grasa deben estar completos. Además, las calorías deben ser coherentes con los macronutrientes (factores de Atwater 4/4/9, desviación ≤ 15 %). Si no se cumple, la API responde **422**.
- **R3, ciclo de vida.** Una receta publicada no se elimina: primero se archiva (**409**). Los nombres de receta son únicos (**409**) y solo se aceptan transiciones de estado válidas (**409**).

Los errores usan `application/problem+json` (RFC 9457) e incluyen `code`, `detail`, la lista `errors` y `requestId`.

## 5. Guion de demostración (sustentación)

Antes de empezar, deje la base en su estado inicial con `npm run db:reset`. La demo puede hacerse en la aplicación web (http://localhost:3000) o con la colección de Postman, ejecutando las carpetas en orden.

1. **Autenticación:** iniciar sesión como admin, Ana y Luis. Probar con credenciales erradas (**401**).
2. **CRUD:** crear (**201**, queda en `draft`) → consultar → actualizar → publicar → archivar → eliminar (**204**) → consultar (**404**).
3. **Regla R1:**
   - Las recomendaciones de Ana no incluyen pasta, wrap ni avena (contienen gluten).
   - `GET /recipes/4/compatibility` con Ana muestra `compatible: false` por gluten, con origen `celiac_disease`.
   - Con Luis, el pollo es incompatible porque es vegetariano.
4. **Casos de error:**
   - Publicar el *Brownie de cacao* da **422**: las calorías declaradas no corresponden a los macros.
   - Borrar una receta publicada da **409**.
   - Nombre duplicado: **409**.
   - Datos inválidos: **400**.
   - Usuario sin rol admin: **403**.
   - Sin token: **401**.

## 6. Pruebas automatizadas

```bash
npm test             # 73 pruebas: dominio, aplicación, API HTTP, contrato y arquitectura
npm run typecheck    # verificación de tipos de TypeScript
```

Para ejecutar también la prueba de contrato contra PostgreSQL (6 pruebas más), cree una base de datos vacía y defina `TEST_DATABASE_URL`:

```bash
psql -U postgres -c "CREATE DATABASE nutriedu_test"
# Linux/macOS:
TEST_DATABASE_URL=postgresql://postgres:postgres@localhost:5432/nutriedu_test npm test
# Windows (PowerShell):
$env:TEST_DATABASE_URL="postgresql://postgres:postgres@localhost:5432/nutriedu_test"; npm test
```

| Carpeta | Qué verifica |
|---|---|
| `tests/domain` | Reglas R1, R2 y R3, ciclo de vida, derivación de restricciones, cadena de evaluación, estrategias, fábrica y orden determinista |
| `tests/application` | Casos de uso con adaptadores en memoria, incluida la defensa en profundidad de R1 |
| `tests/http` | Cada endpoint y cada código de respuesta (200, 201, 204, 400, 401, 403, 404, 409, 422 y 429) |
| `tests/integration` | El mismo contrato del repositorio, ejecutado contra memoria y contra PostgreSQL (principio de sustitución de Liskov) |
| `tests/architecture` | Regla de dependencias hexagonal: el dominio y la aplicación no importan Express, pg, Zod ni JWT |

### Medición de rendimiento (opcional)

```bash
npm run bench:data   # inserta 500 recetas sintéticas (úselo en una base de datos aparte)
npm run dev          # en otra terminal
npm run bench        # 300 solicitudes, concurrencia 10, reporta p50/p95/p99
```

## 7. Estructura del proyecto

```
src/
├── domain/                  Núcleo: entidades, objetos de valor, reglas y motor de recomendación
│   ├── recipe/              Recipe (R2, R3, R1), NutritionFacts
│   ├── profile/             DietaryProfile (restricciones efectivas, metas por comida)
│   ├── recommendation/      RecommendationEngine, cadena de evaluación y estrategias
│   └── shared/errors.ts     Errores del dominio (sin HTTP)
├── application/
│   ├── ports/input/         Puertos de entrada (interfaces de casos de uso)
│   ├── ports/output/        Puertos de salida (RecipeRepository, IngredientCatalog, …)
│   └── services/            Implementación de los casos de uso
├── infrastructure/
│   ├── adapters/input/http/ Adaptador de entrada: Express (rutas, controladores, validación, errores)
│   ├── adapters/output/     Adaptadores de salida: PostgreSQL, memoria, JWT, bcrypt
│   ├── config/              Configuración validada (.env)
│   └── seed/                Datos de ejemplo (única fuente)
├── bootstrap/container.ts   Raíz de composición (inyección de dependencias)
└── main.ts                  Punto de arranque
public/                      Aplicación web (cliente de la API)
db/migrations/               Esquema SQL
docs/                        OpenAPI, Postman y documento de arquitectura
tests/                       Pruebas automatizadas
```

La explicación completa de cada capa, los diagramas, la tabla de evidencia SOLID/DRY/KISS y los patrones de diseño están en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

## 8. Scripts

| Script | Uso |
|---|---|
| `npm run dev` | API en modo desarrollo (recarga automática) |
| `npm run dev:memory` | API sin base de datos (adaptadores en memoria) |
| `npm run build` / `npm start` | Compila a `dist/` y ejecuta la versión compilada |
| `npm run db:setup` | Migraciones y datos de ejemplo |
| `npm run db:reset` | Borra los datos y vuelve a cargar los de ejemplo |
| `npm test` | Pruebas automatizadas |

## 9. Solución de problemas

| Síntoma | Causa probable y solución |
|---|---|
| `Configuración inválida … JWT_SECRET` | No existe `.env`. Ejecute `cp .env.example .env`. |
| `password authentication failed for user "postgres"` | Ajuste `DB_USER` y `DB_PASSWORD` en `.env`. |
| `database "nutriedu_recetas" does not exist` | Cree la base de datos (paso 3 de la alternativa A). |
| `EADDRINUSE :3000` | El puerto está ocupado. Cambie `PORT` en `.env`. |
| `La base de datos ya tiene datos; no se cargó la semilla` | Es normal. Use `npm run db:reset` para reiniciar los datos. |
