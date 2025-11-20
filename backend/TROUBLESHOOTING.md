# 🔧 Troubleshooting - Guía de Solución de Problemas

Soluciones a los problemas más comunes al conectarse a Aurora DSQL.

## 🚨 Errores Comunes

### 1. Error: "access denied"

```
pq: unable to accept connection, access denied
```

**Causa**: Tu usuario IAM no tiene permisos `dsql:DbConnect`

**Solución Rápida**:
```bash
cd backend/scripts
./fix-iam-permissions.sh
sleep 60  # Esperar propagación
cd .. && make run
```

**Solución Manual**: Ver [IAM-PERMISSIONS.md](IAM-PERMISSIONS.md)

**Debug Completo**: Ver [DEBUG-ACCESS-DENIED.md](DEBUG-ACCESS-DENIED.md)

---

### 2. Error: "no such host"

```
dial tcp: lookup vpce-xxxxx: no such host
```

**Causa**: Estás usando un endpoint VPC desde tu computadora local

**Solución**: Usa el endpoint PÚBLICO del GitHub Actions output

```env
# ❌ INCORRECTO (VPC endpoint):
DSQL_CLUSTER_ENDPOINT=vpce-xxxxx.dsql-fnh4.us-east-1.vpce.amazonaws.com

# ✅ CORRECTO (público):
DSQL_CLUSTER_ENDPOINT=abc123.dsql.us-east-1.on.aws
```

Ver: [MAPEO-GITHUB-ACTIONS.md](MAPEO-GITHUB-ACTIONS.md)

---

### 3. Error: "DSQL_CLUSTER_ENDPOINT is required"

```
Failed to load configuration: DSQL_CLUSTER_ENDPOINT is required
```

**Causa**: El archivo `.env` no existe o está incompleto

**Solución**:
```bash
cd backend
cp env.example .env
nano .env  # Agregar tu endpoint
```

Ver: [CONFIGURACION-ENV.md](CONFIGURACION-ENV.md)

---

### 4. Error: "connection timeout"

```
context deadline exceeded
```

**Causas posibles**:
- Región incorrecta en `.env`
- Cluster no está running
- Firewall bloqueando conexión

**Solución**:
```bash
# Verificar región
grep AWS_REGION backend/.env

# Verificar cluster existe
aws dsql list-clusters --region us-east-1

# Verificar endpoint responde
nslookup your-endpoint.dsql.us-east-1.on.aws
```

---

### 5. Error: "password authentication failed"

```
pq: password authentication failed for user "admin"
```

**Causa**: Usando `AUTH_METHOD=password` pero contraseña incorrecta

**Soluciones**:
1. **Cambiar a IAM auth** (recomendado):
   ```env
   AUTH_METHOD=iam
   # Eliminar o comentar DSQL_PASSWORD
   ```

2. **Verificar contraseña**:
   ```env
   DSQL_PASSWORD=tu-password-correcta
   ```

---

### 6. Error: "failed to build auth token"

```
failed to build auth token: the provided endpoint is missing a port
```

**Causa**: Bug en versión anterior del código (ya corregido)

**Solución**: Este error ya está arreglado. Si lo ves, actualiza el código de `database/connection.go`

---

## 🔍 Herramientas de Diagnóstico

### Script de Diagnóstico Automático

Identifica automáticamente el problema:

```bash
cd backend/scripts
./debug-connection.sh
```

Este script verifica:
- ✅ AWS credentials
- ✅ IAM permissions
- ✅ .env configuration
- ✅ Network connectivity
- ✅ DSQL cluster status

### Verificar Configuración

```bash
cd backend/scripts
./verificar-env.sh
```

Verifica que tu `.env` esté completo y correcto.

### Arreglar Permisos IAM

```bash
cd backend/scripts
./fix-iam-permissions.sh
```

Agrega automáticamente los permisos necesarios.

---

## 🧪 Verificación Manual Paso a Paso

### 1. Verificar AWS Identity

```bash
aws sts get-caller-identity
```

Debe mostrar tu cuenta y usuario.

### 2. Verificar Endpoint

```bash
# Ver tu endpoint
grep DSQL_CLUSTER_ENDPOINT backend/.env

# Probar DNS
nslookup tu-endpoint.dsql.us-east-1.on.aws
```

Debe resolver a una IP.

### 3. Verificar Permisos IAM

```bash
USER_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | awk -F'/' '{print $NF}')
aws iam list-user-policies --user-name $USER_NAME
```

Debe mostrar `DSQLConnectPolicy` o similar.

### 4. Verificar Región

```bash
grep AWS_REGION backend/.env
aws dsql list-clusters --region us-east-1
```

Debe coincidir.

### 5. Test de Conexión

```bash
cd backend
make run
```

En otra terminal:
```bash
curl http://localhost:8080/health
```

---

## 📋 Checklist Completo

Usa este checklist para verificar todo:

- [ ] Archivo `.env` existe en `backend/`
- [ ] `DSQL_CLUSTER_ENDPOINT` configurado (endpoint PÚBLICO)
- [ ] `AWS_REGION` coincide con el endpoint
- [ ] AWS credentials configuradas (`aws sts get-caller-identity` funciona)
- [ ] Permisos IAM agregados (ejecutar `fix-iam-permissions.sh`)
- [ ] Esperaste 60 segundos después de agregar permisos
- [ ] Endpoint responde a `nslookup`
- [ ] `AUTH_METHOD=iam` (o `password` con `DSQL_PASSWORD` configurado)

---

## 🆘 Flujo de Troubleshooting

```
¿Tienes un error?
    ↓
Ejecuta: ./scripts/debug-connection.sh
    ↓
Lee la salida - te dice exactamente qué está mal
    ↓
Si dice "Missing IAM Permissions":
    → Ejecuta: ./scripts/fix-iam-permissions.sh
    → Espera 60 segundos
    → Intenta de nuevo
    ↓
Si dice "VPC Endpoint":
    → Cambia al endpoint público en .env
    → Ver MAPEO-GITHUB-ACTIONS.md
    ↓
Si dice "Endpoint not reachable":
    → Verifica que copiaste bien el endpoint
    → Verifica la región
    ↓
¿Aún no funciona?
    → Comparte output de debug-connection.sh
```

---

## 📚 Documentación Relacionada

- **[DEBUG-ACCESS-DENIED.md](DEBUG-ACCESS-DENIED.md)** - Debugging detallado del error "access denied"
- **[IAM-PERMISSIONS.md](IAM-PERMISSIONS.md)** - Guía completa de permisos IAM
- **[MAPEO-GITHUB-ACTIONS.md](MAPEO-GITHUB-ACTIONS.md)** - Mapeo de endpoints
- **[CONFIGURACION-ENV.md](CONFIGURACION-ENV.md)** - Configuración del .env

---

## 💡 Tips

1. **Siempre ejecuta primero** `./scripts/debug-connection.sh` - te ahorra tiempo
2. **El error "access denied" es el más común** - solo necesita permisos IAM
3. **Endpoint público vs VPC** - usa público para desarrollo local
4. **Espera 60 segundos** después de cambios en IAM
5. **Los scripts hacen todo automáticamente** - úsalos

---

**¿No encuentras tu error aquí? Ejecuta el script de debug - te dará información específica de tu problema.** 🔍

