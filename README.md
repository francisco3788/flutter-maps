# Vía Limpia

Aplicación Flutter (Android/iOS/Web) para reportar daños viales sobre un mapa de OpenStreetMap. Cada reporte se almacena en Supabase (Postgres + Storage) e incluye latitud/longitud, tipo, severidad, estado, descripción y evidencia fotográfica.

## Requisitos previos

- Flutter 3.19+ con Dart 3.x y herramientas de plataforma configuradas.
- Proyecto Supabase activo (URL y anon key).
- Bucket de Storage llamado `road_reports`.

## Configuración rápida

1. **Variables de entorno**

   Crea el archivo `.env` en la raíz del proyecto (ya está ignorado por git) con tus credenciales:

   ```env
   SUPABASE_URL=https://<tu-proyecto>.supabase.co
   SUPABASE_ANON_KEY=<tu-anon-key>
   ```

2. **Dependencias**

   ```bash
    flutter pub get
   ```

3. **Backend Supabase**

   - Abre el panel de Supabase ➜ SQL Editor.
   - Ejecuta el script `docs/supabase_schema.sql` para crear tabla, índices y políticas RLS.
   - En Storage crea el bucket público `road_reports` y define reglas:
     - Lectura pública (o usa URLs firmadas si prefieres privacidad).
     - Escritura restringida a rutas `road_reports/{user_id}/{report_id}.jpg` donde `auth.uid()` coincide con `user_id`.

4. **Permisos móviles**

   - Android: `android/app/src/main/AndroidManifest.xml` incluye permisos de ubicación y cámara.
   - iOS: `ios/Runner/Info.plist` contiene descripciones para uso de ubicación/cámara/fotos.

5. **Ejecutar**

   ```bash
   flutter run
   ```

## Arquitectura

Estructura feature-first usando Riverpod:

```
lib/
 ├─ core/            # theme, widgets base, utils (result, validaciones, ubicación, media)
 ├─ data/            # proveedores genéricos como el SupabaseClient
 ├─ features/
 │   ├─ auth/        # controlador de sesión anónima
 │   └─ reports/
 │       ├─ data/    # repositorio Supabase + Storage, utilidades de media
 │       ├─ domain/  # entidades y filtros
 │       └─ presentation/
 │           ├─ controllers/  # Notifiers Riverpod
 │           └─ pages/        # Mapa, formulario, detalle, dashboard, listado
 └─ main.dart        # ProviderScope, navegación y shell principal
```

## Funcionalidades clave

- **Mapa interactivo** con marcadores coloreados por severidad, filtros y creación rápida (long-press o botón).
- **Formulario de reportes** con validaciones de lat/lng, descripción y tamaño de foto (≤ 5 MB).
- **Detalle** con imagen, acciones para editar, cerrar o eliminar (según RLS).
- **Listado** con búsqueda y filtros por estado.
- **Dashboard** con KPIs y gráfica de severidad.
- **Sesión anónima automática** para asociar reportes a cada usuario.

## Supabase y RLS

- Tabla `public.reports` protegida por Row Level Security.
- Lectura pública opcional (elimina la política `reports_select_public` si requieres autenticación).
- Inserciones, actualizaciones y eliminaciones limitadas al dueño (`auth.uid()`).
- Bucket `road_reports` con rutas `user_id/report_id.ext`.

## Scripts útiles

- `docs/supabase_schema.sql`: crea tabla, índices y políticas recomendadas.

## Próximos pasos sugeridos

- Configurar Supabase Realtime para actualizaciones en vivo (el stream está listo).
- Sustituir la lectura pública del bucket por URLs firmadas si necesitas privacidad extra.
- Añadir autenticación por correo/contraseña si el taller lo requiere.

¡Listo para tu taller! Ejecuta `flutter run` y comienza a reportar huecos con Vía Limpia.
