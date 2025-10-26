<h2>🔐 Configuración de secretos locales (<code>LocalSecrets.swift</code>)</h2> <p> El archivo <code>LocalSecrets.swift</code> contiene la configuración local para las <b>claves y credenciales necesarias</b> en la comunicación con la <b>API de Capital One (Nessie API)</b>.<br> Su propósito es centralizar el acceso a estas claves dentro del proyecto y permitir que se lean dinámicamente desde la configuración de compilación (<code>Info.plist</code> o <code>.xcconfig</code>) o, en su defecto, desde valores predeterminados. </p>
<h3>📄 Código del archivo</h3>
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

<h3>🧠 Explicación</h3> <ul> <li><b>nessieApiKey:</b><br> Recupera la clave API desde el archivo <code>Info.plist</code> (si fue configurada allí mediante <code>.xcconfig</code>).<br> Si no existe, utiliza una clave de respaldo definida directamente en el código.</li> <li><b>nessieCustomerId:</b><br> Identificador del cliente utilizado para realizar solicitudes autenticadas a la API.</li> <li><b>nessieCheckingAccountId:</b><br> ID de una cuenta corriente específica. Es opcional, pero útil si se desea consultar transacciones de una cuenta concreta.</li> </ul>
<h3>⚙️ Uso dentro del proyecto</h3> <p> Este archivo se incluye dentro del proyecto <b>Xcode</b> y se utiliza desde los servicios que realizan peticiones HTTP a la API.<br> Por ejemplo: </p>
let apiKey = LocalSecrets.nessieApiKey
let customerId = LocalSecrets.nessieCustomerId

<p> Esto permite mantener las claves <b>centralizadas</b> y evitar su repetición o exposición directa en múltiples archivos. </p>
<h3>🚀 Ejecución</h3> <p> El archivo <code>LocalSecrets.swift</code> no se ejecuta de forma independiente.<br> Se compila junto con el proyecto en Xcode y sus valores son accesibles en tiempo de ejecución cuando la aplicación realiza peticiones de red. </p>
<h3>🔒 Recomendaciones de seguridad</h3> <ul> <li>No incluyas claves reales en repositorios públicos.</li> <li>Usa archivos <code>.xcconfig</code> o variables de entorno para definir tus claves.</li> <li>Puedes agregar <code>LocalSecrets.swift</code> a tu <code>.gitignore</code> si contiene información sensible.</li> </ul>
