# Configuración de API Key desde xcconfig

## Pasos para configurar en Xcode:

### 1. Verificar que Secrets.xcconfig esté asignado al target
1. Abre el proyecto en Xcode
2. Selecciona el proyecto en el navegador
3. Selecciona el target "CapitalOneDemo"
4. Ve a "Build Settings"
5. Busca "Configuration Files" o "Based on configuration file"
6. Asegúrate que esté seleccionado `Secrets.xcconfig`

### 2. Agregar API_KEY al Info.plist
1. Selecciona el target "CapitalOneDemo"
2. Ve a la pestaña "Info"
3. En "Custom iOS Target Properties", haz clic en el botón "+"
4. Agrega una nueva key: `API_KEY`
5. En el valor, pon: `$(API_KEY)`
   - Esto tomará el valor de Secrets.xcconfig

### 3. Verificar el Customer ID
En el archivo `Config/LocalSecrets.swift`, actualiza el customer ID:
```swift
static let nessieCustomerId = "TU_CUSTOMER_ID_AQUI"
```

Para obtener tu customer ID:
- Ve a https://api.nessieisreal.com
- O usa Postman/curl para crear un customer
- Guarda el `_id` que te devuelve la API

### 4. Alternativa: Hardcodear temporalmente
Si quieres probar rápido sin configurar el xcconfig, puedes:
1. Abrir `Config/LocalSecrets.swift`
2. Las credenciales ya están ahí como fallback:
   - API Key: `65dfb406dc064d7c9e638642279e62ff`
   - Customer ID: `671c203e9683f20dd518954a`

### 5. Verificar en logs
Cuando ejecutes la app, verás en la consola de Xcode:
```
🔍 IncomeVM: Fetching accounts for customer: [customer-id]
✅ IncomeVM: Got X accounts
🔍 ExpensesVM: Fetching purchases for customer: [customer-id]
✅ Got X purchases for [account]
```

Si ves errores ❌, revisa:
- El customer ID es correcto
- La API key es válida
- Tienes conexión a internet
- La API de Nessie está funcionando

## Estructura de archivos creados:
- `/Config/LocalSecrets.swift` - Credenciales con fallback
- `/Config/APIConfig.swift` - Helper para leer del xcconfig (opcional, no usado actualmente)
- `/Services/NessieService.swift` - Cliente API mejorado con logs
- Los ViewModels ahora usan `LocalSecrets` como fallback si no hay credenciales guardadas
