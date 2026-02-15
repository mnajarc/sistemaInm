
# Decisiones de Arquitectura - Sistema Inmobiliario V2

## ADR-001: offering_client_id / acquiring_client_id son LEGACY

### Contexto
El diseño original asumía 1 oferente y 1 adquiriente por transacción.
La realidad del negocio inmobiliario contempla:
- Múltiples copropietarios oferentes (herencias, sociedad conyugal)
- Múltiples adquirientes (pareja comprando, socios)
- Cambio de "principal" por fallecimiento o cesión

### Decisión
- **Fuente de verdad**: `business_transaction_co_owners` con campo `role`
- **Legacy**: `offering_client_id` y `acquiring_client_id` se mantienen
  por compatibilidad pero son REDUNDANTES
- **Regla**: El copropietario con `role: 'propietario'` y mayor
  porcentaje ES el "principal" (no offering_client_id)

### Consecuencias
- Cualquier cambio de principal debe actualizar AMBOS lugares
- La auditoría `rake audit:co_owner_consistency` detecta divergencias
- En el revamp V3, eliminar ambas columnas y resolver via co_owners

### Plan de Migración (V3)
1. Crear stored procedure `get_principal_owner(bt_id)` en PostgreSQL
2. Migrar todas las vistas a usar co_owners en vez de offering_client
3. DROP COLUMN offering_client_id, acquiring_client_id
4. Trigger BEFORE INSERT que asigne principal automáticamente
