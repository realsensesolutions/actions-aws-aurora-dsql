# 🚀 Inicio Rápido - Backend Go + Aurora DSQL

> Guía rápida para conectar tu backend Go con Aurora DSQL en **5 minutos**

## 📋 Prerequisitos

- ✅ Cluster DSQL creado (vía GitHub Actions workflow)
- ✅ Go 1.21+ instalado
- ✅ AWS CLI configurado (`aws configure`)

## ⚡ 3 Pasos para Conectarte

### 1️⃣ Configurar .env

```bash
cd backend
cp env.example .env
nano .env  # o tu editor favorito
```

**Pega el endpoint del GitHub Actions output:**

```env
# Del output "Endpoint:" en GitHub Actions (línea 106)
DSQL_CLUSTER_ENDPOINT=tu-endpoint.dsql.us-east-1.on.aws

# Región
AWS_REGION=us-east-1

# Valores por defecto (no cambiar)
DSQL_DATABASE_NAME=testdb
DSQL_USER=admin
AUTH_METHOD=iam
```

### 2️⃣ Agregar Permisos IAM

```bash
cd backend/scripts
./fix-iam-permissions.sh
```

Espera 60 segundos para que AWS propague los cambios.

### 3️⃣ Iniciar el Backend

```bash
cd backend
make install  # Solo primera vez
make run
```

## ✅ Probar

En otra terminal:

```bash
# Health check
curl http://localhost:8080/health

# Swagger UI
open http://localhost:8080/swagger/index.html
```

## 📝 Respuesta Esperada

```json
{
  "success": true,
  "message": "Service is healthy",
  "data": {
    "status": "healthy",
    "database": "connected",
    "version": "1.0.0"
  }
}
```

## 🎨 Probar CRUD Operations

### Opción 1: Swagger UI (Recomendado)
Abre: http://localhost:8080/swagger/index.html

### Opción 2: cURL

```bash
# Crear item
curl -X POST http://localhost:8080/api/v1/items \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Probando DSQL","completed":false}'

# Listar items
curl http://localhost:8080/api/v1/items

# Actualizar item
curl -X PUT http://localhost:8080/api/v1/items/1 \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'

# Eliminar item
curl -X DELETE http://localhost:8080/api/v1/items/1
```

## ❌ ¿Problemas?

### Error: "access denied"
```bash
cd backend/scripts
./debug-connection.sh  # Identifica el problema
./fix-iam-permissions.sh  # Agrega permisos
```

### Error: "no such host"
Estás usando el endpoint VPC. Usa el endpoint PÚBLICO del GitHub Actions output.

### Verificar configuración
```bash
cd backend/scripts
./verificar-env.sh
```

## 📚 Documentación Completa

- **`backend/README.md`** - Documentación completa del backend
- **`backend/MAPEO-GITHUB-ACTIONS.md`** - Cómo mapear outputs de Actions a .env
- **`backend/CONFIGURACION-ENV.md`** - Configuración detallada del .env
- **`backend/DEBUG-ACCESS-DENIED.md`** - Troubleshooting completo
- **`backend/IAM-PERMISSIONS.md`** - Guía de permisos IAM

## 🎯 Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/v1/items` | Listar items |
| GET | `/api/v1/items/:id` | Obtener item |
| POST | `/api/v1/items` | Crear item |
| PUT | `/api/v1/items/:id` | Actualizar item |
| DELETE | `/api/v1/items/:id` | Eliminar item |

## 🔧 Comandos Útiles

```bash
# Instalar dependencias
make install

# Generar docs Swagger
make swagger

# Iniciar servidor
make run

# Compilar binario
make build

# Limpiar
make clean

# Ver ayuda
make help
```

## 📦 Estructura del Backend

```
backend/
├── config/              # Configuración
├── database/            # Conexión DSQL
├── handlers/            # API endpoints
├── models/              # Data models
├── docs/                # Swagger (generado)
├── scripts/             # Scripts útiles
├── main.go              # Entry point
├── go.mod               # Dependencias
└── .env                 # Tu configuración
```

## 🆘 Soporte

Si tienes problemas, ejecuta el script de debug:

```bash
cd backend/scripts
./debug-connection.sh
```

Esto te dirá exactamente qué está mal y cómo arreglarlo.

---

**¡Tu backend está listo para probar operaciones CRUD con Aurora DSQL!** 🎉

