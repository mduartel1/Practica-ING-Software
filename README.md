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
- Aplicacion movil iOS como cliente principal.

## Alcance de MVP

- Gestion de perfil y autenticacion para profesor y alumno.
- Gestion de asignaturas por parte del profesor.
- Control de QR de sesion (activar/desactivar) por el profesor.
- Registro de asistencia por escaneo QR desde la app iOS.
- Consulta de historico de asistencia filtrado por asignatura y alumno.

## Documento de propuesta

- `docs/Propuesta_AsistQR.docx`
