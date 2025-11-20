# 🔗 Mapeo: GitHub Actions → .env

## Información que obtienes del GitHub Actions Workflow

Después de ejecutar el workflow `test-action.yml`, obtienes esta información:

```
========================================
✅ DSQL Cluster Test Results
========================================

📊 Cluster Details:
  Name: test-dsql-cluster
  ARN: arn:aws:dsql:us-east-1:123456789012:cluster/xxxxx
  Endpoint: xxxxx.dsql.us-east-1.on.aws              ← ⭐ USA ESTE

🔒 Security:
  KMS Key: arn:aws:kms:us-east-1:123456789012:key/xxxxx
  IAM Role: arn:aws:iam::123456789012:role/xxxxx
  Security Group: sg-xxxxx

🌐 Networking:
  VPC Endpoint Service: com.amazonaws.vpce.us-east-1.vpce-svc-xxxxx
  VPC Endpoint ID: vpce-xxxxx
  VPC Endpoint DNS: vpce-xxxxx.dsql-fnh4.us-east-1.vpce.amazonaws.com  ← NO uses este para local
```

## 🎯 Mapeo Directo a .env

### Para Desarrollo Local (Tu Mac/PC)

```env
# ============================================
# DEL GITHUB ACTIONS OUTPUT
# ============================================

# 1. De "Endpoint:" (línea 106) - EL MÁS IMPORTANTE
# Copia el valor que aparece en: steps.dsql.outputs.cluster_endpoint
DSQL_CLUSTER_ENDPOINT=xxxxx.dsql.us-east-1.on.aws

# 2. Región (del workflow o del endpoint)
# Visible en el endpoint: xxxxx.dsql.US-EAST-1.on.aws
AWS_REGION=us-east-1

# 3. Base de datos (valor por defecto que creó el cluster)
DSQL_DATABASE_NAME=testdb

# 4. Usuario (por defecto en DSQL)
DSQL_USER=admin

# 5. Autenticación (recomendado IAM)
AUTH_METHOD=iam

# 6. Puerto del servidor (local)
PORT=8080

# 7. Pool de conexiones (valores por defecto)
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_CONN_MAX_LIFETIME=300

# 8. Logs
LOG_LEVEL=info
```

### Para Producción en AWS VPC

Si vas a desplegar tu backend en EC2/ECS/Lambda **dentro del mismo VPC**:

```env
# Usa el VPC Endpoint DNS en lugar del público
DSQL_CLUSTER_ENDPOINT=vpce-xxxxx.dsql-fnh4.us-east-1.vpce.amazonaws.com

# El resto igual...
AWS_REGION=us-east-1
DSQL_DATABASE_NAME=testdb
DSQL_USER=admin
AUTH_METHOD=iam
```

## 📋 Tabla de Mapeo Completo

| GitHub Actions Output | Variable .env | Cuándo Usarlo | Ejemplo |
|----------------------|---------------|---------------|---------|
| **Endpoint** (línea 106) | `DSQL_CLUSTER_ENDPOINT` | ✅ Desarrollo local | `abc123.dsql.us-east-1.on.aws` |
| **VPC Endpoint DNS** (línea 116) | `DSQL_CLUSTER_ENDPOINT` | Solo en VPC | `vpce-xxx.dsql-fnh4.us-east-1.vpce.amazonaws.com` |
| Región (del endpoint) | `AWS_REGION` | Siempre | `us-east-1` |
| N/A (valor estándar) | `DSQL_DATABASE_NAME` | Siempre | `testdb` |
| N/A (valor estándar) | `DSQL_USER` | Siempre | `admin` |
| N/A (elección) | `AUTH_METHOD` | Siempre | `iam` |

## 🎯 Valores que NO necesitas del GitHub Actions

Estos outputs son informativos pero NO van en el `.env`:

- ❌ **ARN**: Solo para referencia
- ❌ **KMS Key**: Se usa automáticamente por DSQL
- ❌ **IAM Role**: Es para el cluster, no para tu app
- ❌ **Security Group**: Ya está configurado en el cluster
- ❌ **VPC Endpoint Service**: Información de red
- ❌ **VPC Endpoint ID**: Información de red

## 📝 Ejemplo Real Paso a Paso

### 1. Copia el Output del GitHub Actions

```
📊 Cluster Details:
  Name: test-dsql-cluster
  ARN: arn:aws:dsql:us-east-1:156783829256:cluster/a1b2c3d4e5f6
  Endpoint: a1b2c3d4e5f6.dsql.us-east-1.on.aws    ← COPIA ESTO
```

### 2. Crea tu .env

```bash
cd backend
cp env.example .env
nano .env  # o tu editor favorito
```

### 3. Pega el Endpoint

```env
# Antes (env.example):
DSQL_CLUSTER_ENDPOINT=your-cluster-endpoint.dsql.us-east-1.on.aws

# Después (tu .env):
DSQL_CLUSTER_ENDPOINT=a1b2c3d4e5f6.dsql.us-east-1.on.aws
```

### 4. Verifica la Región

```env
# Debe coincidir con la región del endpoint
AWS_REGION=us-east-1
```

### 5. Mantén los Demás Valores por Defecto

```env
DSQL_DATABASE_NAME=testdb
DSQL_USER=admin
AUTH_METHOD=iam
PORT=8080
```

## 🔍 Script de Verificación

Usa este script para verificar que todo esté correcto:

```bash
cd backend/scripts
./verificar-env.sh
```

## ⚠️ Errores Comunes

### ❌ Error 1: Usar VPC Endpoint en Local

```env
# ❌ INCORRECTO para desarrollo local:
DSQL_CLUSTER_ENDPOINT=vpce-0875989ea5d927cc1-x46zjgyx.dsql-fnh4.us-east-1.vpce.amazonaws.com

# ✅ CORRECTO para desarrollo local:
DSQL_CLUSTER_ENDPOINT=a1b2c3d4e5f6.dsql.us-east-1.on.aws
```

**Síntoma**: Error "no such host"

### ❌ Error 2: Región Incorrecta

```env
# Si tu cluster está en us-east-1
AWS_REGION=us-west-2  # ❌ INCORRECTO
AWS_REGION=us-east-1  # ✅ CORRECTO
```

**Síntoma**: Timeout o error de autenticación

### ❌ Error 3: Copiar el ARN en vez del Endpoint

```env
# ❌ INCORRECTO:
DSQL_CLUSTER_ENDPOINT=arn:aws:dsql:us-east-1:156783829256:cluster/a1b2c3d4e5f6

# ✅ CORRECTO:
DSQL_CLUSTER_ENDPOINT=a1b2c3d4e5f6.dsql.us-east-1.on.aws
```

**Síntoma**: Error de formato o conexión

## 🧪 Probar la Configuración

Una vez configurado:

```bash
# 1. Verificar
cd backend/scripts
./verificar-env.sh

# 2. Agregar permisos IAM (si es necesario)
./fix-iam-permissions.sh

# 3. Iniciar el backend
cd ..
make run

# 4. Probar conexión (en otra terminal)
curl http://localhost:8080/health
```

## ✅ Respuesta Esperada

Si todo está correcto, deberías ver:

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

## 📞 ¿Problemas?

1. **"no such host"** → Estás usando VPC endpoint, cambia a endpoint público
2. **"access denied"** → Faltan permisos IAM, ejecuta `./scripts/fix-iam-permissions.sh`
3. **"connection timeout"** → Verifica la región en AWS_REGION

---

## 🎯 Resumen Visual

```
GitHub Actions Output:
┌─────────────────────────────────────────────────┐
│ Endpoint: a1b2c3d4e5f6.dsql.us-east-1.on.aws  │ ← Copia esto
└─────────────────────────────────────────────────┘
                        ↓
Tu archivo .env:
┌─────────────────────────────────────────────────┐
│ DSQL_CLUSTER_ENDPOINT=a1b2c3d4e5f6.dsql...     │ ← Pégalo aquí
│ AWS_REGION=us-east-1                            │
│ DSQL_DATABASE_NAME=testdb                       │
│ DSQL_USER=admin                                 │
│ AUTH_METHOD=iam                                 │
└─────────────────────────────────────────────────┘
                        ↓
Ejecutar:
┌─────────────────────────────────────────────────┐
│ cd backend                                      │
│ make run                                        │
└─────────────────────────────────────────────────┘
                        ↓
Probar:
┌─────────────────────────────────────────────────┐
│ curl http://localhost:8080/health               │
└─────────────────────────────────────────────────┘
```

**¡Es así de simple! Solo necesitas copiar el Endpoint de la línea 106 del output de GitHub Actions!** 🚀

