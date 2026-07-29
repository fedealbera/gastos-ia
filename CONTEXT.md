# Contexto de la Aplicación: Gastos IA

Este documento sirve como la fuente única de verdad para contextualizar la estructura, arquitectura y estado actual de la aplicación **Gastos IA**.

---

## 🏗️ 1. Arquitectura y Tecnologías Core 

La aplicación está construida sobre **Flutter stable** utilizando **Clean Architecture** estructurada por *features*. Esto asegura desacoplamiento total, escalabilidad, y preparación para futuras migraciones (por ejemplo, de almacenamiento local a una API REST remota o Firebase).

### Tecnologías Utilizadas:
* **Gestión de Estados**: `flutter_bloc` (BLoC Pattern) para desacoplar lógica de negocio y presentación.
* **Persistencia Local**: `hive_flutter` para almacenamiento llave-valor local ultrarrápido y de baja latencia. Se implementaron **TypeAdapters manuales** para evitar dependencias e inconsistencias del generador de código.
* **Navegación**: `go_router` para enrutamiento declarativo e incorporando animaciones de transición personalizadas.
* **Inyección de Dependencias**: `get_it` para registro y resolución de dependencias por capas.
* **Estadísticas**: `fl_chart` para renderizar gráficos de torta y barras interactivos.
* **Exportación y Compartición de Informes**: `excel` para la generación estructurada de libros de trabajo en formato XLSX, `share_plus` para gatillar el diálogo nativo de compartir y `path_provider` para localizar directorios temporales de manera multiplataforma.
* **Testing**: `mocktail` y `flutter_test` para unit testing robusto de agregaciones y repositorios.

---

## 📂 2. Estructura Completa del Proyecto

A continuación, se detalla el propósito de cada directorio y archivo en la base de código actual:

```
lib/
├── main.dart                      # Punto de entrada de la aplicación, inicializa la localización
├── app.dart                       # Configura MaterialApp con Material 3 Light/Dark y GoRouter
├── core/                          # Compartido por todas las features de la app
│   ├── database/
│   │   └── hive_database.dart     # Inicializa Hive, registra adaptadores manuales, siembra y migra categorías
│   ├── di/
│   │   └── injection.dart         # Registro centralizado de dependencias y Blocs con GetIt
│   ├── errors/
│   │   └── failures.dart          # Jerarquía de excepciones y fallos estándar de Clean Architecture
│   ├── routes/
│   │   └── app_router.dart        # Configuración de GoRouter con efectos de transición fluidos
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
    │           ├── splash_page.dart # Pantalla de carga animada y calentamiento de Base de Datos
    │           └── onboarding_page.dart # Registro de bienvenida (nombre de usuario) en primer lanzamiento
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
    │           └── dashboard_page.dart # Hub analítico con fl_chart Pie/Bar, botón de exportación y listas
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
    │   │       └── category_repository_impl.dart # Implementación del contrato de Repositorio
    │   └── presentation/
    │       ├── bloc/
    │       │   └── categories_bloc.dart # Control de estados para el CRUD de Categorías
    │       └── pages/
    │           └── categories_page.dart # CRUD de categorías con paleta expandida de 12 colores y 18 iconos redondeados
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
        │       └── expense_repository_impl.dart # Resuelve los métodos del Repositorio atrapando DatabaseFailures
        └── presentation/
            ├── bloc/
            │   └── expenses_bloc.dart # Manejo de eventos CRUD de transacciones e historial por rangos
            └── pages/
                ├── expenses_list_page.dart # Historial cronológico con barra de búsqueda, selector de rangos y botón de exportar
                ├── category_expenses_page.dart # Listado y agregados de transacciones filtradas por categoría
                └── expense_form_page.dart # Registro con teclado numérico, chips dinámicos y fecha editable
```

---

## 🔀 3. Flujos de Gestión de Estados (BLoCs)

### A. CategoriesBloc
* **Eventos**:
  * `LoadCategories`: Carga todas las categorías disponibles.
  * `SaveCategoryEvent`: Guarda o edita una categoría.
  * `DeleteCategoryEvent`: Remueve una categoría por ID.
* **Estados**:
  * `CategoriesInitial`, `CategoriesLoading`, `CategoriesLoaded`, `CategoriesError`.

### B. ExpensesBloc
* **Eventos**:
  * `LoadExpenses`: Carga todos los gastos en la app.
  * `LoadExpensesByDateRange`: Filtra los gastos locales entre dos fechas.
  * `SaveExpenseEvent` / `DeleteExpenseEvent`: Registra o remueve gastos manteniendo activos los filtros previos de fechas.
* **Estados**:
  * `ExpensesInitial`, `ExpensesLoading`, `ExpensesLoaded`, `ExpensesError`.

### C. DashboardBloc
* **Eventos**:
  * `LoadDashboardData`: Recibe fechas límites (por defecto, el mes calendario actual) para calcular la analítica acumulada.
* **Estados**:
  * `DashboardInitial`, `DashboardLoading`, `DashboardLoaded`, `DashboardError`.

---

## 💾 4. Base de Datos Local, Siembra (Seeding) y Migración

Se inicializa mediante `HiveDatabase.init()` en la pantalla de carga Splash. Si al iniciar la aplicación la caja (`Box`) de categorías se encuentra vacía, se realiza un autosebrado para mejorar la experiencia de primer uso del usuario:
1. **Supermercado** (Azul, icono `shopping_cart_rounded`)
2. **Combustible** (Rojo, icono `local_gas_station_rounded`)
3. **Salidas** (Amarillo, icono `restaurant_rounded`)
4. **Transporte** (Verde esmeralda, icono `directions_bus_rounded`)
5. **Servicios** (Morado, icono `electrical_services_rounded`)

### Robustez y Migración de Codepoints de Iconos
Para asegurar que los iconos de las categorías se dibujen sin inconsistencias visuales ni discrepancias tipográficas en cualquier versión del SDK de Flutter, se sustituyeron los enteros hexadecimales arbitrarios por codepoints directos resueltos en tiempo de compilación (a través de `Icons.*_rounded.codePoint`).
Durante el inicio, `HiveDatabase._migrateCategoryIcons()` detecta de manera automatizada codepoints previos deprecados o no estándar almacenados en la base de datos de categorías o cacheados en el historial de gastos, transformándolos transparentemente a sus equivalentes modernos de la familia Material Rounded.

---

## 📊 5. Sistema de Exportación de Datos (Excel Report)

La aplicación incorpora una utilidad premium en [export_helper.dart](file:///Users/federicoalbera/Documents/Proyectos/LeapFactor/Flutter/proyectos/gastos-ia/lib/core/utils/export_helper.dart) para generar y compartir reportes financieros en formato Microsoft Excel:
* **Estructura Multitab del Reporte**:
  * **Pestaña "Resumen"**: Detalla la sumatoria consolidada gastada por cada categoría individual dentro del período seleccionado, junto a un indicador destacado del *TOTAL GENERAL*.
  * **Pestaña "Detalle de Gastos"**: Muestra las transacciones agrupadas por categoría (ordenadas alfabéticamente). Para cada categoría, lista de forma cronológica descendente las transacciones individuales (Fecha, Descripción, Monto) acompañadas de su subtotal correspondiente.
* **Flujos de Exportación Disponibles**:
  * **Desde el Dashboard**: Un botón de exportación en la parte superior derecha de la tarjeta de total gastado permite extraer la analítica completa del mes calendario corriente o del período personalizado seleccionado.
  * **Desde el Historial de Gastos**: Un botón en la barra superior del listado de transacciones permite exportar únicamente el subconjunto de gastos que coincide con los filtros aplicados (rango de fechas seleccionado y/o texto en la barra de búsqueda).

---

## 🎨 6. Paleta Visual y Catálogo de Categorías Expandido

Se enriqueció el abanico de opciones para crear categorías personalizadas:
* **Colores**: Se expandió la grilla a 12 colores distintivos curados de la paleta Material/Tailwind para dar mayor identidad y contraste visual al dashboard.
* **Iconografía**: El selector de iconos ahora expone 18 alternativas estilizadas y redondeadas que abarcan diversas aristas de consumo (compras, combustible, banco, deportes, servicios, vehículos, seguridad, restaurantes, buses, cine, gimnasio, educación, hogar, salud, viajes, tarjetas de crédito, regalos y mascotas).

---

## 🧪 7. Suite de Pruebas Unitarias

Ubicada en `test/widget_test.dart`, implementa pruebas con stubs locales que simulan el repositorio:
* **Agregaciones de gastos**: Verifica la sumatoria de montos.
* **Porcentaje de categorías**: Valida la distribución proporcional del dinero.
* **Identificación del mayor gasto**: Comprueba que resuelva correctamente la categoría con mayor desembolso.
* **Historial diario**: Controla el agrupamiento cronológico para los gráficos.
