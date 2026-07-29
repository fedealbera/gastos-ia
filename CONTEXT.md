# Contexto de la Aplicación: Gastos IA

Este documento sirve como la fuente única de verdad para contextualizar la estructura, arquitectura y estado actual de la aplicación **Gastos IA**.

---

## 🏗️ 1. Arquitectura y Tecnologías Core 

La aplicación está construida sobre **Flutter stable** utilizando **Clean Architecture** estructurada por *features*. Esto asegura desacoplamiento total, escalabilidad, y preparación para futuras migraciones (por ejemplo, de almacenamiento local a una API REST remota o Firebase).

### Tecnologías Utilizadas:
* **Gestión de Estados**: `flutter_bloc` (BLoC Pattern) para desacoplar lógica de negocio y presentación.
* **Persistencia Local**: `hive_flutter` para almacenamiento llave-valor local ultrarrápido y de baja latencia. Se implementaron **TypeAdapters manuales** para evitar dependencias e inconsistencias del generador de código.
* **Autenticación en la Nube**: `firebase_auth` y `google_sign_in` para posibilitar el inicio de sesión con Google y la vinculación de cuentas de invitado a cuentas en la nube.
* **Base de Datos Remota**: `cloud_firestore` de Firebase para alojar los gastos y categorías en la nube por cada usuario autenticado de manera aislada.
* **Navegación**: `go_router` para enrutamiento declarativo e incorporando animaciones de transición personalizadas.
* **Inyección de Dependencias**: `get_it` para registro y resolución de dependencias por capas.
* **Estadísticas**: `fl_chart` para renderizar gráficos de torta y barras interactivos.
* **Información de Compilación**: `package_info_plus` para extraer la versión y el número de compilación directamente del archivo `pubspec.yaml`.
* **Exportación de Informes**: `excel` para generar libros de trabajo XLSX y `share_plus` junto con `path_provider` para gatillar el diálogo nativo de compartir.
* **Testing**: `mocktail` y `flutter_test` para unit testing robusto de agregaciones y repositorios.

---

## 📂 2. Estructura Completa del Proyecto

A continuación, se detalla el propósito de cada directorio y archivo en la base de código actual:

```
lib/
├── main.dart                      # Punto de entrada de la aplicación, inicializa Firebase y localización
├── app.dart                       # Configura MaterialApp envuelto en AuthCubit con GoRouter
├── core/                          # Compartido por todas las features de la app
│   ├── database/
│   │   └── hive_database.dart     # Inicializa Hive, registra adaptadores manuales y migra categorías (con guardia de re-inicialización)
│   ├── di/
│   │   └── injection.dart         # Registro centralizado de dependencias y Blocs con GetIt (con guardia de re-inicialización)
│   ├── errors/
│   │   └── failures.dart          # Jerarquía de excepciones y fallos estándar de Clean Architecture
│   ├── routes/
│   │   └── app_router.dart        # Configuración de GoRouter con efectos de transición fluidos
│   ├── services/
│   │   └── sync_service.dart      # Servicio de sincronización bidireccional entre Hive local y Firestore
│   ├── theme/
│   │   └── app_theme.dart         # Temas M3 Light/Dark y tokens visuales premium (Slate & Teal)
│   ├── usecases/
│   │   └── usecase.dart           # Firma de UseCases base
│   ├── utils/
│   │   ├── color_helper.dart      # Auxiliar para parsear colores hexadecimales y calcular contrastes de texto
│   │   └── export_helper.dart     # Utilidad para formatear, construir y compartir hojas de cálculo de Excel
│   └── widgets/
│       └── app_logo.dart          # Logo animado premium con degradados, sombras y destello AI
└── features/                      # Módulos aislados y escalables por dominio de negocio
    ├── splash/
    │   └── presentation/
    │       └── pages/
    │           ├── splash_page.dart # Pantalla de carga animada y visualización de versión con fade-in
    │           └── onboarding_page.dart # Botón de Google Sign-in y Guest login clásico
    ├── auth/                          # Módulo de autenticación de usuario
    │   ├── domain/
    │   │   └── repositories/
    │   │       └── auth_repository.dart # Interfaz del repositorio de autenticación
    │   ├── data/
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart # Implementación concreta con FirebaseAuth y GoogleSignIn
    │   └── presentation/
    │       └── cubit/
    │           ├── auth_cubit.dart    # Cubit controlador del estado de autenticación global
    │           └── auth_state.dart    # Estados de autenticación (Cargando, Autenticado, Error)
    ├── dashboard/
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── dashboard_stats.dart # Entidad agregada de métricas mensuales y acumulados
    │   │   └── usecases/
    │   │       └── get_dashboard_stats.dart # Ejecuta cálculos de total, diario y categoría mayor de gastos
    │   └── presentation/
    │       ├── bloc/
    │       │   └── dashboard_bloc.dart # Administra estados del ciclo analítico mensual
    │       └── pages/
    │           └── dashboard_page.dart # Hub analítico con Pie/Bar chart, botón avatar de perfil con menú Custom Bottom Sheet
    ├── categories/
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── category.dart  # Entidad que define el ID, nombre, color hex e icono de categorías
    │   │   ├── repositories/
    │   │   │   └── category_repository.dart # Contrato de repositorio
    │   │   └── usecases/
    │   │       ├── get_categories.dart
    │   │       ├── save_category.dart
    │   │       └── delete_category.dart
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── category_local_datasource.dart # Datasource para lectura/escritura en Hive Box
    │   │   ├── models/
    │   │   │   └── category_model.dart # Modelo compatible con Hive y su TypeAdapter manual
    │   │   └── repositories/
    │   │       └── category_repository_impl.dart # Implementación con soporte para réplicas en Firestore
    │   └── presentation/
    │       ├── bloc/
    │       │   └── categories_bloc.dart # Control de estados para el CRUD de Categorías
    │       └── pages/
    │           └── categories_page.dart # CRUD de categorías con paleta expandida de 12 colores y 18 iconos rounded
    └── expenses/
        ├── domain/
        │   ├── entities/
        │   │   └── expense.dart   # Entidad para registro de gastos individuales con metadatos de categoría
        │   ├── repositories/
        │   │   └── expense_repository.dart # Contrato de repositorio de gastos
        │   └── usecases/
        │       ├── get_expenses.dart
        │       ├── get_expenses_by_date_range.dart
        │       ├── save_expense.dart
        │       └── delete_expense.dart
        ├── data/
        │   ├── datasources/
        │   │   └── expense_local_datasource.dart # Datasource para persistencia de gastos en Hive Box
        │   ├── models/
        │   │   └── expense_model.dart # Modelo y adaptador Hive manual para mapeo de campos
        │   └── repositories/
        │       └── expense_repository_impl.dart # Resuelve los métodos de almacenamiento y borrado en Hive y Firestore
        └── presentation/
            ├── bloc/
            │   └── expenses_bloc.dart # Manejo de eventos CRUD de transacciones e historial por rangos
            └── pages/
                ├── expenses_list_page.dart # Historial cronológico con barra de búsqueda, selector de rangos y botón de exportar
                ├── category_expenses_page.dart # Listado y agregados de transacciones filtradas por categoría
                └── expense_form_page.dart # Registro con teclado numérico, chips dinámicos y fecha editable
```

---

## 🔀 3. Flujos de Gestión de Estados (BLoCs y Cubits)

### A. AuthCubit (Autenticación Global)
* **Eventos/Métodos**:
  * `checkAuth()`: Determina si el usuario ya cuenta con una sesión de Firebase activa.
  * `loginWithGoogle()`: Inicia el flujo nativo de Google Sign-in y Firebase Authentication.
  * `loginAsGuest(String name)`: Crea un perfil local en Hive sin registrarse en la nube.
  * `logout()`: Ejecuta el cierre de sesión tanto en Firebase como en el cliente de Google.
* **Estados**:
  * `AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`, `AuthError`.

### B. CategoriesBloc
* **Eventos**:
  * `LoadCategories`: Carga todas las categorías disponibles de Hive.
  * `SaveCategoryEvent`: Guarda o edita una categoría localmente y la sincroniza a Firestore.
  * `DeleteCategoryEvent`: Remueve una categoría por ID localmente y de Firestore.
* **Estados**:
  * `CategoriesInitial`, `CategoriesLoading`, `CategoriesLoaded`, `CategoriesError`.

### C. ExpensesBloc
* **Eventos**:
  * `LoadExpenses`: Carga todos los gastos en la app.
  * `LoadExpensesByDateRange`: Filtra los gastos locales entre dos fechas.
  * `SaveExpenseEvent` / `DeleteExpenseEvent`: Registra o remueve gastos locales y sincroniza los cambios a Firestore.

### D. DashboardBloc
* **Eventos**:
  * `LoadDashboardData`: Recibe fechas límites para calcular estadísticas.

---

## ☁️ 4. Sistema de Sincronización en la Nube (Firestore Sync)

El servicio `SyncService` gestiona la consistencia de los datos históricos y en tiempo real:

* **Sincronización al Iniciar Sesión (Fusión Bidireccional)**:
  Al autenticarse mediante Google, se ejecuta `syncOnLogin(userId)` el cual:
  1. Descarga todas las categorías y gastos de Firestore pertenecientes al usuario que no existan localmente y los guarda en Hive.
  2. Sube todos los gastos y categorías locales de Hive (creados en modo invitado) que no existan en Firestore.
* **Sincronización en Tiempo Real**:
  Los repositorios de datos (`ExpenseRepositoryImpl` y `CategoryRepositoryImpl`) inyectan `SyncService` para propagar de inmediato cada creación o eliminación hacia Firestore cuando `AuthCubit` reporta que el usuario está autenticado.
* **Protección contra Pérdidas en Cierre de Sesión (Secure Logout)**:
  Al hacer clic en *Cerrar Sesión*, el sistema muestra una pantalla de carga y ejecuta `syncAndClearLocalData(userId)` de forma obligatoria. Sube cualquier transacción local remanente a Firestore y, solo al confirmarse la carga exitosa, procede a limpiar las cajas de Hive, a resembrar las categorías por defecto y a desloguear la sesión de Google, garantizando **cero pérdidas de datos**.

---

## 💾 5. Base de Datos Local y Robustez de Inicialización

Se inicializa mediante `HiveDatabase.init()` en la pantalla de carga Splash.

### Guardia de Re-inicialización de Hive y GetIt (Garantía contra Freezes)
Para dar soporte a los flujos de cierre de sesión, donde el usuario vuelve a la pantalla de Splash, se implementaron guardias de inicialización:
* **Hive Guard**: En `HiveDatabase.init()`, si las cajas ya están inicializadas, se retorna inmediatamente. Esto evita errores de tipo `HiveError: There is already a TypeAdapter for typeId 0`.
* **GetIt Guard**: En `injection.dart`, si `SyncService` ya está registrado, se sale de la función para evitar excepciones de tipo `StateError (GetIt: Factory/Singleton already registered)`.

### Migración de Codepoints de Iconos
Para asegurar que los iconos se dibujen correctamente bajo cualquier SDK, `HiveDatabase._migrateCategoryIcons()` detecta codepoints hexadecimales antiguos almacenados localmente y los migra de forma transparente a los codepoints de tiempo de compilación nativos de la familia `Icons.*_rounded`.

---

## 🛠️ 6. Compatibilidad y Configuración SDK (Android)

* **minSdkVersion**: Incrementado a **`23`** (Android 6.0) en `android/app/build.gradle.kts` para cumplir con las especificaciones del SDK de Firebase Auth.
* **Kotlin Compiler**: Actualizado a la versión **`2.1.0`** en `android/settings.gradle.kts` para resolver errores de compilación de metadatos incompatibles con dependencias modernas (como `package_info_plus`).
* **Seguridad de Firestore**: Configurado bajo reglas que restringen estrictamente la lectura y escritura de los documentos de la colección `/users/{userId}` al usuario cuyo UID coincida con el UID autenticado en la petición (`request.auth.uid == userId`).
