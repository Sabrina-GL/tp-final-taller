# Cobertura de Tests - TP Final

## Estado actual

Este archivo resume **cómo medir cobertura** y **cómo reportar resultados vigentes**.
Se toma como **fuente canónica** para métricas de tests/cobertura en el proyecto.

Última actualización del documento: 2026-02-18.

### Última corrida registrada

- Comando: `mix test --cover`
- Resultado tests: `166 tests, 0 failures`
- Cobertura total: `80.22%`
- Umbral configurado: `80.00%`
- Estado del comando: exitoso (exit code 0)
- Vigencia: estos valores corresponden a la última actualización de este documento.

## Cómo ejecutar

```bash
cd chat_app
mix test --cover
```

## Qué registrar después de correr

- Porcentaje total de cobertura informado por `mix test --cover`.
- Cantidad total de tests y número de fallos.
- Módulos con menor cobertura para priorizar mejoras.

## Notas

- Los valores de cobertura y conteo de tests **pueden variar** entre corridas según cambios recientes.
- Para resultados reproducibles, ejecutar sobre una base de datos de test limpia.
