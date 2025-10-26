# 🎨 Guía de Estilo - Capital One Liquid Glass

## 🌊 Efecto Liquid Glass - Receta Completa

### Anatomía de un Componente con Glass Effect

```swift
ZStack {
    // 1. CAPA BASE - Fondo con gradiente
    RoundedRectangle(cornerRadius: 16)
        .fill(
            LinearGradient(
                colors: [SwiftFinColor.surface, SwiftFinColor.surfaceAlt],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    
    // 2. CAPA GLASS - Overlay transparente
    RoundedRectangle(cornerRadius: 16)
        .fill(
            LinearGradient(
                colors: [.white.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
}
.overlay(
    // 3. BORDE ILUMINADO - Stroke con gradiente
    RoundedRectangle(cornerRadius: 16)
        .stroke(
            LinearGradient(
                colors: [.white.opacity(0.15), .white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
)
.shadow(color: .black.opacity(0.2), radius: 8, y: 4) // 4. SOMBRA OSCURA
.shadow(color: SwiftFinColor.accentBlue.opacity(0.2), radius: 10, y: 5) // 5. SOMBRA DE COLOR
```

## 🎯 Componentes por Tipo

### Botones Principales (Primary Buttons)

```swift
// Ejemplo: Botón de Login
Button("Log In") { }
.padding()
.background(
    ZStack {
        // Gradiente base
        LinearGradient(
            colors: [SwiftFinColor.accentBlue, Color(hex: "#2563EB")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Overlay glass
        LinearGradient(
            colors: [.white.opacity(0.2), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
)
.clipShape(RoundedRectangle(cornerRadius: 12))
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .stroke(.white.opacity(0.2), lineWidth: 1)
)
.shadow(color: SwiftFinColor.accentBlue.opacity(0.5), radius: 10, y: 5)
```

### Botones Circulares (Icon Buttons)

```swift
// Ejemplo: Navigation buttons
ZStack {
    Circle()
        .fill(
            LinearGradient(
                colors: [SwiftFinColor.surfaceAlt.opacity(0.8), SwiftFinColor.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 40, height: 40)
    
    Circle()
        .stroke(
            LinearGradient(
                colors: [.white.opacity(0.15), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
        .frame(width: 40, height: 40)
    
    Image(systemName: "chevron.left")
        .foregroundStyle(SwiftFinColor.textPrimary)
}
```

### Campos de Texto (Text Fields)

```swift
TextField("Placeholder", text: $text)
    .padding(12)
    .background(
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(SwiftFinColor.surface.opacity(0.8))
            
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.05), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    )
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.2), SwiftFinColor.divider],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    )
```

### Tarjetas (Cards)

```swift
Card {
    // Contenido
}

// Card ya tiene el efecto glass aplicado:
// - Fondo con gradiente
// - Overlay transparente
// - Borde iluminado
// - Sombras múltiples
```

### Íconos Circulares (Circle Icons)

```swift
ZStack {
    Circle()
        .fill(
            LinearGradient(
                colors: [SwiftFinColor.surfaceAlt.opacity(0.8), SwiftFinColor.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 40, height: 40)
    
    Circle()
        .stroke(
            LinearGradient(
                colors: [.white.opacity(0.15), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
        .frame(width: 40, height: 40)
    
    Image(systemName: icon)
        .foregroundStyle(color)
}
```

## 🎨 Paleta de Colores por Contexto

### Colores de Acento

```swift
// Botones primarios, elementos activos
Primary Action: SwiftFinColor.accentBlue (#3B82F6)
Gradient: #3B82F6 → #2563EB

// Ingresos, valores positivos, success
Positive: SwiftFinColor.positiveGreen (#22C55E)
Gradient: #22C55E → #16A34A

// Gastos, valores negativos, alertas
Negative: SwiftFinColor.negativeRed (#EF4444)
Gradient: #EF4444 → #DC2626

// Capital One brand
Brand Blue: #004A9B
Brand Red: #DA1E28
```

### Colores de Fondo

```swift
// Fondos principales
Background: SwiftFinColor.bgPrimary (#0B1220)
Surface: SwiftFinColor.surface (#0F172A)
Surface Alt: SwiftFinColor.surfaceAlt (#111827)
```

### Colores de Texto

```swift
// Textos
Primary Text: SwiftFinColor.textPrimary (#E5E7EB)
Secondary Text: SwiftFinColor.textSecondary (#94A3B8)
```

## ✨ Animaciones

### Spring Animation (Recomendada)

```swift
// Para la mayoría de interacciones
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)

// Para transiciones de pantalla
.animation(.spring(response: 0.5, dampingFraction: 0.8), value: state)
```

### Transiciones Asimétricas

```swift
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

### Scale Effects

```swift
// Para botones al presionar
.scaleEffect(isPressed ? 0.95 : 1.0)
```

## 📏 Espaciado y Tamaños

### Padding Estándar

```swift
Tight: 4-8pt
Normal: 12-16pt
Spacious: 20-24pt
Section: 32pt+
```

### Corner Radius

```swift
Small (Buttons): 8-12pt
Medium (Cards): 16pt
Large (Sheets): 20pt
Pills/Capsules: 999pt o Capsule()
Circles: 50% del width
```

### Tamaños de Fuente

```swift
Title: .largeTitle (34pt)
Section Header: .title2 (22pt) o .title3 (20pt)
Body: .body (17pt) o .subheadline (15pt)
Caption: .caption (12pt) o .caption2 (11pt)
```

## 🎭 Estados Visuales

### Enabled vs Disabled

```swift
// Enabled
.foregroundStyle(SwiftFinColor.accentBlue)
.opacity(1.0)

// Disabled
.foregroundStyle(SwiftFinColor.textSecondary)
.opacity(0.5)
```

### Active vs Inactive

```swift
// Active (selected tab, por ejemplo)
.background(
    LinearGradient(
        colors: [SwiftFinColor.accentBlue, Color(hex: "#2563EB")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
.shadow(color: SwiftFinColor.accentBlue.opacity(0.4), radius: 8, y: 4)

// Inactive
.background(SwiftFinColor.surfaceAlt.opacity(0.5))
```

### Loading States

```swift
if isLoading {
    ProgressView()
        .tint(SwiftFinColor.accentBlue)
}
```

## 🔍 Ejemplos de Uso

### Login Screen

- ✅ Fondo con gradiente Capital One
- ✅ Círculos flotantes difuminados (blur)
- ✅ Campos de texto con glass effect
- ✅ Botón principal con gradiente y glow
- ✅ Feedback visual en errores

### Chat Interface

- ✅ Burbujas con gradientes distintos (usuario vs bot)
- ✅ Avatares circulares con glass effect
- ✅ Input field con glass effect
- ✅ Botón de envío con gradiente animado
- ✅ Timestamps sutiles

### Transaction Lists

- ✅ Íconos circulares con gradientes
- ✅ Colores distintos para income/expense
- ✅ Información jerárquica clara
- ✅ Rows con hover/press states

### Budgets

- ✅ Barras de progreso con gradientes
- ✅ Indicadores visuales (✓ ⚠️)
- ✅ Cards individuales con glass effect
- ✅ Estados de color (verde/rojo)

## 🚀 Best Practices

### DO ✅

1. Usa gradientes sutiles (5-20% opacity)
2. Combina múltiples sombras para profundidad
3. Agrega bordes iluminados con gradientes
4. Usa spring animations para naturalidad
5. Mantén consistencia en corner radius
6. Separa contenido con spacing adecuado

### DON'T ❌

1. No uses opacidades muy altas (>30%)
2. No combines demasiados efectos en un elemento
3. No uses animaciones muy rápidas (<0.2s)
4. No ignores los estados disabled
5. No uses colores planos sin gradientes
6. No olvides las sombras

## 🎓 Recursos de Referencia

- SwiftUI LinearGradient Documentation
- iOS Human Interface Guidelines
- Material Design (para inspiración de depth)
- Capital One Brand Guidelines (colores)

---

**💡 Tip Final**: El efecto liquid glass se basa en **capas**. Piensa en cada componente como una pila de capas transparentes que crean profundidad y reflejo.

**🎨 Regla de Oro**: Menos es más. No todos los elementos necesitan todos los efectos. Aplica el glass effect estratégicamente en elementos clave.
