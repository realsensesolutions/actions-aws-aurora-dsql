# 📋 Configuración del archivo .env para Aurora DSQL

## 🎯 Información Necesaria

Para conectarte a Aurora DSQL, tu archivo `.env` debe tener la siguiente información:

### ✅ Información Mínima Requerida

```env
# ===================================
# 1. ENDPOINT DE DSQL (REQUERIDO)
# ===================================
# Este es el endpoint PÚBLICO de tu cluster DSQL
# Formato: xxxxx.dsql.us-east-1.on.aws
# ⚠️ NO uses el endpoint VPC (vpce-xxxxx) si estás corriendo localmente
DSQL_CLUSTER_ENDPOINT=tu-cluster-id.dsql.us-east-1.on.aws

# ===================================
# 2. REGIÓN DE AWS (REQUERIDO)
# ===================================
# Debe coincidir con la región donde creaste el cluster
AWS_REGION=us-east-1

# ===================================
# 3. CREDENCIALES AWS (REQUERIDO)
# ===================================
# Estas NO van en el .env, sino que deben estar configuradas en tu sistema:
# - Opción 1: aws configure
# - Opción 2: Variables de entorno AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY
# - Opción 3: Archivo ~/.aws/credentials

# ===================================
# 4. MÉTODO DE AUTENTICACIÓN
# ===================================
# 'iam' = Usa credenciales AWS (recomendado, más seguro)
# 'password' = Usa usuario y contraseña (para testing)
AUTH_METHOD=iam

# ===================================
# 5. CONFIGURACIÓN DE BASE DE DATOS
# ===================================
# Nombre de la base de datos a usar
DSQL_DATABASE_NAME=testdb

# Usuario de la base de datos
# Para IAM auth: típicamente 'admin' o el usuario IAM
# Para password auth: el usuario que creaste en la BD
DSQL_USER=admin

# ===================================
# 6. CONTRASEÑA (Solo si AUTH_METHOD=password)
# ===================================
# DSQL_PASSWORD=tu-contraseña-segura

# ===================================
# 7. CONFIGURACIÓN DEL SERVIDOR
# ===================================
PORT=8080

# ===================================
# 8. CONFIGURACIÓN DEL POOL DE CONEXIONES
# ===================================
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_CONN_MAX_LIFETIME=300

# ===================================
# 9. CONFIGURACIÓN DE LA APLICACIÓN
# ===================================
LOG_LEVEL=info
```

## 📍 Dónde Obtener Cada Valor

### 1. DSQL_CLUSTER_ENDPOINT

**Opción A: GitHub Actions Output**

Después de ejecutar el workflow `test-action.yml`:

1. Ve a GitHub → Actions → Selecciona el workflow ejecutado
2. Busca el step "Display Cluster Information"
3. Encuentra la línea que dice "Endpoint: xxxxx.dsql.us-east-1.on.aws"
4. **IMPORTANTE**: Copia el endpoint PÚBLICO (sin `vpce-` al inicio)

**Opción B: AWS Console**

1. Ve a https://console.aws.amazon.com/rds/
2. Busca "Aurora DSQL" en el menú lateral
3. Selecciona tu cluster
4. Copia el "Cluster endpoint"

**Ejemplo de endpoints válidos:**
```
✅ CORRECTO (Público):  abc123def456.dsql.us-east-1.on.aws
❌ INCORRECTO (VPC):    vpce-xxxxx.dsql-fnh4.us-east-1.vpce.amazonaws.com
```

### 2. AWS_REGION

La región donde creaste el cluster. Típicamente:
- `us-east-1` (Virginia)
- `us-west-2` (Oregon)
- `eu-west-1` (Irlanda)

**Verificar en el endpoint**: Está en el endpoint mismo: `xxxxx.dsql.US-EAST-1.on.aws`

### 3. Credenciales AWS

**NO van en el .env**. Deben estar configuradas en tu sistema:

**Verificar que están configuradas:**
```bash
aws sts get-caller-identity
```

**Si no están configuradas:**
```bash
aws configure
# Ingresa:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region (us-east-1)
# - Default output format (json)
```

**O exporta variables de entorno:**
```bash
export AWS_ACCESS_KEY_ID=tu-access-key
export AWS_SECRET_ACCESS_KEY=tu-secret-key
export AWS_REGION=us-east-1
```

### 4. AUTH_METHOD

**Opciones:**

- `iam` ← **RECOMENDADO** (más seguro, sin contraseñas)
  - Usa tus credenciales AWS
  - Requiere permisos IAM: `dsql:DbConnect`
  
- `password` ← Para testing
  - Requiere usuario y contraseña en la BD
  - Debes agregar `DSQL_PASSWORD` al .env

### 5. DSQL_DATABASE_NAME

- Nombre de la base de datos dentro del cluster
- Por defecto: `testdb`
- Si creaste otra BD, usa ese nombre

### 6. DSQL_USER

**Con AUTH_METHOD=iam:**
- Típicamente: `admin` o tu nombre de usuario IAM
- Debe coincidir con el usuario que tiene permisos en la BD

**Con AUTH_METHOD=password:**
- El nombre del usuario que creaste en la BD
- Ejemplo: `testuser`, `dbadmin`, etc.

### 7. DSQL_PASSWORD

**Solo si usas AUTH_METHOD=password**

Debes crear el usuario primero en la BD:
```sql
CREATE USER testuser WITH PASSWORD 'MiPassword123!';
GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
```

## 🔍 Verificar tu Configuración

### Checklist Completo

```bash
# 1. Verificar que el .env existe
cd backend
ls -la .env

# 2. Ver el contenido (sin mostrar contraseñas)
cat .env | grep -v PASSWORD

# 3. Verificar endpoint (debe responder)
# Si es público, esto debería funcionar:
nslookup $(grep DSQL_CLUSTER_ENDPOINT .env | cut -d'=' -f2)

# 4. Verificar credenciales AWS
aws sts get-caller-identity

# 5. Verificar permisos IAM (si usas AUTH_METHOD=iam)
aws iam get-user-policy \
  --user-name $(aws sts get-caller-identity --query 'Arn' --output text | awk -F'/' '{print $NF}') \
  --policy-name DSQLConnectPolicy 2>/dev/null || echo "⚠️ Falta agregar permisos DSQL"
```

## ✅ Ejemplo Completo de .env

### Para Autenticación IAM (Recomendado)

```env
# Endpoint público del cluster (obtén del GitHub Actions output o AWS Console)
DSQL_CLUSTER_ENDPOINT=a1b2c3d4e5f6.dsql.us-east-1.on.aws

# Región AWS
AWS_REGION=us-east-1

# Base de datos
DSQL_DATABASE_NAME=testdb
DSQL_USER=admin

# Autenticación IAM
AUTH_METHOD=iam

# Servidor
PORT=8080

# Pool de conexiones
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_CONN_MAX_LIFETIME=300

# Aplicación
LOG_LEVEL=info
```

### Para Autenticación con Contraseña (Testing)

```env
# Endpoint público del cluster
DSQL_CLUSTER_ENDPOINT=a1b2c3d4e5f6.dsql.us-east-1.on.aws

# Región AWS
AWS_REGION=us-east-1

# Base de datos
DSQL_DATABASE_NAME=testdb
DSQL_USER=testuser

# Autenticación con contraseña
AUTH_METHOD=password
DSQL_PASSWORD=MiPassword123!

# Servidor
PORT=8080

# Pool de conexiones
DB_MAX_OPEN_CONNS=25
DB_MAX_IDLE_CONNS=5
DB_CONN_MAX_LIFETIME=300

# Aplicación
LOG_LEVEL=info
```

## 🚨 Errores Comunes

### Error: "no such host"
```
dial tcp: lookup vpce-xxxxx: no such host
```
**Problema**: Estás usando un endpoint VPC desde local  
**Solución**: Usa el endpoint PÚBLICO (sin `vpce-`)

### Error: "access denied"
```
pq: unable to accept connection, access denied
```
**Problema**: Faltan permisos IAM  
**Solución**: Ejecuta `./scripts/fix-iam-permissions.sh`

### Error: "DSQL_CLUSTER_ENDPOINT is required"
```
Failed to load configuration: DSQL_CLUSTER_ENDPOINT is required
```
**Problema**: El .env no existe o está vacío  
**Solución**: Crea el archivo .env desde env.example

### Error: "password authentication failed"
```
pq: password authentication failed for user "admin"
```
**Problema**: Contraseña incorrecta o usuario no existe  
**Solución**: Verifica DSQL_PASSWORD o cambia a AUTH_METHOD=iam

## 🧪 Probar la Configuración

Una vez configurado el .env:

```bash
# 1. Iniciar la aplicación
cd backend
make run

# 2. En otra terminal, probar
curl http://localhost:8080/health

# Respuesta esperada:
# {
#   "success": true,
#   "message": "Service is healthy",
#   "data": {
#     "status": "healthy",
#     "database": "connected",
#     "version": "1.0.0"
#   }
# }
```

## 📞 Necesitas Ayuda?

Si sigues teniendo problemas:

1. **Comparte el error específico** que ves
2. **Verifica el endpoint**: `echo $DSQL_CLUSTER_ENDPOINT` (sin contraseñas)
3. **Verifica credenciales**: `aws sts get-caller-identity`
4. **Revisa logs**: Inicia con `LOG_LEVEL=debug` en el .env

---

**Con esta configuración correcta, tu backend se conectará sin problemas a Aurora DSQL!** 🚀

