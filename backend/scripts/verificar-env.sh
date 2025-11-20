#!/bin/bash

# Script para verificar la configuración del archivo .env

echo "🔍 Verificación de Configuración .env para Aurora DSQL"
echo "========================================================"
echo ""

cd "$(dirname "$0")/.." || exit 1

# Verificar que existe el archivo .env
if [ ! -f ".env" ]; then
    echo "❌ ERROR: No se encuentra el archivo .env"
    echo ""
    echo "Solución:"
    echo "  cp env.example .env"
    echo "  # Luego edita .env con tus valores"
    exit 1
fi

echo "✅ Archivo .env encontrado"
echo ""

# Función para obtener valor del .env
get_env_value() {
    grep "^$1=" .env 2>/dev/null | cut -d'=' -f2- | tr -d ' '
}

# Variables a verificar
ENDPOINT=$(get_env_value "DSQL_CLUSTER_ENDPOINT")
REGION=$(get_env_value "AWS_REGION")
DATABASE=$(get_env_value "DSQL_DATABASE_NAME")
USER=$(get_env_value "DSQL_USER")
AUTH_METHOD=$(get_env_value "AUTH_METHOD")
PORT=$(get_env_value "PORT")

echo "📋 Configuración actual:"
echo "────────────────────────────────────────────────────────"

# 1. Verificar ENDPOINT
echo ""
echo "1️⃣  DSQL_CLUSTER_ENDPOINT"
if [ -z "$ENDPOINT" ] || [ "$ENDPOINT" = "your-cluster-endpoint.dsql.us-east-1.on.aws" ]; then
    echo "   ❌ NO CONFIGURADO o usando valor por defecto"
    echo "   → Necesitas el endpoint de tu cluster DSQL"
    echo "   → Formato: xxxxx.dsql.region.on.aws"
    ERRORS=$((ERRORS + 1))
elif [[ $ENDPOINT == vpce-* ]]; then
    echo "   ⚠️  ADVERTENCIA: Usando endpoint VPC"
    echo "   → Valor: $ENDPOINT"
    echo "   → Este endpoint solo funciona desde dentro del VPC"
    echo "   → Para local, usa el endpoint PÚBLICO"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✅ Configurado: $ENDPOINT"
    # Verificar si el endpoint responde
    if command -v nslookup &> /dev/null; then
        if nslookup "$ENDPOINT" &> /dev/null; then
            echo "   ✅ El endpoint responde (DNS lookup exitoso)"
        else
            echo "   ⚠️  El endpoint no responde o no es accesible"
        fi
    fi
fi

# 2. Verificar AWS_REGION
echo ""
echo "2️⃣  AWS_REGION"
if [ -z "$REGION" ]; then
    echo "   ❌ NO CONFIGURADO"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ Configurado: $REGION"
fi

# 3. Verificar DSQL_DATABASE_NAME
echo ""
echo "3️⃣  DSQL_DATABASE_NAME"
if [ -z "$DATABASE" ]; then
    echo "   ⚠️  NO CONFIGURADO (se usará valor por defecto)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✅ Configurado: $DATABASE"
fi

# 4. Verificar DSQL_USER
echo ""
echo "4️⃣  DSQL_USER"
if [ -z "$USER" ]; then
    echo "   ❌ NO CONFIGURADO"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ Configurado: $USER"
fi

# 5. Verificar AUTH_METHOD
echo ""
echo "5️⃣  AUTH_METHOD"
if [ -z "$AUTH_METHOD" ]; then
    echo "   ⚠️  NO CONFIGURADO (se usará 'iam' por defecto)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✅ Configurado: $AUTH_METHOD"
    
    if [ "$AUTH_METHOD" = "iam" ]; then
        echo "   ℹ️  Usando autenticación IAM (recomendado)"
        echo "   → Requiere credenciales AWS configuradas"
        echo "   → Requiere permisos: dsql:DbConnect"
    elif [ "$AUTH_METHOD" = "password" ]; then
        echo "   ℹ️  Usando autenticación por contraseña"
        PASSWORD=$(get_env_value "DSQL_PASSWORD")
        if [ -z "$PASSWORD" ]; then
            echo "   ❌ FALTA: DSQL_PASSWORD es requerido para AUTH_METHOD=password"
            ERRORS=$((ERRORS + 1))
        else
            echo "   ✅ DSQL_PASSWORD configurado"
        fi
    fi
fi

# 6. Verificar PORT
echo ""
echo "6️⃣  PORT"
if [ -z "$PORT" ]; then
    echo "   ⚠️  NO CONFIGURADO (se usará 8080 por defecto)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✅ Configurado: $PORT"
fi

# Verificar credenciales AWS
echo ""
echo "────────────────────────────────────────────────────────"
echo "🔐 Verificando Credenciales AWS"
echo ""

if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null 2>&1; then
        ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        USER_ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
        echo "   ✅ Credenciales AWS configuradas"
        echo "   → Cuenta: $ACCOUNT"
        echo "   → Usuario/Role: $USER_ARN"
        
        # Verificar permisos DSQL (solo si usamos IAM auth)
        if [ "$AUTH_METHOD" = "iam" ] || [ -z "$AUTH_METHOD" ]; then
            echo ""
            echo "   🔍 Verificando permisos DSQL..."
            USER_NAME=$(echo "$USER_ARN" | awk -F'/' '{print $NF}')
            
            if aws iam get-user-policy --user-name "$USER_NAME" --policy-name DSQLConnectPolicy &> /dev/null; then
                echo "   ✅ Política DSQLConnectPolicy encontrada"
            else
                echo "   ⚠️  No se encontró la política DSQLConnectPolicy"
                echo "   → Ejecuta: ./scripts/fix-iam-permissions.sh"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    else
        echo "   ❌ Credenciales AWS NO configuradas o inválidas"
        echo "   → Ejecuta: aws configure"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ⚠️  AWS CLI no instalado"
    echo "   → No se pueden verificar las credenciales"
    WARNINGS=$((WARNINGS + 1))
fi

# Resumen final
echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 RESUMEN"
echo "════════════════════════════════════════════════════════"
echo ""

if [ ${ERRORS:-0} -eq 0 ] && [ ${WARNINGS:-0} -eq 0 ]; then
    echo "✅ ¡TODO ESTÁ CONFIGURADO CORRECTAMENTE!"
    echo ""
    echo "Siguiente paso:"
    echo "  cd backend"
    echo "  make run"
    echo ""
    echo "Luego prueba:"
    echo "  curl http://localhost:8080/health"
    exit 0
elif [ ${ERRORS:-0} -eq 0 ]; then
    echo "⚠️  Configuración completa con ${WARNINGS:-0} advertencia(s)"
    echo ""
    echo "Puedes intentar ejecutar la aplicación:"
    echo "  make run"
    exit 0
else
    echo "❌ Encontrados ${ERRORS:-0} error(es) y ${WARNINGS:-0} advertencia(s)"
    echo ""
    echo "Debes corregir los errores antes de continuar"
    echo ""
    echo "Guía completa: backend/CONFIGURACION-ENV.md"
    exit 1
fi

