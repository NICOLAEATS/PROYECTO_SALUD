"""Scripts de instalación y configuración del sistema."""

from .instalar_postgresql import (
    detectar_postgresql_existente,
    instalar_postgresql_automatico,
    iniciar_servicio_postgresql,
    esperar_servicio_activo,
    crear_base_datos_y_esquema,
)

__all__ = [
    "detectar_postgresql_existente",
    "instalar_postgresql_automatico",
    "iniciar_servicio_postgresql",
    "esperar_servicio_activo",
    "crear_base_datos_y_esquema",
]
