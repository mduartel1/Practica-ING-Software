# Practica ING Software - AsistQR

AsistQR es una aplicacion de control de asistencia academica con codigos QR.

## Problema

La toma manual de asistencia consume tiempo de clase, introduce errores y dificulta auditoria de registros.

## Solucion

AsistQR permite registrar asistencia en tiempo real mediante QR por sesion, con trazabilidad por usuario y curso.

## Perfiles del sistema

- Profesor.
- Alumno.

## Funcionalidades principales

- Registro como profesor o alumno de manera autonoma.
- Pantalla para que el profesor cree asignaturas.
- El profesor puede habilitar y deshabilitar el QR de la sesion activa.
- El alumno puede escanear el codigo QR y registrar su asistencia.
- Visualizacion del historico de asistencia por asignatura y alumno.
- Exportacion CSV del historico de asistencia filtrado.
- Aplicacion movil iOS como cliente principal.

## Alcance de MVP

- Gestion de perfil y autenticacion para profesor y alumno.
- Gestion de asignaturas por parte del profesor.
- Control de QR de sesion (activar/desactivar) por el profesor.
- Registro de asistencia por escaneo QR desde la app iOS.
- Consulta de historico de asistencia filtrado por asignatura y alumno.
- Vista previa y comparticion de CSV del historico.

## Estado actual

La aplicacion iOS esta integrada en `ios/AsistQR` y contiene un MVP funcional con persistencia local:

- Flujo de entrada por perfil: profesor o alumno.
- Pantallas de registro e inicio de sesion simuladas.
- Panel de profesor con asignaturas, sesion QR activa, historico y exportacion CSV.
- Panel de alumno con escaneo QR, entrada manual de codigo y consulta de asistencia.
- Store con persistencia local para asignaturas, sesiones QR y registros de asistencia.
- Pruebas unitarias automatizadas para creacion de asignaturas, registro de asistencia y exportacion CSV.

Nota: la persistencia actual es local en el dispositivo/simulador. No hay sincronizacion remota ni backend.

## Ejecutar la aplicacion

Requisitos:

- macOS con Xcode instalado.
- Simulador iOS disponible.

Pasos:

1. Abrir `ios/AsistQR/AsistQR.xcodeproj` en Xcode.
2. Seleccionar el esquema `AsistQR`.
3. Seleccionar un simulador iPhone.
4. Ejecutar con `Run`.

Desde terminal:

```bash
xcodebuild test \
  -project ios/AsistQR/AsistQR.xcodeproj \
  -scheme AsistQR \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:AsistQRTests
```

En GitHub Actions se ejecuta automaticamente el workflow `iOS Tests` en cada PR que toca `ios/**`.

## Demo sugerida

1. Entrar como profesor.
2. Crear una asignatura.
3. Abrir sesion activa y habilitar QR.
4. Copiar o leer el codigo de sesion mostrado.
5. Entrar como alumno.
6. Registrar asistencia con el escaner o la entrada manual.
7. Volver al profesor y revisar el historico filtrado.
8. Exportar CSV y mostrar la vista previa.

## Documentacion para Laboratorio 4

- `docs/Laboratorio4_AsistQR.md`: resumen de requisitos, arquitectura, pruebas y guion de presentacion.

## Documento de propuesta

- `docs/Propuesta_AsistQR.docx`
