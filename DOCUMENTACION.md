# 📚 Índice de Documentación

Guía completa de toda la documentación disponible en este proyecto.

## 🚀 Para Empezar

### **[INICIO-RAPIDO.md](INICIO-RAPIDO.md)** ⭐ EMPIEZA AQUÍ
Guía de 5 minutos para conectar tu backend Go con Aurora DSQL.
- Setup en 3 pasos
- Configuración del .env
- Pruebas rápidas

---

## 📖 Documentación del Backend Go

### Configuración

#### **[backend/MAPEO-GITHUB-ACTIONS.md](backend/MAPEO-GITHUB-ACTIONS.md)**
Cómo mapear los outputs del GitHub Actions workflow a tu archivo `.env`
- Tabla de mapeo completo
- Ejemplos paso a paso
- Diferencia entre endpoint público y VPC

#### **[backend/CONFIGURACION-ENV.md](backend/CONFIGURACION-ENV.md)**
Guía detallada de todas las variables de entorno
- Cada variable explicada
- Dónde obtener cada valor
- Ejemplos completos

### Troubleshooting

#### **[backend/DEBUG-ACCESS-DENIED.md](backend/DEBUG-ACCESS-DENIED.md)**
Solución al error "access denied"
- Pasos de debugging
- Verificación de permisos IAM
- Soluciones alternativas

#### **[backend/IAM-PERMISSIONS.md](backend/IAM-PERMISSIONS.md)**
Guía completa de permisos IAM para Aurora DSQL
- Políticas necesarias
- Cómo agregar permisos (Console, CLI, Terraform)
- Verificación de permisos

### Referencia

#### **[backend/README.md](backend/README.md)**
Documentación completa del backend
- Arquitectura
- API endpoints
- Ejemplos de uso
- Configuración avanzada
- Docker deployment

---

## 🛠️ Scripts Útiles

### **backend/scripts/verificar-env.sh**
Verifica que tu archivo `.env` esté configurado correctamente
```bash
cd backend/scripts && ./verificar-env.sh
```

### **backend/scripts/fix-iam-permissions.sh**
Agrega automáticamente los permisos IAM necesarios
```bash
cd backend/scripts && ./fix-iam-permissions.sh
```

### **backend/scripts/debug-connection.sh**
Diagnóstico completo de problemas de conexión
```bash
cd backend/scripts && ./debug-connection.sh
```

### **backend/scripts/setup.sh**
Setup inicial completo (dependencias, Swagger, etc.)
```bash
cd backend/scripts && ./setup.sh
```

---

## 🗂️ Estructura de Archivos

```
actions-aws-aurora-dsql/
│
├── INICIO-RAPIDO.md              ⭐ Empieza aquí
├── DOCUMENTACION.md              📚 Este archivo
├── README.md                     📖 README principal del proyecto
│
├── backend/                      🔧 Backend Go
│   ├── README.md                     Documentación completa del backend
│   ├── MAPEO-GITHUB-ACTIONS.md       GitHub Actions → .env
│   ├── CONFIGURACION-ENV.md          Guía del .env
│   ├── DEBUG-ACCESS-DENIED.md        Troubleshooting "access denied"
│   ├── IAM-PERMISSIONS.md            Guía de permisos IAM
│   │
│   ├── config/                       Configuración
│   ├── database/                     Conexión DSQL
│   ├── handlers/                     API endpoints
│   ├── models/                       Data models
│   ├── docs/                         Swagger (generado)
│   │
│   ├── scripts/                      Scripts útiles
│   │   ├── setup.sh                      Setup completo
│   │   ├── verificar-env.sh              Verificar .env
│   │   ├── fix-iam-permissions.sh        Fix permisos IAM
│   │   └── debug-connection.sh           Debug conexión
│   │
│   ├── main.go                       Entry point
│   ├── go.mod                        Dependencias
│   ├── Makefile                      Comandos build
│   ├── Dockerfile                    Container
│   ├── env.example                   Template .env
│   └── .env                          Tu configuración
│
├── .github/workflows/            ⚙️ GitHub Actions
│   └── test-action.yml               Workflow para crear DSQL cluster
│
├── main.tf                       🏗️ Terraform
├── outputs.tf                        Outputs del cluster
├── variables.tf                      Variables
└── terraform.tf                      Config Terraform
```

---

## 🎯 Flujo de Trabajo Recomendado

### 1. Primera Vez

```bash
# 1. Leer INICIO-RAPIDO.md
# 2. Ejecutar GitHub Actions para crear cluster DSQL
# 3. Configurar .env con el endpoint del output
# 4. Agregar permisos IAM
cd backend/scripts && ./fix-iam-permissions.sh

# 5. Iniciar backend
cd backend && make run

# 6. Probar
curl http://localhost:8080/health
```

### 2. Si Hay Problemas

```bash
# 1. Ejecutar debug
cd backend/scripts && ./debug-connection.sh

# 2. Verificar .env
./verificar-env.sh

# 3. Revisar documentación específica
# Ver backend/DEBUG-ACCESS-DENIED.md o backend/IAM-PERMISSIONS.md
```

### 3. Desarrollo Continuo

```bash
# Iniciar servidor
cd backend && make run

# Regenerar Swagger docs (si cambias endpoints)
make swagger

# Compilar para producción
make build
```

---

## 🔍 Búsqueda Rápida de Temas

### "¿Cómo configuro el .env?"
→ **INICIO-RAPIDO.md** (paso 1) o **backend/CONFIGURACION-ENV.md**

### "Error: access denied"
→ **backend/DEBUG-ACCESS-DENIED.md** o ejecuta `scripts/debug-connection.sh`

### "¿Qué permisos IAM necesito?"
→ **backend/IAM-PERMISSIONS.md**

### "¿Cómo mapeo el output de GitHub Actions?"
→ **backend/MAPEO-GITHUB-ACTIONS.md**

### "Error: no such host"
→ **backend/MAPEO-GITHUB-ACTIONS.md** (usa endpoint público, no VPC)

### "¿Cómo uso la API?"
→ **backend/README.md** o abre Swagger UI: http://localhost:8080/swagger/index.html

### "¿Cómo despliego a producción?"
→ **backend/README.md** (sección Docker y deployment)

---

## 📞 Herramientas de Diagnóstico

| Problema | Script | Qué hace |
|----------|--------|----------|
| No sé si mi .env está bien | `verificar-env.sh` | Verifica toda la configuración |
| Error "access denied" | `fix-iam-permissions.sh` | Agrega permisos IAM automáticamente |
| Cualquier error de conexión | `debug-connection.sh` | Diagnóstico completo |
| Primera instalación | `setup.sh` | Instala todo lo necesario |

---

## 💡 Tips

- **Siempre empieza con `INICIO-RAPIDO.md`** - Te ahorrará mucho tiempo
- **Usa los scripts** - Son más rápidos que hacer todo manual
- **Swagger UI es tu amigo** - Para probar la API interactivamente
- **El debug script es muy útil** - Te dice exactamente qué está mal

---

## 🆘 ¿Perdido?

1. Lee **INICIO-RAPIDO.md**
2. Ejecuta `backend/scripts/debug-connection.sh`
3. Revisa la salida del script - te dirá qué hacer

**¡La documentación está diseñada para que puedas estar corriendo en menos de 5 minutos!** 🚀

