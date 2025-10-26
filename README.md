🔐 Configuración de secretos locales (LocalSecrets.swift)

El archivo LocalSecrets.swift contiene la configuración local para las claves y credenciales necesarias en la comunicación con la API de Capital One (Nessie API).
Su propósito es centralizar el acceso a estas claves dentro del proyecto y permitir que se lean dinámicamente desde la configuración de compilación (Info.plist o .xcconfig) o, en su defecto, desde valores predeterminados.

📄 Código del archivo
import Foundation

/// Local secrets configuration
/// In production, these should come from secure storage or build configuration
enum LocalSecrets {
    // Read from xcconfig via Info.plist, fallback to hardcoded
    static var nessieApiKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty {
            return key
        }
        return "YOUR_DEFAULT_API_KEY_HERE"
    }
    
}

🧠 Explicación

nessieApiKey:
Recupera la clave API desde el archivo Info.plist (si fue configurada allí mediante .xcconfig).
Si no existe, utiliza una clave de respaldo definida directamente en el código.

nessieCustomerId:
Identificador del cliente utilizado para realizar solicitudes autenticadas a la API.

nessieCheckingAccountId:
ID de una cuenta corriente específica. Es opcional, pero útil si se desea consultar transacciones de una cuenta concreta.

⚙️ Uso dentro del proyecto

Este archivo se incluye en el proyecto Xcode y se utiliza desde los servicios que realizan peticiones HTTP a la API.
Por ejemplo:

let apiKey = LocalSecrets.nessieApiKey
let customerId = LocalSecrets.nessieCustomerId


Esto permite mantener las claves centralizadas y evitar su repetición o exposición directa en múltiples archivos.

🚀 Ejecución

LocalSecrets.swift no se ejecuta de forma independiente.
Se compila junto con el proyecto en Xcode, y sus valores son accesibles en tiempo de ejecución cuando la aplicación realiza peticiones de red.
