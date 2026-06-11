import customtkinter as ctk
import threading
import subprocess
CREATE_NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
import sys
import os
import runpy
import re
import time
import json
import shutil
import zipfile
from datetime import datetime
from tkinter import filedialog, messagebox

# Módulo de configuración de base de datos
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db_config import (
    get_db_config,
    update_db_config,
    verificar_bd_esquema,
    detectar_postgresql_existente,
    PASSWORD_POSTGRES,
    PasswordRequeridoError,
    CONFIG_DIR,
)

# Módulo de instalación de PostgreSQL
try:
    from scripts_python.instalacion.instalar_postgresql import (
        instalar_postgresql_automatico,
        iniciar_servicio_postgresql,
        esperar_servicio_activo,
        crear_base_datos_y_esquema,
    )
    _instalador_disponible = True
except ImportError:
    _instalador_disponible = False

# Módulo de gestión de maestros
try:
    from modulo_maestros import ModuloMaestros
    _modulo_maestros_disponible = True
except ImportError:
    ModuloMaestros = None
    _modulo_maestros_disponible = False

BASE_DIR = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
INSTALL_DIR = os.path.dirname(sys.executable) if getattr(sys, "frozen", False) else os.path.dirname(os.path.abspath(__file__))
EDITOR_CONFIG_FILE = os.path.join(CONFIG_DIR, "editor_buttons.json")
EDITOR_RUNTIME_DIR = os.path.join(CONFIG_DIR, "editable")
PACKAGE_FILE_NAME = "paquete_actualizaciones.pscpack"
INSTALLED_PACKAGE_FILE = os.path.join(CONFIG_DIR, "installed_package.json")
PACKAGE_MANIFEST = "manifest.json"
RUTA_SQL_EDITOR_TABLA_VACUNAS = os.path.join("scripts_sql", "reportes", "tabla_vacunas_editor.sql")
RUTA_SQL_EDITOR_REPORTE_VACUNAS = os.path.join("scripts_sql", "reportes", "reporte_vacunas_editor.sql")
RUTA_SQL_EDITOR_HIS_PROCESO = os.path.join("scripts_sql", "reportes", "generar_his_proceso_editor.sql")
RUTA_SQL_EDITOR_EESS_PRINCIPAL = os.path.join(
    "scripts_sql",
    "scripst tabla y reportes vacunas-cred",
    "EESS_PRINCIPAL_2026     moshe.sql",
)

SECCIONES_REPORTE = [
    ("vacunas_cred", "💉 Vacunas y CRED"),
    ("reportes", "📊 Reportes"),
]
SECCIONES_REPORTE_MAP = {clave: titulo for clave, titulo in SECCIONES_REPORTE}
SECCIONES_REPORTE_INV = {titulo: clave for clave, titulo in SECCIONES_REPORTE}

BOTONES_REPORTE_PREDETERMINADOS = [
    {
        "text": "1️⃣ Tabla Vacunas/CRED",
        "color": "#3498DB",
        "script_path": os.path.join("scripts_python", "bi", "generar_tabla_vacunas.py"),
        "section": "vacunas_cred",
        "edit_path": RUTA_SQL_EDITOR_TABLA_VACUNAS,
        "custom": False,
    },
    {
        "text": "2️⃣ Tabla Materno",
        "color": "#9B59B6",
        "script_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "tabla materno.sql"
        ),
        "section": "vacunas_cred",
        "edit_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "tabla materno.sql"
        ),
        "custom": False,
    },
    {
        "text": "3️⃣ Tabla PAI",
        "color": "#8E44AD",
        "script_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "Script-136 moshe vacunas.sql"
        ),
        "section": "vacunas_cred",
        "edit_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "Script-136 moshe vacunas.sql"
        ),
        "custom": False,
    },
    {
        "text": "Reporte CRED",
        "color": "#F39C12",
        "script_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "cred2026_clean.sql"
        ),
        "section": "reportes",
        "edit_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "cred2026_clean.sql"
        ),
        "custom": False,
    },
    {
        "text": "Reporte Vacunas",
        "color": "#E74C3C",
        "script_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "REPORTE_VACUNAS_POR AÑO   moshe.sql"
        ),
        "section": "reportes",
        "edit_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "REPORTE_VACUNAS_POR AÑO   moshe.sql"
        ),
        "custom": False,
    },
    {
        "text": "Reporte IRAS/EDAS",
        "color": "#2ECC71",
        "script_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "REPORTE_IRAS_EDAS_POR_AÑO   moshe.sql"
        ),
        "section": "reportes",
        "edit_path": os.path.join(
            "scripts_sql", "scripst tabla y reportes vacunas-cred", "REPORTE_IRAS_EDAS_POR_AÑO   moshe.sql"
        ),
        "custom": False,
    },
]

SCRIPTS_MAESTROS_EDITABLES = [
    {
        "text": "Generar HIS Proceso",
        "script_path": os.path.join("scripts_python", "ingesta", "generar_his_proceso.py"),
        "section": "Gestión de Maestros",
        "edit_path": RUTA_SQL_EDITOR_HIS_PROCESO,
    },
    {
        "text": "Procesar EESS principal",
        "script_path": os.path.join("scripts_python", "ingesta", "procesar_eess_principal.py"),
        "section": "Gestión de Maestros",
        "edit_path": RUTA_SQL_EDITOR_EESS_PRINCIPAL,
    },
]


def normalizar_ruta_script(ruta_script: str) -> tuple[str, str]:
    ruta_norm = os.path.normpath(ruta_script)

    if os.path.isabs(ruta_norm):
        ruta_abs = ruta_norm
        try:
            ruta_rel = os.path.relpath(ruta_abs, BASE_DIR)
        except ValueError:
            ruta_rel = ruta_abs
        return ruta_rel, ruta_abs

    # En ejecutable, BASE_DIR apunta a los recursos empaquetados. Los SQL
    # editados deben vivir en APPDATA para que persistan entre ejecuciones.
    ruta_editable = os.path.join(EDITOR_RUNTIME_DIR, ruta_norm)
    if ruta_norm.lower().endswith(".sql") and os.path.exists(ruta_editable):
        return ruta_norm, ruta_editable

    ruta_abs = os.path.join(BASE_DIR, ruta_norm)
    ruta_rel = os.path.relpath(ruta_abs, BASE_DIR)
    return ruta_rel, ruta_abs


def ruta_recurso_empaquetado(ruta_relativa: str) -> str:
    return os.path.join(BASE_DIR, os.path.normpath(ruta_relativa))


def ruta_recurso_editable(ruta_relativa: str) -> str:
    return os.path.join(EDITOR_RUNTIME_DIR, os.path.normpath(ruta_relativa))


def resolver_ruta_lectura_editable(ruta_relativa: str) -> str:
    ruta_editable = ruta_recurso_editable(ruta_relativa)
    if os.path.exists(ruta_editable):
        return ruta_editable
    return ruta_recurso_empaquetado(ruta_relativa)


def rutas_paquete_distribucion() -> list[str]:
    candidatos = [
        os.path.join(INSTALL_DIR, PACKAGE_FILE_NAME),
        os.path.join(BASE_DIR, PACKAGE_FILE_NAME),
    ]
    vistos = set()
    resultado = []
    for ruta in candidatos:
        ruta_abs = os.path.abspath(ruta)
        clave = os.path.normcase(ruta_abs)
        if clave not in vistos:
            vistos.add(clave)
            resultado.append(ruta_abs)
    return resultado


def buscar_paquete_distribucion() -> str | None:
    for ruta in rutas_paquete_distribucion():
        if os.path.exists(ruta):
            return ruta
    return None


def leer_manifest_paquete(ruta_paquete: str) -> dict:
    try:
        with zipfile.ZipFile(ruta_paquete, "r") as zip_file:
            with zip_file.open(PACKAGE_MANIFEST) as manifest_file:
                return json.loads(manifest_file.read().decode("utf-8"))
    except Exception:
        return {}


def paquete_deshabilita_editor() -> bool:
    ruta_paquete = buscar_paquete_distribucion()
    if not ruta_paquete:
        return False
    manifest = leer_manifest_paquete(ruta_paquete)
    return bool(manifest.get("disable_editor", False))


def _destino_paquete_config(nombre_zip: str) -> str | None:
    nombre = nombre_zip.replace("\\", "/").lstrip("/")
    partes = [parte for parte in nombre.split("/") if parte not in {"", ".", ".."}]
    if not partes:
        return None

    if partes[0] == "editor_buttons.json" and len(partes) == 1:
        destino = os.path.join(CONFIG_DIR, "editor_buttons.json")
    elif partes[0] == "editable" and len(partes) > 1:
        destino = os.path.join(CONFIG_DIR, *partes)
    else:
        return None

    destino_abs = os.path.abspath(destino)
    config_abs = os.path.abspath(CONFIG_DIR)
    if not destino_abs.startswith(config_abs + os.sep) and destino_abs != config_abs:
        return None
    return destino_abs


def aplicar_paquete_actualizaciones(ruta_paquete: str, force: bool = False) -> tuple[bool, str]:
    if not os.path.exists(ruta_paquete):
        return False, f"Paquete no encontrado: {ruta_paquete}"

    manifest = leer_manifest_paquete(ruta_paquete)
    package_id = str(manifest.get("package_id") or os.path.basename(ruta_paquete))

    if not force and os.path.exists(INSTALLED_PACKAGE_FILE):
        try:
            with open(INSTALLED_PACKAGE_FILE, "r", encoding="utf-8") as file:
                instalado = json.load(file)
            if instalado.get("package_id") == package_id:
                return True, "Paquete ya aplicado."
        except Exception:
            pass

    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        extraidos = 0
        with zipfile.ZipFile(ruta_paquete, "r") as zip_file:
            for info in zip_file.infolist():
                if info.is_dir() or info.filename == PACKAGE_MANIFEST:
                    continue

                destino = _destino_paquete_config(info.filename)
                if not destino:
                    continue

                os.makedirs(os.path.dirname(destino), exist_ok=True)
                with zip_file.open(info, "r") as origen, open(destino, "wb") as salida:
                    shutil.copyfileobj(origen, salida)
                extraidos += 1

        registro = {
            "package_id": package_id,
            "source": os.path.abspath(ruta_paquete),
            "applied_at": datetime.now().isoformat(timespec="seconds"),
            "files": extraidos,
            "manifest": manifest,
        }
        with open(INSTALLED_PACKAGE_FILE, "w", encoding="utf-8") as file:
            json.dump(registro, file, ensure_ascii=False, indent=2)

        return True, f"Paquete aplicado correctamente ({extraidos} archivo(s))."
    except Exception as exc:
        return False, f"No se pudo aplicar el paquete: {exc}"


def autoaplicar_paquete_distribucion() -> tuple[bool, str]:
    ruta_paquete = buscar_paquete_distribucion()
    if not ruta_paquete:
        return True, "Sin paquete de distribución."
    return aplicar_paquete_actualizaciones(ruta_paquete, force=False)


def construir_comando_ejecucion(ruta_relativa: str, ruta_absoluta: str) -> list[str]:
    if getattr(sys, "frozen", False):
        return [sys.executable, "--run-script", ruta_relativa]
    return [sys.executable, ruta_absoluta]


ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")


class SistemaSaludApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self._paquete_autoaplicado_ok, self._paquete_autoaplicado_msg = autoaplicar_paquete_distribucion()
        self.editor_permitido = not paquete_deshabilita_editor()

        self.title("Sistema de Monitoreo de Salud - GERESA Cusco")
        self.geometry("1100x700")

        self.ruta_crudos_seleccionada = None
        self.db_config = get_db_config()
        self.requisitos_bd_ok = False
        self._ingesta_total = 0
        self._ingesta_completado = 0
        self._ingesta_inicio = None
        self._dialogo_password = None
        self.editor_mode_activo = False
        self._ventana_login_editor = None
        self._ventana_gestor_scripts = None
        self._scroll_gestor_scripts = None
        self.report_buttons_config = self._cargar_config_editor()
        self._ejecucion_global_token = 0
        self._proceso_cancelable = None
        self._proceso_cancelable_token = None
        self._proceso_cancelable_nombre = None
        self._tokens_cancelados = set()

        # ── MENÚ SUPERIOR ─────────────────────────────────────────────────────
        self.nav_frame = ctk.CTkFrame(self, height=50, fg_color="#1f242d", corner_radius=0)
        self.nav_frame.pack(side="top", fill="x")

        self.btn_nav_ingesta = ctk.CTkButton(
            self.nav_frame, text="⚙️ Ingesta y Mantenimiento",
            command=self.mostrar_modulo_ingesta, fg_color="#2c3e50"
        )
        self.btn_nav_ingesta.pack(side="left", padx=10, pady=10)

        self.btn_nav_reportes = ctk.CTkButton(
            self.nav_frame, text="📊 Análisis y Reportes",
            command=self.mostrar_modulo_reportes, fg_color="transparent"
        )
        self.btn_nav_reportes.pack(side="left", padx=10, pady=10)

        self.btn_nav_maestros = ctk.CTkButton(
            self.nav_frame, text="🗂️ Gestión de Maestros",
            command=self.mostrar_modulo_maestros, fg_color="transparent"
        )
        self.btn_nav_maestros.pack(side="left", padx=10, pady=10)

        self.btn_nav_bd = ctk.CTkButton(
            self.nav_frame, text="🗄️ Configurar BD",
            command=self.mostrar_modulo_bd, fg_color="transparent"
        )
        self.btn_nav_bd.pack(side="left", padx=10, pady=10)

        self.lbl_estado_acceso = ctk.CTkLabel(
            self.nav_frame,
            text="⏳ Validando entorno...",
            text_color="yellow",
            font=ctk.CTkFont(size=12, weight="bold"),
        )
        self.lbl_estado_acceso.pack(side="right", padx=14)

        self.btn_modo_editor = None
        if self.editor_permitido:
            self.btn_modo_editor = ctk.CTkButton(
                self.nav_frame,
                text="🛠️ Modo Editor",
                width=140,
                fg_color="transparent",
                hover_color="#273746",
                border_width=1,
                border_color="#566573",
                command=self._alternar_modo_editor,
            )
            self.btn_modo_editor.pack(side="right", padx=(0, 12), pady=10)

        # ── CONTENEDORES ──────────────────────────────────────────────────────
        self.contenedor_ingesta  = ctk.CTkFrame(self, fg_color="transparent")
        self.contenedor_reportes = ctk.CTkFrame(self, fg_color="transparent")
        self.contenedor_maestros = ctk.CTkFrame(self, fg_color="transparent")
        self.contenedor_bd       = ctk.CTkFrame(self, fg_color="transparent")

        self.contenedor_ingesta.grid_columnconfigure(1, weight=1)
        self.contenedor_ingesta.grid_rowconfigure(0, weight=1)
        self._construir_panel_ejecucion_global()

        # ── CONSTRUIR MÓDULOS ─────────────────────────────────────────────────
        self._construir_panel_bd()
        self._construir_modulo_ingesta()
        self._construir_modulo_reportes()
        self._construir_modulo_maestros()

        # Siempre iniciar en configuración de BD
        self.mostrar_modulo_bd()
        self._aplicar_restricciones_acceso()
        self._actualizar_estado_modo_editor()

    def _construir_panel_ejecucion_global(self):
        self.frame_ejecucion_global = ctk.CTkFrame(self, height=72, corner_radius=0)
        self.frame_ejecucion_global.pack(side="bottom", fill="x")

        self.lbl_ejecucion_global = ctk.CTkLabel(
            self.frame_ejecucion_global,
            text="Estado general: en espera",
            font=ctk.CTkFont(size=12, weight="bold"),
            anchor="w",
        )
        self.lbl_ejecucion_global.pack(fill="x", padx=14, pady=(8, 2))

        frame_barra_global = ctk.CTkFrame(self.frame_ejecucion_global, fg_color="transparent")
        frame_barra_global.pack(fill="x", padx=14, pady=2)
        frame_barra_global.grid_columnconfigure(0, weight=1)

        self.barra_ejecucion_global = ctk.CTkProgressBar(frame_barra_global, height=10)
        self.barra_ejecucion_global.grid(row=0, column=0, sticky="ew")
        self.barra_ejecucion_global.set(0)

        self.btn_cancelar_ejecucion = ctk.CTkButton(
            frame_barra_global,
            text="Cancelar",
            width=100,
            state="disabled",
            fg_color="#922B21",
            hover_color="#7B241C",
            command=self._cancelar_proceso_actual,
        )
        self.btn_cancelar_ejecucion.grid(row=0, column=1, padx=(8, 0))

        self.lbl_detalle_ejecucion_global = ctk.CTkLabel(
            self.frame_ejecucion_global,
            text="Sin procesos en ejecución.",
            text_color="gray",
            anchor="w",
        )
        self.lbl_detalle_ejecucion_global.pack(fill="x", padx=14, pady=(2, 8))

    def _iniciar_ejecucion_global(self, nombre_proceso: str, detalle: str = "Preparando...", determinate: bool = False) -> int:
        self._ejecucion_global_token += 1
        token = self._ejecucion_global_token
        self._tokens_cancelados.discard(token)

        def _ui():
            try:
                self.barra_ejecucion_global.stop()
            except Exception:
                pass

            modo = "determinate" if determinate else "indeterminate"
            self.barra_ejecucion_global.configure(mode=modo)
            if determinate:
                self.barra_ejecucion_global.set(0)
            else:
                self.barra_ejecucion_global.start()

            self.lbl_ejecucion_global.configure(
                text=f"⏳ {nombre_proceso}",
                text_color="yellow",
            )
            self.lbl_detalle_ejecucion_global.configure(
                text=detalle,
                text_color="gray",
            )
            self.btn_cancelar_ejecucion.configure(state="disabled")

        self.after(0, _ui)
        return token

    def _registrar_proceso_cancelable(self, token: int, nombre_proceso: str, proceso):
        self._proceso_cancelable = proceso
        self._proceso_cancelable_token = token
        self._proceso_cancelable_nombre = nombre_proceso
        self.after(0, lambda: self.btn_cancelar_ejecucion.configure(state="normal"))

    def _limpiar_proceso_cancelable(self, token: int | None):
        if token is None or token != self._proceso_cancelable_token:
            return

        self._proceso_cancelable = None
        self._proceso_cancelable_token = None
        self._proceso_cancelable_nombre = None
        self.after(0, lambda: self.btn_cancelar_ejecucion.configure(state="disabled"))

    def _cancelar_proceso_actual(self):
        proceso = self._proceso_cancelable
        token = self._proceso_cancelable_token
        nombre = self._proceso_cancelable_nombre or "Proceso"

        if proceso is None or token is None:
            return

        if proceso.poll() is not None:
            self._limpiar_proceso_cancelable(token)
            return

        self._tokens_cancelados.add(token)
        self.log_mensaje(f"🛑 Cancelando proceso: {nombre}...")
        self._actualizar_detalle_ejecucion_global(token, "Cancelando por solicitud del usuario...", "orange")
        self.btn_cancelar_ejecucion.configure(state="disabled")

        try:
            proceso.terminate()
        except Exception:
            try:
                proceso.kill()
            except Exception as err:
                self.log_mensaje(f"❌ No se pudo cancelar {nombre}: {err}")

    def _actualizar_ejecucion_global(self, token: int, completado: int, total: int, estado: str, detalle: str):
        if token != self._ejecucion_global_token:
            return

        def _ui():
            try:
                self.barra_ejecucion_global.stop()
            except Exception:
                pass

            self.barra_ejecucion_global.configure(mode="determinate")
            total_seguro = max(total, 1)
            self.barra_ejecucion_global.set(max(0, min(completado, total_seguro)) / total_seguro)
            color = "gray" if estado == "ok" else "orange"
            self.lbl_detalle_ejecucion_global.configure(text=detalle, text_color=color)

        self.after(0, _ui)

    def _actualizar_detalle_ejecucion_global(self, token: int, detalle: str, color: str = "gray"):
        if token != self._ejecucion_global_token:
            return

        self.after(0, lambda: self.lbl_detalle_ejecucion_global.configure(text=detalle, text_color=color))

    def _finalizar_ejecucion_global(self, token: int, nombre_proceso: str, exito: bool, detalle: str):
        if token != self._ejecucion_global_token:
            return

        if token in self._tokens_cancelados:
            exito = False
            detalle = f"{nombre_proceso} cancelado por el usuario."
            self._tokens_cancelados.discard(token)

        self._limpiar_proceso_cancelable(token)

        def _ui():
            try:
                self.barra_ejecucion_global.stop()
            except Exception:
                pass

            self.barra_ejecucion_global.configure(mode="determinate")
            self.barra_ejecucion_global.set(1 if exito else 0)
            self.lbl_ejecucion_global.configure(
                text=(f"✅ {nombre_proceso}" if exito else f"❌ {nombre_proceso}"),
                text_color=("#2ECC71" if exito else "#E74C3C"),
            )
            self.lbl_detalle_ejecucion_global.configure(
                text=detalle,
                text_color=("#2ECC71" if exito else "#E74C3C"),
            )
            self.btn_cancelar_ejecucion.configure(state="disabled")

        self.after(0, _ui)

    def _normalizar_boton_reporte(self, boton: dict) -> dict | None:
        if not isinstance(boton, dict):
            return None

        text = str(boton.get("text") or boton.get("label") or "").strip()
        color = str(boton.get("color") or "#2C3E50").strip() or "#2C3E50"
        script_path = str(boton.get("script_path") or boton.get("archivo") or "").strip()
        section = str(boton.get("section") or "reportes").strip()

        if not text or not script_path or section not in SECCIONES_REPORTE_MAP:
            return None

        script_path_norm = os.path.normpath(script_path)
        coincidencia_default = next(
            (
                item
                for item in BOTONES_REPORTE_PREDETERMINADOS
                if item["text"].casefold() == text.casefold()
                and os.path.normcase(os.path.normpath(item["script_path"]))
                == os.path.normcase(script_path_norm)
                and item["section"] == section
            ),
            None,
        )

        edit_path_raw = boton.get("edit_path")
        if edit_path_raw:
            edit_path = str(edit_path_raw).strip()
        elif coincidencia_default:
            edit_path = coincidencia_default.get("edit_path") or script_path_norm
        else:
            edit_path = script_path_norm

        if "custom" in boton:
            custom = bool(boton.get("custom"))
        elif coincidencia_default:
            custom = bool(coincidencia_default.get("custom", False))
        else:
            custom = os.path.normcase(script_path_norm).startswith(
                os.path.normcase(os.path.join("scripts_sql", "reportes"))
            )

        return {
            "text": text,
            "color": color,
            "script_path": script_path_norm,
            "edit_path": os.path.normpath(edit_path),
            "section": section,
            "custom": custom,
        }

    def _cargar_config_editor(self) -> list[dict]:
        botones = []

        try:
            if os.path.exists(EDITOR_CONFIG_FILE):
                with open(EDITOR_CONFIG_FILE, "r", encoding="utf-8") as file:
                    data = json.load(file)
                for boton in data.get("report_buttons", []):
                    boton_norm = self._normalizar_boton_reporte(boton)
                    if boton_norm:
                        botones.append(boton_norm)
        except (OSError, json.JSONDecodeError, TypeError, ValueError):
            botones = []

        if botones:
            return botones

        botones = [dict(boton) for boton in BOTONES_REPORTE_PREDETERMINADOS]
        self._guardar_config_editor(botones)
        return botones

    def _guardar_config_editor(self, botones=None) -> bool:
        data = {
            "version": 1,
            "report_buttons": botones if botones is not None else self.report_buttons_config,
        }

        try:
            os.makedirs(CONFIG_DIR, exist_ok=True)
            with open(EDITOR_CONFIG_FILE, "w", encoding="utf-8") as file:
                json.dump(data, file, ensure_ascii=False, indent=2)
            return True
        except OSError:
            return False

    def _alternar_modo_editor(self):
        if not self.editor_permitido:
            messagebox.showinfo(
                "Editor deshabilitado",
                "Esta versión fue publicada para centros y no permite edición.",
            )
            return
        if self.editor_mode_activo:
            self._desactivar_modo_editor()
            return
        self._mostrar_login_editor()

    def _mostrar_login_editor(self):
        if self._ventana_login_editor and self._ventana_login_editor.winfo_exists():
            self._ventana_login_editor.lift()
            self._ventana_login_editor.focus()
            return

        dialogo = ctk.CTkToplevel(self)
        dialogo.title("Acceso Modo Editor")
        dialogo.geometry("360x220")
        dialogo.resizable(False, False)
        dialogo.transient(self)

        self._ventana_login_editor = dialogo

        ctk.CTkLabel(
            dialogo,
            text="Modo Editor",
            font=ctk.CTkFont(size=18, weight="bold"),
        ).pack(pady=(18, 6))

        ctk.CTkLabel(
            dialogo,
            text="Ingresa credenciales para editar scripts y crear botones SQL.",
            text_color="gray",
            wraplength=300,
            justify="center",
        ).pack(padx=20, pady=(0, 12))

        entry_usuario = ctk.CTkEntry(dialogo, placeholder_text="Usuario")
        entry_usuario.pack(fill="x", padx=24, pady=6)

        entry_password = ctk.CTkEntry(dialogo, placeholder_text="Contraseña", show="*")
        entry_password.pack(fill="x", padx=24, pady=6)

        def cerrar_dialogo():
            if dialogo.winfo_exists():
                dialogo.destroy()
            self._ventana_login_editor = None

        def validar_acceso(_event=None):
            usuario = entry_usuario.get().strip()
            password = entry_password.get()

            if usuario == "ivan" and password == "ivanar":
                cerrar_dialogo()
                self._activar_modo_editor()
                return

            messagebox.showerror("Acceso denegado", "Usuario o contraseña incorrectos.")
            entry_password.delete(0, "end")
            entry_password.focus()

        botones = ctk.CTkFrame(dialogo, fg_color="transparent")
        botones.pack(fill="x", padx=24, pady=(12, 0))
        botones.grid_columnconfigure(0, weight=1)
        botones.grid_columnconfigure(1, weight=1)

        ctk.CTkButton(
            botones,
            text="Cancelar",
            fg_color="#566573",
            command=cerrar_dialogo,
        ).grid(row=0, column=0, padx=(0, 4), sticky="ew")

        ctk.CTkButton(
            botones,
            text="Ingresar",
            command=validar_acceso,
        ).grid(row=0, column=1, padx=(4, 0), sticky="ew")

        entry_usuario.bind("<Return>", lambda _event: entry_password.focus())
        entry_password.bind("<Return>", validar_acceso)
        dialogo.protocol("WM_DELETE_WINDOW", cerrar_dialogo)
        entry_usuario.focus()

    def _activar_modo_editor(self):
        if not self.editor_permitido:
            return
        self.editor_mode_activo = True
        self._actualizar_estado_modo_editor()
        self.log_mensaje("🛠️ Modo editor activado.")
        self._abrir_gestor_scripts()

    def _desactivar_modo_editor(self):
        self.editor_mode_activo = False
        self._cerrar_gestor_scripts()
        self._actualizar_estado_modo_editor()
        self.log_mensaje("🔒 Modo editor desactivado.")

    def _actualizar_estado_modo_editor(self):
        if not self.btn_modo_editor:
            return
        if self.editor_mode_activo:
            self.btn_modo_editor.configure(
                text="🛠️ Editor ACTIVO",
                fg_color="#7D3C98",
                hover_color="#6C3483",
                border_width=0,
            )
        else:
            self.btn_modo_editor.configure(
                text="🛠️ Modo Editor",
                fg_color="transparent",
                hover_color="#273746",
                border_width=1,
                border_color="#566573",
            )

        if hasattr(self, "frame_editor_reportes"):
            self._actualizar_panel_editor_reportes()
        if hasattr(self, "frame_botones_reportes"):
            self._renderizar_botones_reportes()
        if hasattr(self, "widget_maestros") and self.widget_maestros is not None:
            self.widget_maestros.set_editor_mode(self.editor_mode_activo)

    def _actualizar_panel_editor_reportes(self):
        if not hasattr(self, "frame_editor_reportes"):
            return

        if self.editor_mode_activo:
            if self.frame_editor_reportes.winfo_manager() != "pack":
                self.frame_editor_reportes.pack(
                    fill="x",
                    padx=10,
                    pady=(0, 10),
                    before=self.frame_botones_reportes,
                )
        elif self.frame_editor_reportes.winfo_manager():
            self.frame_editor_reportes.pack_forget()

    def _ruta_edicion_descriptor(self, descriptor: dict) -> str:
        return os.path.normpath(descriptor.get("edit_path") or descriptor["script_path"])

    def _descripcion_script_editable(self, descriptor: dict) -> str:
        ruta_ejecucion = os.path.normpath(descriptor["script_path"])
        ruta_edicion = self._ruta_edicion_descriptor(descriptor)
        if ruta_edicion == ruta_ejecucion:
            return f"{ruta_edicion} | Guarda en APPDATA"
        return f"Edita: {ruta_edicion} | Ejecuta: {ruta_ejecucion} | Guarda en APPDATA"

    def _coincide_boton_reporte(self, boton_a: dict, boton_b: dict) -> bool:
        return (
            str(boton_a.get("text", "")).casefold() == str(boton_b.get("text", "")).casefold()
            and os.path.normcase(os.path.normpath(boton_a.get("script_path", "")))
            == os.path.normcase(os.path.normpath(boton_b.get("script_path", "")))
            and os.path.normcase(os.path.normpath(boton_a.get("edit_path") or boton_a.get("script_path", "")))
            == os.path.normcase(os.path.normpath(boton_b.get("edit_path") or boton_b.get("script_path", "")))
            and str(boton_a.get("section", "")) == str(boton_b.get("section", ""))
        )

    def _eliminar_boton_reporte(self, descriptor: dict):
        indice = next(
            (
                i
                for i, boton in enumerate(self.report_buttons_config)
                if self._coincide_boton_reporte(boton, descriptor)
            ),
            None,
        )
        if indice is None:
            messagebox.showerror("Botón no encontrado", "No se encontró el botón en la configuración actual.")
            return

        boton = self.report_buttons_config[indice]
        ruta_edicion_rel = self._ruta_edicion_descriptor(boton)
        ruta_edicion_abs = ruta_recurso_editable(ruta_edicion_rel)
        eliminar_archivo = False

        if boton.get("custom") and ruta_edicion_rel.lower().endswith(".sql") and os.path.exists(ruta_edicion_abs):
            decision = messagebox.askyesnocancel(
                "Eliminar botón",
                (
                    f"Botón: {boton['text']}\n\n"
                    "Sí: elimina el botón y su archivo SQL\n"
                    "No: elimina solo el botón\n"
                    "Cancelar: no hace cambios\n\n"
                    f"Archivo SQL: {ruta_edicion_rel}"
                ),
            )
            if decision is None:
                return
            eliminar_archivo = bool(decision)
        else:
            if not messagebox.askyesno(
                "Eliminar botón",
                f"¿Eliminar el botón '{boton['text']}' de Análisis y Reportes?",
            ):
                return

        eliminado = self.report_buttons_config.pop(indice)
        if not self._guardar_config_editor():
            self.report_buttons_config.insert(indice, eliminado)
            messagebox.showerror("Error de configuración", "No se pudo guardar la eliminación del botón.")
            return

        error_archivo = None
        if eliminar_archivo:
            try:
                os.remove(ruta_edicion_abs)
            except OSError as err:
                error_archivo = err

        self._renderizar_botones_reportes()
        self._renderizar_gestor_scripts()
        self.log_mensaje(f"🗑️ Botón eliminado: {boton['text']}")

        if error_archivo:
            messagebox.showwarning(
                "Archivo no eliminado",
                f"El botón fue eliminado, pero no se pudo borrar el SQL asociado.\n\n{error_archivo}",
            )

    def _obtener_scripts_editables(self) -> list[dict]:
        scripts = []

        for boton in self.report_buttons_config:
            descripcion = self._descripcion_script_editable(boton)
            scripts.append(
                {
                    **boton,
                    "origin": "Análisis y Reportes",
                    "subtitle": f"{SECCIONES_REPORTE_MAP[boton['section']]} | {descripcion}",
                }
            )

        for boton in SCRIPTS_MAESTROS_EDITABLES:
            descripcion = self._descripcion_script_editable(boton)
            scripts.append(
                {
                    **boton,
                    "origin": "Gestión de Maestros",
                    "subtitle": descripcion,
                }
            )

        return scripts

    def _abrir_gestor_scripts(self):
        if not self.editor_mode_activo:
            return

        if self._ventana_gestor_scripts and self._ventana_gestor_scripts.winfo_exists():
            self._ventana_gestor_scripts.lift()
            self._ventana_gestor_scripts.focus()
            self._renderizar_gestor_scripts()
            return

        ventana = ctk.CTkToplevel(self)
        ventana.title("Scripts Editables")
        ventana.geometry("820x560")
        ventana.transient(self)

        self._ventana_gestor_scripts = ventana

        cabecera = ctk.CTkFrame(ventana)
        cabecera.pack(fill="x", padx=12, pady=(12, 8))
        cabecera.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(
            cabecera,
            text="Scripts editables",
            font=ctk.CTkFont(size=18, weight="bold"),
        ).grid(row=0, column=0, sticky="w", padx=12, pady=(10, 2))

        ctk.CTkLabel(
            cabecera,
            text="Incluye todos los botones de reportes y los 2 scripts autorizados de maestros.",
            text_color="gray",
        ).grid(row=1, column=0, sticky="w", padx=12, pady=(0, 10))

        acciones = ctk.CTkFrame(cabecera, fg_color="transparent")
        acciones.grid(row=0, column=1, rowspan=2, padx=12, pady=10, sticky="e")

        ctk.CTkButton(
            acciones,
            text="➕ Nuevo botón SQL",
            fg_color="#117A65",
            hover_color="#0E6655",
            command=self._abrir_dialogo_nuevo_sql,
        ).pack(side="left", padx=(0, 6))

        ctk.CTkButton(
            acciones,
            text="📦 Publicar centros",
            fg_color="#B9770E",
            hover_color="#9C640C",
            command=self._publicar_version_centros,
        ).pack(side="left", padx=(0, 6))

        ctk.CTkButton(
            acciones,
            text="📥 Importar",
            fg_color="#2874A6",
            hover_color="#21618C",
            command=self._importar_paquete_actualizaciones,
        ).pack(side="left", padx=(0, 6))

        ctk.CTkButton(
            acciones,
            text="↩ Originales",
            fg_color="#626567",
            hover_color="#515A5A",
            command=self._restaurar_scripts_originales,
        ).pack(side="left", padx=(0, 6))

        ctk.CTkButton(
            acciones,
            text="Cerrar",
            fg_color="#566573",
            command=self._cerrar_gestor_scripts,
        ).pack(side="left")

        self._scroll_gestor_scripts = ctk.CTkScrollableFrame(ventana)
        self._scroll_gestor_scripts.pack(fill="both", expand=True, padx=12, pady=(0, 12))

        ventana.protocol("WM_DELETE_WINDOW", self._cerrar_gestor_scripts)
        self._renderizar_gestor_scripts()

    def _cerrar_gestor_scripts(self):
        if self._ventana_gestor_scripts and self._ventana_gestor_scripts.winfo_exists():
            self._ventana_gestor_scripts.destroy()
        self._ventana_gestor_scripts = None
        self._scroll_gestor_scripts = None

    def _renderizar_gestor_scripts(self):
        if not self._scroll_gestor_scripts or not self._scroll_gestor_scripts.winfo_exists():
            return

        for widget in self._scroll_gestor_scripts.winfo_children():
            widget.destroy()

        scripts = self._obtener_scripts_editables()
        if not scripts:
            ctk.CTkLabel(
                self._scroll_gestor_scripts,
                text="No hay scripts editables configurados.",
                text_color="gray",
            ).pack(pady=20)
            return

        origen_actual = None
        for descriptor in scripts:
            if descriptor["origin"] != origen_actual:
                origen_actual = descriptor["origin"]
                ctk.CTkLabel(
                    self._scroll_gestor_scripts,
                    text=origen_actual,
                    font=ctk.CTkFont(size=15, weight="bold"),
                ).pack(anchor="w", padx=10, pady=(16, 8))

            self._agregar_fila_gestor_script(descriptor)

    def _agregar_fila_gestor_script(self, descriptor: dict):
        fila = ctk.CTkFrame(self._scroll_gestor_scripts, corner_radius=10)
        fila.pack(fill="x", padx=8, pady=4)
        fila.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(
            fila,
            text=descriptor["text"],
            font=ctk.CTkFont(size=13, weight="bold"),
            anchor="w",
        ).grid(row=0, column=0, sticky="w", padx=12, pady=(10, 0))

        ctk.CTkLabel(
            fila,
            text=descriptor.get("subtitle", descriptor["script_path"]),
            text_color="gray",
            anchor="w",
            wraplength=560,
            justify="left",
        ).grid(row=1, column=0, sticky="w", padx=12, pady=(2, 10))

        ctk.CTkButton(
            fila,
            text="✏️ Editar",
            width=110,
            fg_color="#34495E",
            hover_color="#2C3E50",
            command=lambda d=descriptor: self._abrir_editor_script(d),
        ).grid(row=0, column=1, rowspan=2, padx=12, pady=10)

        if descriptor.get("origin") == "Análisis y Reportes":
            ctk.CTkButton(
                fila,
                text="🗑️ Eliminar",
                width=110,
                fg_color="#922B21",
                hover_color="#7B241C",
                command=lambda d=descriptor: self._eliminar_boton_reporte(d),
            ).grid(row=0, column=2, rowspan=2, padx=(0, 12), pady=10)

    def _abrir_editor_script(self, descriptor: dict):
        ruta_rel = self._ruta_edicion_descriptor(descriptor)
        ruta_abs_lectura = resolver_ruta_lectura_editable(ruta_rel)
        ruta_abs_guardado = ruta_recurso_editable(ruta_rel)
        ruta_ejecucion = os.path.normpath(descriptor["script_path"])

        if not os.path.exists(ruta_abs_lectura):
            messagebox.showerror("Script no encontrado", f"No existe:\n{ruta_abs_lectura}")
            return

        try:
            with open(ruta_abs_lectura, "r", encoding="utf-8", errors="replace") as file:
                contenido_inicial = file.read()
        except OSError as err:
            messagebox.showerror("Error de lectura", f"No se pudo abrir el script.\n\n{err}")
            return

        ventana = ctk.CTkToplevel(self)
        ventana.title(f"Editor - {descriptor['text']}")
        ventana.geometry("1000x720")
        ventana.transient(self)

        cabecera = ctk.CTkFrame(ventana)
        cabecera.pack(fill="x", padx=12, pady=(12, 8))
        cabecera.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(
            cabecera,
            text=descriptor["text"],
            font=ctk.CTkFont(size=18, weight="bold"),
            anchor="w",
        ).grid(row=0, column=0, sticky="w", padx=12, pady=(10, 2))

        ctk.CTkLabel(
            cabecera,
            text=(
                f"{descriptor.get('origin', 'Script')} | {self._descripcion_script_editable(descriptor)}"
                if ruta_rel != ruta_ejecucion
                else f"{descriptor.get('origin', 'Script')} | {ruta_rel}"
            ),
            text_color="gray",
            anchor="w",
        ).grid(row=1, column=0, sticky="w", padx=12, pady=(0, 10))

        editor = ctk.CTkTextbox(ventana, font=("Consolas", 12), wrap="none")
        editor.pack(fill="both", expand=True, padx=12, pady=(0, 12))
        editor.insert("1.0", contenido_inicial)

        botones = ctk.CTkFrame(ventana, fg_color="transparent")
        botones.pack(fill="x", padx=12, pady=(0, 12))

        def guardar_script():
            contenido = editor.get("1.0", "end-1c")
            try:
                os.makedirs(os.path.dirname(ruta_abs_guardado), exist_ok=True)
                with open(ruta_abs_guardado, "w", encoding="utf-8", newline="\n") as file:
                    file.write(contenido)
            except OSError as err:
                messagebox.showerror("Error al guardar", f"No se pudo guardar el script.\n\n{err}")
                return

            self.log_mensaje(f"📝 Script guardado en APPDATA: {ruta_rel}")
            messagebox.showinfo(
                "Guardado",
                f"Se guardó correctamente la copia editable:\n{ruta_abs_guardado}\n\n"
                "La ejecución usará esta copia mientras exista.",
            )

        ctk.CTkButton(
            botones,
            text="Guardar",
            fg_color="#1F618D",
            hover_color="#154360",
            command=guardar_script,
        ).pack(side="right")

        ctk.CTkButton(
            botones,
            text="Cerrar",
            fg_color="#566573",
            command=ventana.destroy,
        ).pack(side="right", padx=(0, 8))

    def _editar_script_maestro(self, titulo: str, script_path: str):
        self._abrir_editor_script(
            {
                "text": titulo,
                "script_path": script_path,
                "origin": "Gestión de Maestros",
            }
        )

    def _sanitizar_nombre_archivo(self, nombre: str) -> str:
        nombre = re.sub(r'[<>:"/\\|?*]+', '', nombre or '').strip()
        nombre = re.sub(r'\s+', ' ', nombre).rstrip('. ')
        return nombre or 'Nuevo reporte'

    def _carpeta_sistema_distribuible(self) -> str:
        if getattr(sys, "frozen", False):
            return INSTALL_DIR

        candidato_dist = os.path.join(INSTALL_DIR, "dist", "SistemaSaludCusco")
        exe_dist = os.path.join(candidato_dist, "SistemaSaludCusco.exe")
        if os.path.exists(exe_dist):
            return candidato_dist

        return INSTALL_DIR

    def _crear_paquete_actualizaciones(self, ruta_paquete: str, disable_editor: bool) -> int:
        os.makedirs(os.path.dirname(ruta_paquete), exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        manifest = {
            "version": 1,
            "app": "Proyecto_Salud_Cusco",
            "package_id": f"psc_{timestamp}",
            "created_at": datetime.now().isoformat(timespec="seconds"),
            "disable_editor": bool(disable_editor),
            "description": "Paquete de scripts y botones editados desde modo editor.",
        }

        archivos = 0
        with zipfile.ZipFile(ruta_paquete, "w", compression=zipfile.ZIP_DEFLATED) as zip_file:
            zip_file.writestr(PACKAGE_MANIFEST, json.dumps(manifest, ensure_ascii=False, indent=2))

            config_botones = {
                "version": 1,
                "report_buttons": self.report_buttons_config,
            }
            zip_file.writestr(
                "editor_buttons.json",
                json.dumps(config_botones, ensure_ascii=False, indent=2),
            )
            archivos += 1

            if os.path.isdir(EDITOR_RUNTIME_DIR):
                for raiz, _, nombres in os.walk(EDITOR_RUNTIME_DIR):
                    for nombre in nombres:
                        ruta_archivo = os.path.join(raiz, nombre)
                        arcname = os.path.relpath(ruta_archivo, CONFIG_DIR).replace(os.sep, "/")
                        zip_file.write(ruta_archivo, arcname)
                        archivos += 1

            zip_file.writestr(
                "LEEME_PAQUETE.txt",
                "Este archivo es aplicado automaticamente por SistemaSaludCusco.exe. No descomprimir manualmente.\n",
            )

        return archivos

    def _publicar_version_centros(self):
        if not self.editor_mode_activo:
            return

        origen = self._carpeta_sistema_distribuible()
        if not os.path.isdir(origen):
            messagebox.showerror("No se pudo publicar", f"No se encontró carpeta base del sistema:\n{origen}")
            return

        carpeta_destino = filedialog.askdirectory(
            title="Seleccionar carpeta donde crear la versión para centros"
        )
        if not carpeta_destino:
            return

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        destino = os.path.join(carpeta_destino, f"SistemaSaludCusco_Centros_{timestamp}")

        origen_abs = os.path.abspath(origen)
        destino_abs = os.path.abspath(destino)
        try:
            if os.path.commonpath([origen_abs, destino_abs]) == origen_abs:
                messagebox.showerror(
                    "Destino no válido",
                    "El destino no puede estar dentro de la carpeta del sistema que se está copiando.",
                )
                return
        except ValueError:
            pass

        try:
            shutil.copytree(
                origen_abs,
                destino_abs,
                ignore=shutil.ignore_patterns("__pycache__", "*.log"),
            )
            ruta_paquete = os.path.join(destino_abs, PACKAGE_FILE_NAME)
            total_archivos = self._crear_paquete_actualizaciones(ruta_paquete, disable_editor=True)

            leeme = os.path.join(destino_abs, "LEEME_CENTROS.txt")
            with open(leeme, "w", encoding="utf-8", newline="\n") as file:
                file.write(
                    "Sistema Salud Cusco - Versión para centros\n"
                    "==========================================\n\n"
                    "1. Abrir SistemaSaludCusco.exe.\n"
                    "2. No descomprimir ni mover archivos internos.\n"
                    "3. El paquete_actualizaciones.pscpack se aplica automaticamente al primer inicio.\n"
                    "4. El modo editor esta deshabilitado en esta versión publicada.\n"
                )

            self.log_mensaje(f"📦 Versión para centros publicada: {destino_abs}")
            messagebox.showinfo(
                "Publicación completada",
                f"Se creó la versión para centros:\n{destino_abs}\n\n"
                f"Paquete incluido: {PACKAGE_FILE_NAME}\n"
                f"Archivos de actualización: {total_archivos}\n\n"
                "Envía esa carpeta completa a los centros.",
            )
        except Exception as exc:
            messagebox.showerror("Error al publicar", f"No se pudo crear la versión para centros.\n\n{exc}")

    def _importar_paquete_actualizaciones(self):
        if not self.editor_mode_activo:
            return

        ruta_paquete = filedialog.askopenfilename(
            title="Importar paquete de actualización",
            filetypes=[("Paquete Salud Cusco", "*.pscpack"), ("Todos los archivos", "*.*")],
        )
        if not ruta_paquete:
            return

        ok, mensaje = aplicar_paquete_actualizaciones(ruta_paquete, force=True)
        if not ok:
            messagebox.showerror("No se pudo importar", mensaje)
            return

        self.report_buttons_config = self._cargar_config_editor()
        self._renderizar_botones_reportes()
        self._renderizar_gestor_scripts()
        self.log_mensaje(f"📥 Paquete importado: {ruta_paquete}")
        messagebox.showinfo("Paquete importado", mensaje)

    def _restaurar_scripts_originales(self):
        if not self.editor_mode_activo:
            return

        confirmar = messagebox.askyesno(
            "Restaurar originales",
            "Esto eliminará las copias editables guardadas en APPDATA y restaurará los botones base.\n\n"
            "No se borran datos de PostgreSQL ni archivos de ingesta.\n\n"
            "¿Continuar?",
        )
        if not confirmar:
            return

        try:
            if os.path.isdir(EDITOR_RUNTIME_DIR):
                shutil.rmtree(EDITOR_RUNTIME_DIR)

            self.report_buttons_config = [dict(boton) for boton in BOTONES_REPORTE_PREDETERMINADOS]
            if not self._guardar_config_editor():
                raise OSError("No se pudo guardar editor_buttons.json")

            if os.path.exists(INSTALLED_PACKAGE_FILE):
                os.remove(INSTALLED_PACKAGE_FILE)

            self._renderizar_botones_reportes()
            self._renderizar_gestor_scripts()
            self.log_mensaje("↩ Scripts editables restaurados a originales.")
            messagebox.showinfo("Restaurado", "Se restauraron las copias editables y botones originales.")
        except Exception as exc:
            messagebox.showerror("Error al restaurar", f"No se pudo restaurar.\n\n{exc}")

    def _abrir_dialogo_nuevo_sql(self):
        if not self.editor_mode_activo:
            return

        dialogo = ctk.CTkToplevel(self)
        dialogo.title("Nuevo botón SQL")
        dialogo.geometry("440x260")
        dialogo.resizable(False, False)
        dialogo.transient(self)

        ctk.CTkLabel(
            dialogo,
            text="Crear botón SQL",
            font=ctk.CTkFont(size=18, weight="bold"),
        ).pack(pady=(18, 8))

        ctk.CTkLabel(
            dialogo,
            text="Se creará un nuevo SQL editable en APPDATA y un botón persistente.",
            text_color="gray",
            wraplength=360,
            justify="center",
        ).pack(padx=20, pady=(0, 12))

        entry_nombre = ctk.CTkEntry(dialogo, placeholder_text="Nombre del botón")
        entry_nombre.pack(fill="x", padx=24, pady=6)

        cb_seccion = ctk.CTkOptionMenu(dialogo, values=list(SECCIONES_REPORTE_INV.keys()))
        cb_seccion.pack(fill="x", padx=24, pady=6)
        cb_seccion.set(SECCIONES_REPORTE_MAP["reportes"])

        def crear_boton_sql():
            nombre = entry_nombre.get().strip()
            if not nombre:
                messagebox.showwarning("Nombre requerido", "Ingresa un nombre para el botón.")
                return

            if any(boton["text"].casefold() == nombre.casefold() for boton in self.report_buttons_config):
                messagebox.showwarning("Nombre duplicado", "Ya existe un botón con ese nombre.")
                return

            nombre_archivo = self._sanitizar_nombre_archivo(nombre)
            ruta_rel = os.path.normpath(os.path.join("scripts_sql", "reportes", f"{nombre_archivo}.sql"))
            ruta_abs = ruta_recurso_editable(ruta_rel)

            if os.path.exists(ruta_abs):
                messagebox.showwarning(
                    "Archivo existente",
                    f"Ya existe un archivo con ese nombre:\n{ruta_abs}",
                )
                return

            os.makedirs(os.path.dirname(ruta_abs), exist_ok=True)

            plantilla = (
                "-- Nuevo reporte editable\n"
                "-- Usa {ANIO} y {FILTRO_MES} si quieres filtros dinámicos.\n"
                "SELECT 1 AS ejemplo;\n"
            )

            try:
                with open(ruta_abs, "w", encoding="utf-8", newline="\n") as file:
                    file.write(plantilla)
            except OSError as err:
                messagebox.showerror("Error al crear archivo", f"No se pudo crear el SQL.\n\n{err}")
                return

            nuevo_boton = {
                "text": nombre,
                "color": "#117A65",
                "script_path": ruta_rel,
                "edit_path": ruta_rel,
                "section": SECCIONES_REPORTE_INV[cb_seccion.get()],
                "custom": True,
            }
            self.report_buttons_config.append(nuevo_boton)

            if not self._guardar_config_editor():
                self.report_buttons_config.pop()
                try:
                    os.remove(ruta_abs)
                except OSError:
                    pass
                messagebox.showerror(
                    "Error de configuración",
                    "No se pudo guardar la configuración del nuevo botón.",
                )
                return

            self._renderizar_botones_reportes()
            self._renderizar_gestor_scripts()
            self.log_mensaje(f"🆕 Botón SQL creado: {nombre} -> {ruta_rel}")
            dialogo.destroy()
            self._abrir_editor_script({**nuevo_boton, "origin": "Análisis y Reportes"})

        botones = ctk.CTkFrame(dialogo, fg_color="transparent")
        botones.pack(fill="x", padx=24, pady=(16, 0))
        botones.grid_columnconfigure(0, weight=1)
        botones.grid_columnconfigure(1, weight=1)

        ctk.CTkButton(
            botones,
            text="Cancelar",
            fg_color="#566573",
            command=dialogo.destroy,
        ).grid(row=0, column=0, padx=(0, 4), sticky="ew")

        ctk.CTkButton(
            botones,
            text="Crear y editar",
            fg_color="#117A65",
            hover_color="#0E6655",
            command=crear_boton_sql,
        ).grid(row=0, column=1, padx=(4, 0), sticky="ew")

        entry_nombre.focus()

    # ══════════════════════════════════════════════════════════════════════════
    # MÓDULO: CONFIGURAR BASE DE DATOS (UNIVERSAL)
    # ══════════════════════════════════════════════════════════════════════════
    def _construir_panel_bd(self):
        """Panel universal: detecta PostgreSQL automáticamente y guía al usuario."""
        for widget in self.contenedor_bd.winfo_children():
            widget.destroy()

        self.contenedor_bd.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(
            self.contenedor_bd,
            text="🗄️  Configuración de Base de Datos",
            font=ctk.CTkFont(size=20, weight="bold")
        ).pack(fill="x", padx=24, pady=(16, 8))

        self.frame_estado_bd = ctk.CTkFrame(self.contenedor_bd, corner_radius=10)
        self.frame_estado_bd.pack(fill="x", padx=24, pady=(0, 12))

        self.lbl_estado_pg = ctk.CTkLabel(
            self.frame_estado_bd,
            text="⏳ Detectando PostgreSQL...",
            font=ctk.CTkFont(size=14), text_color="yellow"
        )
        self.lbl_estado_pg.pack(pady=15, padx=15)

        self.frame_contenido_bd = ctk.CTkFrame(self.contenedor_bd, fg_color="transparent")
        self.frame_contenido_bd.pack(fill="both", expand=True, padx=24, pady=(0, 16))

        self._detectar_estado_postgresql()

    def _detectar_estado_postgresql(self):
        """Detecta el estado de PostgreSQL y muestra la interfaz apropiada."""
        for widget in self.frame_contenido_bd.winfo_children():
            widget.destroy()

        info_pg = detectar_postgresql_existente()

        def actualizar_ui():
            if info_pg["instalado"] and info_pg["servicio_activo"]:
                self.lbl_estado_pg.configure(
                    text=f"✅ PostgreSQL {info_pg['version']} detectado y activo",
                    text_color="#2ECC71"
                )
                self._mostrar_opciones_bd_existente(info_pg)
            elif info_pg["instalado"] and not info_pg["servicio_activo"]:
                self.lbl_estado_pg.configure(
                    text=f"⚠️  PostgreSQL {info_pg['version']} instalado pero servicio detenido",
                    text_color="orange"
                )
                self._mostrar_opciones_bd_instalado_detenido(info_pg)
            else:
                self.lbl_estado_pg.configure(
                    text="❌ PostgreSQL no encontrado en este equipo",
                    text_color="#E74C3C"
                )
                self._mostrar_opciones_instalar()

        self.after(0, actualizar_ui)

    def _mostrar_opciones_instalar(self):
        """Muestra la interfaz para instalar PostgreSQL."""
        frame = ctk.CTkFrame(self.frame_contenido_bd, corner_radius=10)
        frame.pack(fill="both", expand=True, pady=(0, 12))

        ctk.CTkLabel(
            frame,
            text="PostgreSQL no está instalado en esta computadora.",
            font=ctk.CTkFont(size=13), text_color="orange"
        ).pack(pady=(20, 5))

        ctk.CTkLabel(
            frame,
            text="Esta aplicación necesita PostgreSQL para funcionar con grandes volúmenes de datos.",
            font=ctk.CTkFont(size=11), text_color="gray"
        ).pack(pady=(0, 5))

        ctk.CTkLabel(
            frame,
            text="Haga clic en el botón de abajo para instalar PostgreSQL automáticamente.",
            font=ctk.CTkFont(size=11), text_color="gray"
        ).pack(pady=(0, 20))

        self.btn_instalar_pg = ctk.CTkButton(
            frame,
            text="🚀 INSTALAR POSTGRESQL AUTOMÁTICAMENTE",
            height=50,
            font=ctk.CTkFont(size=14, weight="bold"),
            fg_color="#27AE60", hover_color="#1E8449",
            command=self._instalar_postgresql_accion
        )
        self.btn_instalar_pg.pack(padx=30, pady=(0, 15), fill="x")

        self.lbl_progreso_instalacion = ctk.CTkLabel(
            frame,
            text="",
            text_color="gray", font=ctk.CTkFont(size=11)
        )
        self.lbl_progreso_instalacion.pack(pady=(0, 10))

        self.progress_bar = ctk.CTkProgressBar(frame, height=8)
        self.progress_bar.pack(fill="x", padx=30, pady=(0, 5))
        self.progress_bar.set(0)
        self.progress_bar.pack_forget()

    def _mostrar_opciones_bd_instalado_detenido(self, info_pg: dict):
        """PostgreSQL instalado pero servicio detenido."""
        frame = ctk.CTkFrame(self.frame_contenido_bd, corner_radius=10)
        frame.pack(fill="both", expand=True, pady=(0, 12))

        ctk.CTkLabel(
            frame,
            text=f"PostgreSQL {info_pg['version']} está instalado pero el servicio no está corriendo.",
            font=ctk.CTkFont(size=12), text_color="orange"
        ).pack(pady=(20, 10))

        ctk.CTkButton(
            frame,
            text="▶️  INICIAR SERVICIO DE POSTGRESQL",
            height=45,
            font=ctk.CTkFont(size=13, weight="bold"),
            fg_color="#2980B9", hover_color="#1A5276",
            command=self._iniciar_servicio_accion
        ).pack(padx=30, pady=(0, 15), fill="x")

        ctk.CTkButton(
            frame,
            text="🔄 Volver a detectar",
            height=32,
            fg_color="#424242", hover_color="#333333",
            command=self._detectar_estado_postgresql
        ).pack(padx=30, pady=(0, 15), fill="x")

    def _mostrar_opciones_bd_existente(self, info_pg: dict):
        """PostgreSQL instalado y corriendo - verificar/crear BD."""
        frame = ctk.CTkFrame(self.frame_contenido_bd, corner_radius=10)
        frame.pack(fill="both", expand=True, pady=(0, 12))

        ctk.CTkLabel(
            frame,
            text=f"✅ PostgreSQL {info_pg['version']} está activo",
            font=ctk.CTkFont(size=13), text_color="#2ECC71"
        ).pack(pady=(15, 5))

        ctk.CTkLabel(
            frame,
            text=f"📦 Puerto: {info_pg['puerto']}  |  Usuario: postgres",
            font=ctk.CTkFont(size=11), text_color="gray"
        ).pack(pady=(0, 15))

        self.frame_botones_bd = ctk.CTkFrame(frame, fg_color="transparent")
        self.frame_botones_bd.pack(pady=(0, 15), fill="x", padx=20)
        self.frame_botones_bd.grid_columnconfigure(0, weight=1)
        self.frame_botones_bd.grid_columnconfigure(1, weight=1)

        self.btn_inicializar_bd = ctk.CTkButton(
            self.frame_botones_bd,
            text="🔄 INICIALIZAR BASE DE DATOS",
            height=45,
            font=ctk.CTkFont(size=13, weight="bold"),
            fg_color="#27AE60", hover_color="#1E8449",
            command=self._inicializar_bd_automatico
        )
        self.btn_inicializar_bd.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 10))

        self.btn_verificar_bd = ctk.CTkButton(
            self.frame_botones_bd,
            text="🔍 Verificar estado",
            height=35,
            fg_color="#5D6D7E", hover_color="#34495E",
            command=self._verificar_y_habilitar
        )
        self.btn_verificar_bd.grid(row=1, column=0, sticky="ew", padx=(0, 5))

        self.btn_recargar_estado = ctk.CTkButton(
            self.frame_botones_bd,
            text="🔄 Recargar",
            height=35,
            fg_color="#424242", hover_color="#333333",
            command=self._detectar_estado_postgresql
        )
        self.btn_recargar_estado.grid(row=1, column=1, sticky="ew", padx=(5, 0))

        ctk.CTkLabel(
            frame,
            text="📋 Log de operaciones:",
            font=ctk.CTkFont(size=11), text_color="gray"
        ).pack(anchor="w", padx=20, pady=(5, 2))

        self.log_bd_widget = ctk.CTkTextbox(frame, height=200, font=("Consolas", 11))
        self.log_bd_widget.pack(fill="both", expand=True, padx=20, pady=(0, 15))
        self.log_bd_widget.configure(state="disabled")

        self._verificar_y_habilitar()

    def _log_bd(self, mensaje: str):
        """Escribe en el log del panel BD (thread-safe)."""
        def _escribir():
            try:
                self.log_bd_widget.configure(state="normal")
                self.log_bd_widget.insert("end", mensaje + "\n")
                self.log_bd_widget.see("end")
                self.log_bd_widget.configure(state="disabled")
            except Exception:
                pass
        try:
            self.after(0, _escribir)
        except Exception:
            pass

    def _pedir_password_dialogo(self) -> str:
        """Muestra diálogo para pedir contraseña con todas las opciones."""
        from tkinter import Toplevel, Label, Entry, Button, Frame, messagebox
        
        resultado = {"password": None, "cancelado": True, "opcion": None}

        def cerrar_dialogo():
            try:
                dialogo.grab_release()
            except Exception:
                pass
            try:
                if dialogo.winfo_exists():
                    dialogo.destroy()
            except Exception:
                pass
        
        def on_aceptar():
            password = entry_pass.get().strip()
            if not password:
                messagebox.showwarning("Contraseña requerida", "Ingresa una contraseña para continuar.")
                entry_pass.focus_set()
                return
            resultado["password"] = password
            resultado["opcion"] = "aceptar"
            cerrar_dialogo()
        
        def on_recuperar():
            resultado["opcion"] = "recuperar"
            cerrar_dialogo()
        
        def on_reinstalar():
            resultado["opcion"] = "reinstalar"
            cerrar_dialogo()
        
        def on_cancelar():
            resultado["opcion"] = "cancelar"
            cerrar_dialogo()
        
        # Crear diálogo
        dialogo = Toplevel(self)
        self._dialogo_password = dialogo
        dialogo.title("CONEXION A POSTGRESQL")
        dialogo.geometry("500x350")
        dialogo.resizable(False, False)
        dialogo.grab_set()
        dialogo.transient(self)
        dialogo.protocol("WM_DELETE_WINDOW", on_cancelar)
        
        # Centrar
        dialogo.update_idletasks()
        x = self.winfo_x() + (self.winfo_width() // 2) - 250
        y = self.winfo_y() + (self.winfo_height() // 2) - 175
        dialogo.geometry(f"+{x}+{y}")
        
        # Titulo
        Label(dialogo, text="CONEXION A POSTGRESQL", font=("Arial", 14, "bold"), fg="#2C3E50").pack(pady=10)
        Label(dialogo, text="No se pudo conectar automaticamente", font=("Arial", 10), fg="#E74C3C").pack()
        
        # Campo contraseña
        Label(dialogo, text="Ingresa la contraseña de PostgreSQL:", font=("Arial", 11)).pack(pady=(15, 5))
        
        frame_entry = Frame(dialogo)
        frame_entry.pack()
        Label(frame_entry, text="postgres@localhost:5432", font=("Arial", 9), fg="gray").pack()
        entry_pass = Entry(frame_entry, show="*", width=30, font=("Arial", 12))
        entry_pass.pack(pady=5)
        entry_pass.focus()
        
        # Botones principales
        frame_btn = Frame(dialogo)
        frame_btn.pack(pady=15)
        
        btn_aceptar = Button(frame_btn, text="CONECTAR", command=on_aceptar, bg="#27AE60", fg="white", font=("Arial", 11, "bold"), width=15, height=2)
        btn_aceptar.pack(side="left", padx=5)
        
        # Separador
        Label(dialogo, text="---------------- O ----------------", fg="gray").pack(pady=5)
        
        # Opciones
        Label(dialogo, text="¿No funciona?", font=("Arial", 10, "bold")).pack()
        
        frame_opc = Frame(dialogo)
        frame_opc.pack(pady=5)
        
        btn_rec = Button(frame_opc, text="RECUPERAR PASS", command=on_recuperar, bg="#F39C12", fg="white", width=18, height=2)
        btn_rec.pack(side="left", padx=3)
        
        btn_reins = Button(frame_opc, text="REINSTALAR PG", command=on_reinstalar, bg="#3498DB", fg="white", width=18, height=2)
        btn_reins.pack(side="left", padx=3)
        
        btn_canc = Button(dialogo, text="CANCELAR", command=on_cancelar, bg="#95A5A6", fg="white", width=20, height=1)
        btn_canc.pack(pady=8)
        
        # Bind
        entry_pass.bind("<Return>", lambda e: on_aceptar())
        
        self.wait_window(dialogo)
        self._dialogo_password = None
        
        # Procesar resultado
        if resultado["opcion"] == "cancelar" or resultado["opcion"] is None:
            return ""
        
        if resultado["opcion"] == "recuperar":
            self._recuperar_password_automatico()
            return ""
        
        if resultado["opcion"] == "reinstalar":
            self._instalar_postgresql_accion()
            return ""
        
        return resultado["password"] if resultado["password"] else ""

    def _pedir_password_postgres(self, mensaje: str = ""):
        """Muestra un diálogo para pedir la contraseña de PostgreSQL."""
        from tkinter import simpledialog
        
        self._log_bd("📝 Abriendo diálogo para ingresar contraseña...")
        
        if mensaje:
            mensaje_completo = mensaje + "\n\nIngresa la contraseña que usaste al instalar PostgreSQL:"
        else:
            mensaje_completo = "Ingresa la contraseña del usuario 'postgres' de PostgreSQL:"
        
        password = simpledialog.askstring(
            "Contraseña de PostgreSQL",
            mensaje_completo
        )
        
        if not password:
            self._log_bd("❌ Operación cancelada por el usuario")
            self.btn_inicializar_bd.configure(state="normal", text="🔄 INICIALIZAR BASE DE DATOS")
            return
        
        # Guardar la contraseña y reintentar
        self._log_bd("   🔍 Intentando con contraseña proporcionada...")
        try:
            from db_config import update_db_config
            update_db_config(password=password)
            self.db_config = get_db_config()
            ok = verificar_bd_esquema(config=self.db_config, log=self._log_bd, guardar_password=True)
            
            if ok:
                self._log_bd("\n✅ ¡SISTEMA LISTO!")
                self._habilitar_sistema()
            else:
                self._log_bd("❌ La contraseña proporcionada no funcionó")
                self._ofrecer_opciones_recuperacion()
        except PasswordRequeridoError as pw_err:
            self._log_bd("❌ %s" % pw_err)
            self._ofrecer_opciones_recuperacion()
        except Exception as e:
            self._log_bd("❌ Error: %s" % e)
            self.btn_inicializar_bd.configure(state="normal", text="🔄 INICIALIZAR BASE DE DATOS")
    
    def _ofrecer_opciones_recuperacion(self):
        """Ofrece opciones cuando la contraseña no funciona."""
        from tkinter import Toplevel, Label, Button, Frame, messagebox
        
        resultado = {"opcion": None}
        
        def on_recuperar():
            resultado["opcion"] = "recuperar"
            dialogo.destroy()
        
        def on_reinstalar():
            resultado["opcion"] = "reinstalar"
            dialogo.destroy()
        
        def on_cancelar():
            resultado["opcion"] = "cancelar"
            dialogo.destroy()
        
        # Crear dialogo
        dialogo = Toplevel(self)
        dialogo.title("OPCIONES DE RECUPERACION")
        dialogo.geometry("400x250")
        dialogo.resizable(False, False)
        dialogo.grab_set()
        dialogo.transient(self)
        
        # Centrar
        dialogo.update_idletasks()
        x = self.winfo_x() + (self.winfo_width() // 2) - 200
        y = self.winfo_y() + (self.winfo_height() // 2) - 125
        dialogo.geometry(f"+{x}+{y}")
        
        # Titulo
        Label(dialogo, text="CONTRASEÑA INCORRECTA", font=("Arial", 14, "bold"), fg="#E74C3C").pack(pady=10)
        Label(dialogo, text="La contraseña no funcionó", font=("Arial", 11)).pack()
        
        Label(dialogo, text="¿Qué deseas hacer?", font=("Arial", 11, "bold")).pack(pady=15)
        
        # Botones
        frame_btn = Frame(dialogo)
        frame_btn.pack(pady=10)
        
        btn_rec = Button(frame_btn, text="RECUPERAR PASS\n(modifica pg_hba.conf)", 
                   command=on_recuperar, bg="#F39C12", fg="white", 
                   font=("Arial", 10, "bold"), width=20, height=3)
        btn_rec.pack(pady=5)
        
        btn_reins = Button(frame_btn, text="REINSTALAR PostgreSQL\n(mantiene tus datos)", 
                       command=on_reinstalar, bg="#3498DB", fg="white", 
                       font=("Arial", 10, "bold"), width=20, height=3)
        btn_reins.pack(pady=5)
        
        btn_canc = Button(dialogo, text="CANCELAR", command=on_cancelar, 
                        bg="#95A5A6", fg="white", width=20)
        btn_canc.pack(pady=10)
        
        self.wait_window(dialogo)
        
        if resultado["opcion"] == "recuperar":
            self._log_bd("   🔄 Iniciando recuperación automática...")
            self._recuperar_password_automatico()
        elif resultado["opcion"] == "reinstalar":
            self._log_bd("   🔄 Iniciando reinstalación de PostgreSQL...")
            self._instalar_postgresql_accion()
        else:
            self._log_bd("❌ Operación cancelada")
            self.btn_inicializar_bd.configure(state="normal", text="🔄 INICIALIZAR BASE DE DATOS")
    
    def _recuperar_password_automatico(self):
        """Intenta recuperar la contraseña automáticamente."""
        from db_config import inicializar_base_datos
        
        self.btn_inicializar_bd.configure(state="disabled", text="⏳ RECUPERANDO...")
        
        def tarea():
            try:
                ok = inicializar_base_datos()
                def resultado():
                    if ok:
                        self._log_bd("\n✅ ¡Recuperación exitosa! Sistema listo.")
                        self._habilitar_sistema()
                    else:
                        self._log_bd("❌ Recuperación falló")
                        self.btn_inicializar_bd.configure(state="normal", text="🔄 INICIALIZAR BASE DE DATOS")
                self.after(0, resultado)
            except Exception as e:
                def error():
                    self._log_bd("❌ Error en recuperación: %s" % e)
                    self.btn_inicializar_bd.configure(state="normal", text="🔄 INICIALIZAR BASE DE DATOS")
                self.after(0, error)
        
        threading.Thread(target=tarea, daemon=True).start()

    def _instalar_postgresql_accion(self):
        """Acción del botón instalar PostgreSQL."""
        if not _instalador_disponible:
            messagebox.showerror(
                "Error",
                "El módulo de instalación no está disponible.\n"
                "Verifique que el archivo scripts_python/instalacion/instalar_postgresql.py exista."
            )
            return

        confirmacion = messagebox.askyesno(
            "Confirmar instalación",
            "Se descargará e instalará PostgreSQL 17 automáticamente.\n\n"
            "⏳ El proceso puede tardar de 2 a 5 minutos.\n"
            "🔒 Se configurará la contraseña del usuario 'postgres' como: ivan\n\n"
            "¿Desea continuar?"
        )

        if not confirmacion:
            return

        self.btn_instalar_pg.configure(state="disabled", text="⏳ INSTALANDO... (no cierre la ventana)")
        self.progress_bar.pack(fill="x", padx=30, pady=(0, 5))
        self.lbl_progreso_instalacion.configure(text="Iniciando descarga...")

        def tarea():
            def progreso_callback(mensaje: str, porcentaje: float = None):
                def actualizar():
                    self.lbl_progreso_instalacion.configure(text=mensaje)
                    if porcentaje is not None:
                        self.progress_bar.set(porcentaje)
                self.after(0, actualizar)

            exito, resultado = instalar_postgresql_automatico(progreso_callback)

            def actualizar_resultado():
                if exito:
                    self.lbl_progreso_instalacion.configure(
                        text="✅ ¡PostgreSQL instalado! Detectando estado...",
                        text_color="#2ECC71"
                    )
                    self.progress_bar.set(1.0)
                    self.after(2000, self._detectar_estado_postgresql)
                else:
                    self.btn_instalar_pg.configure(
                        state="normal",
                        text="🔄 REINTENTAR INSTALACIÓN"
                    )
                    self.lbl_progreso_instalacion.configure(
                        text=f"❌ Error: {resultado}",
                        text_color="#E74C3C"
                    )
                    self.progress_bar.pack_forget()

            self.after(0, actualizar_resultado)

        threading.Thread(target=tarea, daemon=True).start()

    def _iniciar_servicio_accion(self):
        """Inicia el servicio de PostgreSQL."""
        self._log_bd("⏳ Iniciando servicio de PostgreSQL...")

        def tarea():
            exito = iniciar_servicio_postgresql()
            if exito:
                esperar_servicio_activo(timeout=60)
                self.after(0, self._detectar_estado_postgresql)
            else:
                self._log_bd("❌ No se pudo iniciar el servicio. Intente reiniciar la PC.")

        threading.Thread(target=tarea, daemon=True).start()

    def _inicializar_bd_automatico(self):
        """Crea la base de datos y esquema."""
        if self.btn_inicializar_bd.cget("state") == "disabled":
            return

        self.btn_inicializar_bd.configure(state="disabled", text="...PROCESANDO...")

        def restaurar_boton():
            self.btn_inicializar_bd.configure(state="normal", text="🔄 INICIALIZAR BASE DE DATOS")

        def ejecutar_creacion(password_base: str):
            def tarea_creacion():
                cfg_actual = get_db_config()
                try:
                    puerto_cfg = int(cfg_actual.port)
                except Exception:
                    puerto_cfg = 5432

                exito, mensaje, password_final = crear_base_datos_y_esquema(
                    host=cfg_actual.host or "localhost",
                    puerto=puerto_cfg,
                    usuario=cfg_actual.user or "postgres",
                    contrasena=password_base or cfg_actual.password or PASSWORD_POSTGRES,
                    base_datos=cfg_actual.database or "ivan_proceso_his",
                    esquema=cfg_actual.schema or "es_ivan",
                )

                def resultado():
                    if exito:
                        if password_final:
                            try:
                                update_db_config(password=password_final)
                            except Exception:
                                pass
                        self._log_bd("BD lista!")
                        self._habilitar_sistema()
                    else:
                        self._log_bd("Error: " + mensaje)
                        restaurar_boton()

                self.after(0, resultado)

            threading.Thread(target=tarea_creacion, daemon=True).start()

        def tarea():
            import psycopg2

            cfg = get_db_config()
            try:
                puerto_cfg = int(cfg.port)
            except Exception:
                puerto_cfg = 5432

            password_inicial = cfg.password or PASSWORD_POSTGRES

            try:
                conn = psycopg2.connect(
                    host=cfg.host,
                    port=puerto_cfg,
                    user=cfg.user,
                    password=password_inicial,
                    dbname="postgres",
                    connect_timeout=10,
                )
                conn.close()
                self.after(0, lambda: ejecutar_creacion(password_inicial))
                return
            except Exception:
                pass

            def pedir():
                password = self._pedir_password_dialogo()
                if not password:
                    restaurar_boton()
                    return

                update_db_config(password=password)

                def validar_password():
                    try:
                        conn2 = psycopg2.connect(
                            host=cfg.host,
                            port=puerto_cfg,
                            user=cfg.user,
                            password=password,
                            dbname="postgres",
                            connect_timeout=10,
                        )
                        conn2.close()
                    except Exception as e:
                        self._log_bd("Error: " + str(e))
                        self.after(0, self._ofrecer_opciones_recuperacion)
                        return

                    self.after(0, lambda: ejecutar_creacion(password))

                threading.Thread(target=validar_password, daemon=True).start()

            self.after(0, pedir)

        threading.Thread(target=tarea, daemon=True).start()

    def _habilitar_sistema(self):
        """Habilita el sistema después de una verificación exitosa."""
        dialogo_password = getattr(self, "_dialogo_password", None)
        if dialogo_password is not None:
            try:
                dialogo_password.grab_release()
            except Exception:
                pass
            try:
                if dialogo_password.winfo_exists():
                    dialogo_password.destroy()
            except Exception:
                pass
            self._dialogo_password = None

        self.btn_inicializar_bd.configure(state="normal", text="🔄 INICIALIZAR BASE DE DATOS")
        self.requisitos_bd_ok = True
        self.lbl_estado_acceso.configure(
            text="🔓 Sistema habilitado", text_color="#2ECC71"
        )
        self.btn_nav_bd.configure(fg_color="#1A5C2E")
        self._aplicar_restricciones_acceso()
        self.log_mensaje("✅ Sistema listo para usar. Accede a los módulos del menú superior.")

    def _verificar_y_habilitar(self):
        """Verifica BD/esquema y habilita el sistema."""
        self._log_bd("Iniciando...")
        self.requisitos_bd_ok = False
        self.lbl_estado_acceso.configure(text="...verificando", text_color="gray")
        self.btn_nav_bd.configure(fg_color="#7F8C8D")
        
        def tarea():
            import psycopg2
            try:
                cfg = get_db_config()
                conn = psycopg2.connect(
                    host=cfg.host, port=int(cfg.port),
                    user=cfg.user, password=cfg.password,
                    dbname=cfg.database, connect_timeout=5
                )
                conn.close()
                self.after(0, self._habilitar_sistema)
                return
            except:
                pass
            
            # No funciona, pedir password
            def pedir():
                password = self._pedir_password_dialogo()
                if not password:
                    self._log_bd("Operacion cancelada")
                    self.lbl_estado_acceso.configure(text="INGRESA PASS", text_color="orange")
                    return
                
                update_db_config(password=password)
                self._verificar_y_habilitar()
            
            self.after(0, pedir)

        threading.Thread(target=tarea, daemon=True).start()

    def _acceso_habilitado(self) -> bool:
        return self.requisitos_bd_ok

    def _aplicar_restricciones_acceso(self):
        habilitado = self._acceso_habilitado()
        estado_modulos = "normal" if habilitado else "disabled"

        for boton in (self.btn_nav_ingesta, self.btn_nav_reportes, self.btn_nav_maestros):
            boton.configure(state=estado_modulos)

        if habilitado:
            self.lbl_estado_acceso.configure(text="🔓 Sistema habilitado", text_color="#2ECC71")
        else:
            self.lbl_estado_acceso.configure(text="🔒 Acceso restringido", text_color="orange")

    # ══════════════════════════════════════════════════════════════════════════
    # MÓDULO: INGESTA Y MANTENIMIENTO
    # ══════════════════════════════════════════════════════════════════════════
    def _construir_modulo_ingesta(self):
        self.frame_lateral = ctk.CTkFrame(self.contenedor_ingesta, width=260, corner_radius=0)
        self.frame_lateral.grid(row=0, column=0, sticky="nsew")

        self.scroll_lateral = ctk.CTkScrollableFrame(self.frame_lateral, width=240)
        self.scroll_lateral.pack(fill="both", expand=True)

        ctk.CTkLabel(
            self.scroll_lateral, text="📊 ETL Salud Cusco",
            font=ctk.CTkFont(size=18, weight="bold")
        ).pack(pady=(16, 16))

        # ── Rutas ────────────────────────────────────────────────────────────
        ctk.CTkLabel(
            self.scroll_lateral, text="RUTAS DE ARCHIVOS",
            font=ctk.CTkFont(size=11, weight="bold"), text_color="#E67E22"
        ).pack(pady=(8, 4))

        self.lbl_ruta_crudos = ctk.CTkLabel(
            self.scroll_lateral, text="📁 Atenciones: automática",
            text_color="gray", font=ctk.CTkFont(size=10),
            wraplength=220, justify="left"
        )
        self.lbl_ruta_crudos.pack(padx=10, pady=(0, 2), anchor="w")

        ctk.CTkButton(
            self.scroll_lateral, text="📂 Seleccionar carpeta atenciones",
            height=30, fg_color="#5D4037", hover_color="#4E342E",
            command=self.seleccionar_carpeta_crudos
        ).pack(padx=14, pady=2, fill="x")

        ctk.CTkButton(
            self.scroll_lateral, text="↺ Usar ruta automática",
            height=26, fg_color="#424242", hover_color="#333333",
            command=self.limpiar_ruta_crudos
        ).pack(padx=14, pady=(0, 6), fill="x")



        ctk.CTkLabel(
            self.scroll_lateral, text="Año:",
            font=ctk.CTkFont(size=10), anchor="w"
        ).pack(padx=14, pady=(8, 0), fill="x")

        self.combo_anio = ctk.CTkComboBox(
            self.scroll_lateral,
            values=["2021", "2022", "2023", "2024", "2025", "2026"]
        )
        self.combo_anio.pack(padx=14, pady=2, fill="x")
        self.combo_anio.set("2024")

        ctk.CTkLabel(
            self.scroll_lateral, text="Meses:",
            font=ctk.CTkFont(size=10), anchor="w"
        ).pack(padx=14, pady=(4, 0), fill="x")

        self.btn_meses = ctk.CTkButton(
            self.scroll_lateral, text="Todos los meses",
            fg_color="#2d2d2d", hover_color="#3d3d3d",
            command=self._mostrar_menu_meses
        )
        self.btn_meses.pack(padx=14, pady=2, fill="x")
        self._crear_menu_meses()
        self._actualizar_btn_meses()

        ctk.CTkButton(
            self.scroll_lateral, text="📊 Importar HIS",
            fg_color="#1f538d", hover_color="#14375e",
            command=self.ejecutar_carga_inteligente
        ).pack(padx=14, pady=(8, 12), fill="x")

        ctk.CTkButton(
            self.scroll_lateral, text="♻️ Refrescar HIS Proceso (Pac/Per)",
            fg_color="#0E6655", hover_color="#0B5345",
            command=self.actualizar_his_proceso_maestros
        ).pack(padx=14, pady=(0, 12), fill="x")

        # ── Separador ──────────────────────────────────────────────────────────
        ctk.CTkFrame(self.scroll_lateral, height=2, fg_color="gray").pack(fill="x", padx=14, pady=8)

        # ── Acceso Rápido a Reportes ───────────────────────────────────────────
        ctk.CTkLabel(
            self.scroll_lateral, text="REPORTES",
            font=ctk.CTkFont(size=11, weight="bold"), text_color="#3498DB"
        ).pack(pady=(4, 4))

        ctk.CTkButton(
            self.scroll_lateral, text="📊 Ver Reportes MINSA",
            fg_color="#3498DB", hover_color="#2980B9",
            command=self.mostrar_modulo_reportes
        ).pack(padx=14, pady=(4, 12), fill="x")

        # ── Mantenimiento (Operaciones Peligrosas) ─────────────────────────────
        ctk.CTkLabel(
            self.scroll_lateral, text="⚠️ MANTENIMIENTO",
            font=ctk.CTkFont(size=11, weight="bold"), text_color="#E74C3C"
        ).pack(pady=(8, 4))

        ctk.CTkButton(
            self.scroll_lateral, text="🗑️ Borrar Mes/Año Selecc.",
            fg_color="#8d1f1f", hover_color="#5e1414",
            command=self.confirmar_borrado_parcial
        ).pack(padx=14, pady=4, fill="x")

        ctk.CTkButton(
            self.scroll_lateral, text="💀 VACIAR TODA LA TABLA",
            fg_color="black", hover_color="#333333",
            command=self.confirmar_borrado_total
        ).pack(padx=14, pady=(4, 16), fill="x")

        # ── Panel principal ───────────────────────────────────────────────────
        self.frame_principal = ctk.CTkFrame(self.contenedor_ingesta, fg_color="transparent")
        self.frame_principal.grid(row=0, column=1, padx=20, pady=20, sticky="nsew")
        self.frame_principal.grid_rowconfigure(1, weight=1)
        self.frame_principal.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(
            self.frame_principal, text="Centro de Control ETL",
            font=ctk.CTkFont(size=24, weight="bold")
        ).grid(row=0, column=0, sticky="w", pady=(0, 10))

        self.tabview = ctk.CTkTabview(self.frame_principal)
        self.tabview.grid(row=1, column=0, sticky="nsew")
        self.tabview.add("Vista de Monitoreo")
        self.tabview.add("Registro de Logs")

        # Pestaña Estado
        tab_dash = self.tabview.tab("Vista de Monitoreo")
        self.frame_status = ctk.CTkFrame(tab_dash, corner_radius=10)
        self.frame_status.pack(fill="x", padx=20, pady=20)

        ctk.CTkLabel(
            self.frame_status, text="Estado:",
            font=ctk.CTkFont(weight="bold")
        ).pack(side="left", padx=15, pady=15)

        self.lbl_estado_valor = ctk.CTkLabel(
            self.frame_status, text="Listo para iniciar", text_color="gray"
        )
        self.lbl_estado_valor.pack(side="left", padx=5, pady=15)

        self.frame_progreso_ingesta = ctk.CTkFrame(tab_dash, corner_radius=10)
        self.frame_progreso_ingesta.pack(fill="x", padx=20, pady=(0, 12))

        self.lbl_progreso_ingesta = ctk.CTkLabel(
            self.frame_progreso_ingesta,
            text="Progreso de ingesta: esperando ejecución",
            anchor="w",
        )
        self.lbl_progreso_ingesta.pack(fill="x", padx=14, pady=(10, 4))

        self.barra_progreso_ingesta = ctk.CTkProgressBar(self.frame_progreso_ingesta, height=10)
        self.barra_progreso_ingesta.pack(fill="x", padx=14, pady=4)
        self.barra_progreso_ingesta.set(0)

        self.lbl_eta_ingesta = ctk.CTkLabel(
            self.frame_progreso_ingesta,
            text="ETA: --:--",
            text_color="gray",
            anchor="w",
        )
        self.lbl_eta_ingesta.pack(fill="x", padx=14, pady=(2, 10))

        self.frame_monitor = ctk.CTkFrame(tab_dash, fg_color=("gray85", "gray15"))
        self.frame_monitor.pack(fill="both", expand=True, padx=20, pady=(0, 20))

        ctk.CTkLabel(
            self.frame_monitor,
            text="Seleccione una operación en el menú lateral\npara comenzar el procesamiento de datos."
        ).place(relx=0.5, rely=0.5, anchor="center")

        # Pestaña Logs
        tab_logs = self.tabview.tab("Registro de Logs")
        self.consola_texto = ctk.CTkTextbox(tab_logs, font=("Consolas", 12))
        self.consola_texto.pack(fill="both", expand=True, padx=10, pady=10)
        self.consola_texto.configure(state="disabled")

    # ══════════════════════════════════════════════════════════════════════════
    # MÓDULO: ANÁLISIS Y REPORTES
    # ══════════════════════════════════════════════════════════════════════════
    def _construir_modulo_reportes(self):
        self.rep_lateral = ctk.CTkScrollableFrame(self.contenedor_reportes, width=260)
        self.rep_lateral.pack(side="left", fill="y", padx=10, pady=10)

        ctk.CTkLabel(
            self.rep_lateral, text="📊 Análisis y Reportes",
            font=ctk.CTkFont(size=16, weight="bold")
        ).pack(pady=(20, 10))

        ctk.CTkLabel(
            self.rep_lateral, text="Año:",
            font=ctk.CTkFont(size=12)
        ).pack(pady=(0, 5))

        self.cb_anio_tablas = ctk.CTkOptionMenu(
            self.rep_lateral,
            values=["2021", "2022", "2023", "2024", "2025", "2026"],
            width=120
        )
        self.cb_anio_tablas.pack(pady=(0, 10))
        self.cb_anio_tablas.set("2024")

        self.frame_editor_reportes = ctk.CTkFrame(self.rep_lateral, fg_color="transparent")
        self.frame_editor_reportes.grid_columnconfigure(0, weight=1)
        self.frame_editor_reportes.grid_columnconfigure(1, weight=1)

        ctk.CTkButton(
            self.frame_editor_reportes,
            text="📋 Scripts editables",
            fg_color="#34495E",
            hover_color="#2C3E50",
            command=self._abrir_gestor_scripts,
        ).grid(row=0, column=0, padx=(0, 4), sticky="ew")

        ctk.CTkButton(
            self.frame_editor_reportes,
            text="➕ Nuevo SQL",
            fg_color="#117A65",
            hover_color="#0E6655",
            command=self._abrir_dialogo_nuevo_sql,
        ).grid(row=0, column=1, padx=(4, 0), sticky="ew")

        self._actualizar_panel_editor_reportes()

        self.frame_botones_reportes = ctk.CTkFrame(self.rep_lateral, fg_color="transparent")
        self.frame_botones_reportes.pack(fill="x", padx=0, pady=0)
        self._renderizar_botones_reportes()

        self.rep_central = ctk.CTkFrame(self.contenedor_reportes)
        self.rep_central.pack(side="right", fill="both", expand=True, padx=10, pady=10)

        ctk.CTkLabel(
            self.rep_central, text="Visor de Resultados",
            font=ctk.CTkFont(size=18, weight="bold")
        ).pack(pady=(10, 0))

        self.pantalla_resultados = ctk.CTkTextbox(self.rep_central, font=("Consolas", 12))
        self.pantalla_resultados.pack(fill="both", expand=True, padx=10, pady=10)

    def _renderizar_botones_reportes(self):
        if not hasattr(self, "frame_botones_reportes"):
            return

        for widget in self.frame_botones_reportes.winfo_children():
            widget.destroy()

        for section_key, section_title in SECCIONES_REPORTE:
            botones = [boton for boton in self.report_buttons_config if boton["section"] == section_key]
            if not botones:
                continue

            ctk.CTkLabel(
                self.frame_botones_reportes,
                text=section_title,
                font=ctk.CTkFont(size=14 if section_key == "reportes" else 16, weight="bold"),
            ).pack(pady=(20 if section_key == "reportes" else 10, 10))

            for boton in botones:
                self._crear_fila_boton_reporte(boton)

    def _crear_fila_boton_reporte(self, boton: dict):
        fila = ctk.CTkFrame(self.frame_botones_reportes, fg_color="transparent")
        fila.pack(fill="x", padx=10, pady=5)
        fila.grid_columnconfigure(0, weight=1)

        ctk.CTkButton(
            fila,
            text=boton["text"],
            fg_color=boton["color"],
            hover_color="#2C3E50",
            command=lambda a=boton["script_path"], n=boton["text"]: self.ejecutar_script_python(a, n),
        ).grid(row=0, column=0, sticky="ew")

        if self.editor_mode_activo:
            self._crear_boton_edicion_reporte(fila, boton)

    def _crear_boton_edicion_reporte(self, fila, boton: dict):
        descriptor = {
            **boton,
            "origin": "Análisis y Reportes",
        }
        acciones = ctk.CTkFrame(fila, fg_color="transparent")
        acciones.grid(row=0, column=1, padx=(6, 0))

        ctk.CTkButton(
            acciones,
            text="✏️",
            width=42,
            fg_color="#34495E",
            hover_color="#2C3E50",
            command=lambda d=descriptor: self._abrir_editor_script(d),
        ).pack(side="left")

        ctk.CTkButton(
            acciones,
            text="🗑️",
            width=42,
            fg_color="#922B21",
            hover_color="#7B241C",
            command=lambda d=descriptor: self._eliminar_boton_reporte(d),
        ).pack(side="left", padx=(4, 0))

    # ══════════════════════════════════════════════════════════════════════════
    # MÓDULO: GESTIÓN DE MAESTROS
    # ══════════════════════════════════════════════════════════════════════════
    def _construir_modulo_maestros(self):
        if _modulo_maestros_disponible:
            self.widget_maestros = ModuloMaestros(
                self.contenedor_maestros,
                log_callback=self.log_mensaje,
                editor_enabled=self.editor_mode_activo,
                edit_script_callback=self._editar_script_maestro,
                execution_start_callback=self._iniciar_ejecucion_global,
                execution_progress_callback=self._actualizar_ejecucion_global,
                execution_finish_callback=self._finalizar_ejecucion_global,
                process_register_callback=self._registrar_proceso_cancelable,
            )
            self.widget_maestros.pack(fill="both", expand=True)
        else:
            ctk.CTkLabel(
                self.contenedor_maestros,
                text="⚠️ modulo_maestros.py no encontrado junto a main.py",
                text_color="orange", font=ctk.CTkFont(size=14)
            ).pack(expand=True)

    # ══════════════════════════════════════════════════════════════════════════
    # NAVEGACIÓN
    # ══════════════════════════════════════════════════════════════════════════
    def _resetear_nav(self):
        for btn in (self.btn_nav_ingesta, self.btn_nav_reportes,
                    self.btn_nav_maestros, self.btn_nav_bd):
            btn.configure(fg_color="transparent")

    def mostrar_modulo_bd(self):
        self._resetear_nav()
        self.btn_nav_bd.configure(fg_color="#2c3e50")
        for c in (self.contenedor_ingesta, self.contenedor_reportes, self.contenedor_maestros):
            c.pack_forget()
        self.contenedor_bd.pack(fill="both", expand=True)

    def mostrar_modulo_ingesta(self):
        if not self._acceso_habilitado():
            self.log_mensaje("🔒 Debes validar PostgreSQL + BD + esquema desde '🗄️ Configurar BD'.")
            self.mostrar_modulo_bd()
            return

        self._resetear_nav()
        self.btn_nav_ingesta.configure(fg_color="#2c3e50")
        for c in (self.contenedor_reportes, self.contenedor_maestros, self.contenedor_bd):
            c.pack_forget()
        self.contenedor_ingesta.pack(fill="both", expand=True)

    def mostrar_modulo_reportes(self):
        if not self._acceso_habilitado():
            self.log_mensaje("🔒 Debes validar PostgreSQL + BD + esquema desde '🗄️ Configurar BD'.")
            self.mostrar_modulo_bd()
            return

        self._resetear_nav()
        self.btn_nav_reportes.configure(fg_color="#2c3e50")
        for c in (self.contenedor_ingesta, self.contenedor_maestros, self.contenedor_bd):
            c.pack_forget()
        self.contenedor_reportes.pack(fill="both", expand=True)

    def mostrar_modulo_maestros(self):
        if not self._acceso_habilitado():
            self.log_mensaje("🔒 Debes validar PostgreSQL + BD + esquema desde '🗄️ Configurar BD'.")
            self.mostrar_modulo_bd()
            return

        self._resetear_nav()
        self.btn_nav_maestros.configure(fg_color="#2c3e50")
        for c in (self.contenedor_ingesta, self.contenedor_reportes, self.contenedor_bd):
            c.pack_forget()
        self.contenedor_maestros.pack(fill="both", expand=True)

    # ══════════════════════════════════════════════════════════════════════════
    # UTILIDADES COMPARTIDAS
    # ══════════════════════════════════════════════════════════════════════════
    def log_mensaje(self, mensaje):
        """Escribe en la consola principal (thread-safe)."""
        def _escribir():
            self.consola_texto.configure(state="normal")
            self.consola_texto.insert("end", mensaje + "\n")
            self.consola_texto.see("end")
            self.consola_texto.configure(state="disabled")
        self.after(0, _escribir)

    def actualizar_status(self, msg, color="white"):
        self.lbl_estado_valor.configure(text=msg, text_color=color)

    def _formatear_duracion(self, segundos: float) -> str:
        total = max(0, int(segundos))
        minutos, segs = divmod(total, 60)
        horas, mins = divmod(minutos, 60)
        if horas > 0:
            return f"{horas:02d}:{mins:02d}:{segs:02d}"
        return f"{mins:02d}:{segs:02d}"

    def _reiniciar_progreso_ingesta(self, nombre_proceso: str):
        def _ui():
            self._ingesta_total = 0
            self._ingesta_completado = 0
            self._ingesta_inicio = time.monotonic()
            self.barra_progreso_ingesta.set(0)
            self.lbl_progreso_ingesta.configure(
                text=f"Progreso de ingesta: {nombre_proceso} (iniciando)",
                text_color="white",
            )
            self.lbl_eta_ingesta.configure(text="ETA: calculando...", text_color="gray")

        self.after(0, _ui)

    def _actualizar_progreso_ingesta(self, completado: int, total: int, estado: str, detalle: str):
        def _ui():
            self._ingesta_total = max(total, 1)
            self._ingesta_completado = max(0, min(completado, self._ingesta_total))
            self.barra_progreso_ingesta.set(self._ingesta_completado / self._ingesta_total)

            texto_estado = "OK" if estado == "ok" else "ERROR"
            self.lbl_progreso_ingesta.configure(
                text=(
                    f"Progreso de ingesta: {self._ingesta_completado}/{self._ingesta_total} "
                    f"({texto_estado}) - {detalle}"
                )
            )

            if self._ingesta_inicio and self._ingesta_completado > 0:
                transcurrido = time.monotonic() - self._ingesta_inicio
                restantes = max(self._ingesta_total - self._ingesta_completado, 0)
                if restantes == 0:
                    self.lbl_eta_ingesta.configure(text=f"ETA: 00:00 | Total: {self._formatear_duracion(transcurrido)}", text_color="gray")
                else:
                    promedio = transcurrido / self._ingesta_completado
                    eta_segundos = promedio * restantes
                    self.lbl_eta_ingesta.configure(
                        text=(
                            f"ETA: {self._formatear_duracion(eta_segundos)} "
                            f"| Transcurrido: {self._formatear_duracion(transcurrido)}"
                        ),
                        text_color="gray",
                    )

        self.after(0, _ui)

    def _finalizar_progreso_ingesta(self, exito: bool):
        def _ui():
            color = "#2ECC71" if exito else "orange"
            estado = "finalizada" if exito else "finalizada con incidencias"
            total = self._ingesta_total or self._ingesta_completado
            if total > 0:
                self.barra_progreso_ingesta.set(self._ingesta_completado / total)
            self.lbl_progreso_ingesta.configure(
                text=(
                    f"Progreso de ingesta: {estado} "
                    f"({self._ingesta_completado}/{total if total else 0})"
                ),
                text_color=color,
            )

            if self._ingesta_inicio:
                transcurrido = time.monotonic() - self._ingesta_inicio
                self.lbl_eta_ingesta.configure(
                    text=f"Duración total: {self._formatear_duracion(transcurrido)}",
                    text_color="gray",
                )

        self.after(0, _ui)

    def _extraer_progreso(self, linea: str) -> dict | None:
        if not linea.startswith("[PROGRESS]"):
            return None

        payload = linea[len("[PROGRESS]"):].strip()
        if payload.startswith("TOTAL="):
            try:
                total = int(payload.split("=", 1)[1])
            except ValueError:
                return {"kind": "invalid"}
            return {
                "kind": "total",
                "completado": 0,
                "total": total,
                "estado": "ok",
                "detalle": "Preparando carga...",
            }

        if payload.startswith("DONE="):
            body = payload.split("=", 1)[1]
            partes = body.split("|")
            avance = partes[0]
            match = re.match(r"^(\d+)/(\d+)$", avance)
            if not match:
                return {"kind": "invalid"}

            completado = int(match.group(1))
            total = int(match.group(2))
            estado = "ok"
            mes = "--"
            archivo = ""

            for parte in partes[1:]:
                if parte.startswith("estado="):
                    estado = parte.split("=", 1)[1].strip().lower()
                elif parte.startswith("mes="):
                    mes = parte.split("=", 1)[1].strip()
                elif parte.startswith("archivo="):
                    archivo = parte.split("=", 1)[1].strip()

            detalle = f"Mes {mes}" if not archivo else f"Mes {mes} - {archivo}"
            return {
                "kind": "done",
                "completado": completado,
                "total": total,
                "estado": estado,
                "detalle": detalle,
            }

        return {"kind": "invalid"}

    def _procesar_linea_progreso_ingesta(self, linea: str, token: int | None = None) -> bool:
        progreso = self._extraer_progreso(linea)
        if progreso is None:
            return False

        if progreso.get("kind") in {"total", "done"}:
            self._actualizar_progreso_ingesta(
                progreso["completado"],
                progreso["total"],
                progreso["estado"],
                progreso["detalle"],
            )
            if token is not None:
                self._actualizar_ejecucion_global(
                    token,
                    progreso["completado"],
                    progreso["total"],
                    progreso["estado"],
                    progreso["detalle"],
                )
        return True

    def ejecutar_tarea(self, ruta_script, nombre_proceso, argumentos=None, mostrar_progreso=False):
        argumentos = list(argumentos) if argumentos else []
        token = self._iniciar_ejecucion_global(nombre_proceso, determinate=False)

        def hilo():
            args = list(argumentos)
            ruta_relativa, ruta_absoluta = normalizar_ruta_script(ruta_script)
            if not os.path.exists(ruta_absoluta):
                self.log_mensaje(f"❌ ERROR: No se encontró {ruta_absoluta}")
                self.actualizar_status("Error: Script no encontrado", "red")
                self._finalizar_ejecucion_global(
                    token,
                    nombre_proceso,
                    False,
                    f"Script no encontrado: {ruta_absoluta}",
                )
                return

            self.actualizar_status(f"Ejecutando {nombre_proceso}...", "yellow")
            self.log_mensaje(f"\n--- INICIO: {nombre_proceso} ---")
            if mostrar_progreso:
                self._reiniciar_progreso_ingesta(nombre_proceso)

            try:
                comando = construir_comando_ejecucion(ruta_relativa, ruta_absoluta) + args
                entorno = os.environ.copy()
                entorno["PYTHONUTF8"] = "1"
                print(f"[DEBUG] Comando: {comando}")
                proceso = subprocess.Popen(
                    comando,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, encoding="utf-8", errors="replace",
                    env=entorno,
                    creationflags=CREATE_NO_WINDOW,
                )
                self._registrar_proceso_cancelable(token, nombre_proceso, proceso)

                if proceso.stdout:
                    for linea in proceso.stdout:
                        linea_limpia = linea.strip()
                        if mostrar_progreso and self._procesar_linea_progreso_ingesta(linea_limpia, token):
                            continue
                        if linea_limpia:
                            self._actualizar_detalle_ejecucion_global(token, linea_limpia)
                        self.log_mensaje(linea_limpia)
                proceso.wait()

                if proceso.returncode == 0:
                    self.actualizar_status(f"✅ {nombre_proceso} Finalizado", "green")
                    detalle_final = f"{nombre_proceso} completado correctamente."
                else:
                    self.actualizar_status(f"⚠️ {nombre_proceso} con advertencias", "orange")
                    detalle_final = f"{nombre_proceso} terminó con errores o advertencias."

                if mostrar_progreso:
                    self._finalizar_progreso_ingesta(proceso.returncode == 0)

                self._finalizar_ejecucion_global(
                    token,
                    nombre_proceso,
                    proceso.returncode == 0,
                    detalle_final,
                )
                self.log_mensaje(f"--- FIN: {nombre_proceso} ---")

            except Exception as e:
                self.log_mensaje(f"❌ Error crítico: {e}")
                self.actualizar_status("Error de ejecución", "red")
                if mostrar_progreso:
                    self._finalizar_progreso_ingesta(False)
                self._finalizar_ejecucion_global(token, nombre_proceso, False, str(e))

        threading.Thread(target=hilo, daemon=True).start()

    # ══════════════════════════════════════════════════════════════════════════
    # BOTONES DE INGESTA
    # ══════════════════════════════════════════════════════════════════════════
    def seleccionar_carpeta_crudos(self):
        ruta = filedialog.askdirectory(title="Seleccionar carpeta de archivos de atenciones")
        if ruta:
            self.ruta_crudos_seleccionada = ruta
            self.lbl_ruta_crudos.configure(
                text=f"📁 Atenciones: .../{os.path.basename(ruta) or ruta}",
                text_color="#2ECC71"
            )
            self.log_mensaje(f"📂 Carpeta de atenciones: {ruta}")

    def limpiar_ruta_crudos(self):
        self.ruta_crudos_seleccionada = None
        self.lbl_ruta_crudos.configure(text="📁 Atenciones: automática", text_color="gray")
        self.log_mensaje("↺ Carpeta de atenciones restablecida.")

    def actualizar_his_proceso_maestros(self):
        anio = self.combo_anio.get().strip()
        meses_seleccionados = self._get_meses_seleccionados()
        maestro_objetivo = "todos"

        if not anio.isdigit():
            self.log_mensaje("❌ Selecciona un año válido para refrescar HIS Proceso.")
            self.actualizar_status("Año inválido", "red")
            return

        if not meses_seleccionados:
            self.log_mensaje("❌ Selecciona al menos un mes.")
            self.actualizar_status("Sin meses", "red")
            return

        if len(meses_seleccionados) == 12:
            mes_arg = "Todos"
        else:
            meses_str = ",".join(str(m) for m in sorted(meses_seleccionados))
            self.log_mensaje(f"⚠️ Múltiples meses no soportados para refresco, usando primero: {meses_str}")
            mes_arg = str(sorted(meses_seleccionados)[0])

        ruta_script = os.path.join("scripts_python", "ingesta", "actualizar_his_proceso_maestros.py")
        argumentos = [anio, mes_arg, maestro_objetivo]
        nombre = f"Refresco HIS Proceso ({maestro_objetivo})"
        self.ejecutar_tarea(ruta_script, nombre, argumentos, mostrar_progreso=True)

    def _crear_menu_meses(self):
        self._menu_ventana = None
        self._meses_estado = {mes: True for mes in range(1, 13)}
        self._meses_estado_backup = self._meses_estado.copy()
        self._todos_seleccionados = True
        self._todos_backup = True

    def _get_meses_seleccionados(self):
        if self._todos_seleccionados:
            return list(range(1, 13))
        return [mes for mes, seleccionado in self._meses_estado.items() if seleccionado]

    def _mostrar_menu_meses(self):
        if self._menu_ventana and self._menu_ventana.winfo_exists():
            return

        self._meses_estado_backup = self._meses_estado.copy()
        self._todos_backup = self._todos_seleccionados

        btn_x = self.btn_meses.winfo_rootx()
        btn_y = self.btn_meses.winfo_rooty() + self.btn_meses.winfo_height()

        self._menu_ventana = ctk.CTkToplevel(self)
        self._menu_ventana.overrideredirect(True)
        self._menu_ventana.attributes("-topmost", True)
        self._menu_ventana.geometry(f"280x380+{btn_x}+{btn_y}")

        frame = ctk.CTkFrame(self._menu_ventana, border_width=2, border_color="#565656")
        frame.pack(fill="both", expand=True)

        self.check_todos = ctk.CTkCheckBox(
            frame,
            text="Todos los meses",
            command=self._on_todos_clicked,
        )
        self.check_todos.pack(padx=12, pady=(10, 6), anchor="w")
        if self._todos_seleccionados:
            self.check_todos.select()
        else:
            self.check_todos.deselect()

        nombres_meses = [
            "Enero", "Febrero", "Marzo", "Abril",
            "Mayo", "Junio", "Julio", "Agosto",
            "Septiembre", "Octubre", "Noviembre", "Diciembre",
        ]

        self.meses_vars = {}
        for mes, nombre in enumerate(nombres_meses, 1):
            cb = ctk.CTkCheckBox(
                frame,
                text=nombre,
                command=lambda m=mes: self._on_mes_seleccionado(m),
            )
            cb.pack(anchor="w", padx=16, pady=1)
            if self._meses_estado.get(mes, False):
                cb.select()
            else:
                cb.deselect()
            self.meses_vars[mes] = cb

        btn_frame = ctk.CTkFrame(frame, fg_color="transparent")
        btn_frame.pack(pady=8, fill="x", padx=12)
        ctk.CTkButton(btn_frame, text="Aceptar", width=90, command=self._aceptar_menu_meses).pack(side="left")
        ctk.CTkButton(btn_frame, text="Cancelar", width=90, command=self._cancelar_menu_meses).pack(side="right")

        self.after(50, lambda: self.bind_all("<Button-1>", self._cerrar_menu_click_exterior))

    def _on_todos_clicked(self):
        activo = bool(self.check_todos.get())
        self._todos_seleccionados = activo
        for mes, cb in self.meses_vars.items():
            if activo:
                cb.select()
            else:
                cb.deselect()
            self._meses_estado[mes] = bool(cb.get())

    def _on_mes_seleccionado(self, mes):
        self._meses_estado[mes] = bool(self.meses_vars[mes].get())
        self._todos_seleccionados = all(self._meses_estado.values())
        if self._todos_seleccionados:
            self.check_todos.select()
        else:
            self.check_todos.deselect()

    def _aceptar_menu_meses(self):
        self._actualizar_btn_meses()
        self._cerrar_menu_meses()

    def _cancelar_menu_meses(self):
        self._meses_estado = self._meses_estado_backup.copy()
        self._todos_seleccionados = self._todos_backup
        self._actualizar_btn_meses()
        self._cerrar_menu_meses()

    def _cerrar_menu_meses(self):
        self.unbind_all("<Button-1>")
        if self._menu_ventana and self._menu_ventana.winfo_exists():
            self._menu_ventana.destroy()
        self._menu_ventana = None

    def _widget_es_hijo_de(self, widget, contenedor):
        while widget is not None:
            if widget == contenedor:
                return True
            try:
                padre = widget.nametowidget(widget.winfo_parent())
            except Exception:
                return False
            if padre == widget:
                return False
            widget = padre
        return False

    def _cerrar_menu_click_exterior(self, event):
        if not self._menu_ventana or not self._menu_ventana.winfo_exists():
            return
        widget = event.widget
        if self._widget_es_hijo_de(widget, self._menu_ventana):
            return
        if self._widget_es_hijo_de(widget, self.btn_meses):
            return
        self._aceptar_menu_meses()

    def _actualizar_btn_meses(self):
        meses = sorted(self._get_meses_seleccionados())
        if not meses:
            texto = "Seleccionar meses"
        elif len(meses) == 12:
            texto = "Todos los meses"
        elif len(meses) == 1:
            texto = f"Mes {meses[0]:02d}"
        else:
            vista = ", ".join(f"{m:02d}" for m in meses[:3])
            sufijo = "..." if len(meses) > 3 else ""
            texto = f"{len(meses)} meses ({vista}{sufijo})"
        self.btn_meses.configure(text=texto)

    def ejecutar_carga_inteligente(self):
        anio = self.combo_anio.get()
        meses_seleccionados = self._get_meses_seleccionados()

        if not meses_seleccionados:
            self.log_mensaje("❌ Selecciona al menos un mes.")
            return

        if len(meses_seleccionados) == 12:
            ruta      = os.path.join("scripts_python", "ingesta", "01cargacvs_universal.py")
            argumentos = [anio]
            if self.ruta_crudos_seleccionada:
                carpeta_anio = os.path.join(self.ruta_crudos_seleccionada, anio)
                argumentos = [anio, carpeta_anio if os.path.exists(carpeta_anio) else self.ruta_crudos_seleccionada]
            self.ejecutar_tarea(ruta, f"Carga HIS Anual {anio}", argumentos, mostrar_progreso=True)
        elif len(meses_seleccionados) == 1:
            mes = meses_seleccionados[0]
            ruta      = os.path.join("scripts_python", "ingesta", "01cargacvs_mensual.py")
            argumentos = [anio, f"{mes:02d}"]
            if self.ruta_crudos_seleccionada:
                carpeta_anio = os.path.join(self.ruta_crudos_seleccionada, anio)
                argumentos = [anio, f"{mes:02d}", carpeta_anio if os.path.exists(carpeta_anio) else self.ruta_crudos_seleccionada]
            self.ejecutar_tarea(ruta, f"Carga HIS {anio} - Mes {mes:02d}", argumentos, mostrar_progreso=True)
        else:
            for mes in sorted(meses_seleccionados):
                ruta      = os.path.join("scripts_python", "ingesta", "01cargacvs_mensual.py")
                argumentos = [anio, f"{mes:02d}"]
                if self.ruta_crudos_seleccionada:
                    carpeta_anio = os.path.join(self.ruta_crudos_seleccionada, anio)
                    argumentos = [anio, f"{mes:02d}", carpeta_anio if os.path.exists(carpeta_anio) else self.ruta_crudos_seleccionada]
                self.ejecutar_tarea(ruta, f"Carga HIS {anio} - Mes {mes:02d}", argumentos, mostrar_progreso=True)

    def confirmar_borrado_parcial(self):
        anio = self.combo_anio.get()
        meses_seleccionados = self._get_meses_seleccionados()
        
        if not meses_seleccionados:
            self.log_mensaje("❌ Selecciona al menos un mes.")
            return

        modo = "anio" if len(meses_seleccionados) == 12 else "mes"
        if modo == "anio":
            pregunta = f"⚠️ ¿Borrar TODO el año {anio}?"
        else:
            meses_str = ", ".join(f"{m:02d}" for m in sorted(meses_seleccionados))
            pregunta = f"¿Borrar los meses {meses_str} del año {anio}?"
        
        if messagebox.askyesno("Confirmar Borrado", pregunta):
            ruta = os.path.join("scripts_python", "mantenimiento", "02_eliminar_datos.py")
            if modo == "anio":
                self.ejecutar_tarea(ruta, "Limpieza ANIO", ["anio", anio, "00"])
            else:
                for mes in sorted(meses_seleccionados):
                    self.ejecutar_tarea(ruta, "Limpieza MES", ["mes", anio, f"{mes:02d}"])

    def confirmar_borrado_total(self):
        if messagebox.askyesno(
            "¡PELIGRO EXTREMO!", "Esto eliminará TODOS los registros.\n\n¿Continuar?"
        ):
            ruta = os.path.join("scripts_python", "mantenimiento", "02_eliminar_datos.py")
            self.ejecutar_tarea(ruta, "Vaciado Total", ["todo", "None", "None"])

    # ══════════════════════════════════════════════════════════════════════════
    # EJECUTAR SCRIPTS (PYTHON O SQL)
    # ══════════════════════════════════════════════════════════════════════════
    def _append_resultado_reporte_linea(self, texto: str):
        self.pantalla_resultados.insert("end", texto + "\n")
        self.pantalla_resultados.see("end")

    def ejecutar_script_python(self, script_path, display_name=None):
        self.pantalla_resultados.delete("1.0", "end")
        self.pantalla_resultados.insert("1.0", f"⏳ Ejecutando...\nPor favor espere...\n\n")
        self.update()

        ruta_rel_script, ruta_script = normalizar_ruta_script(script_path)
        nombre_proceso = display_name or os.path.basename(ruta_script)
        token = self._iniciar_ejecucion_global(nombre_proceso, determinate=False)

        if not os.path.exists(ruta_script):
            self._mostrar_resultado_reporte("", f"Script no encontrado: {ruta_script}")
            self._finalizar_ejecucion_global(token, nombre_proceso, False, f"Script no encontrado: {ruta_script}")
            return

        entorno = os.environ.copy()
        entorno["PYTHONUTF8"] = "1"

        def proceso():
            anio_sel = getattr(self, 'cb_anio_tablas', None)
            anio = anio_sel.get() if anio_sel else "2024"

            try:
                if script_path.lower().endswith(".sql"):
                    with open(ruta_script, 'r', encoding='utf-8', errors='replace') as f:
                        contenido = f.read().strip().upper()

                    if contenido.startswith("CREATE OR REPLACE PROCEDURE") or contenido.startswith("CREATE TABLE") or contenido.startswith("INSERT") or contenido.startswith("DROP TABLE") or "CREATE TABLE" in contenido:
                        ruta_runner_rel, ruta_runner = normalizar_ruta_script(
                            os.path.join("scripts_python", "bi", "04_ejecutor_procedures.py")
                        )
                        comando = construir_comando_ejecucion(ruta_runner_rel, ruta_runner) + [ruta_script, anio]
                    elif contenido.startswith("SELECT") or contenido.startswith("WITH"):
                        ruta_runner_rel, ruta_runner = normalizar_ruta_script(
                            os.path.join("scripts_python", "bi", "04_generador_reportes.py")
                        )
                        comando = construir_comando_ejecucion(ruta_runner_rel, ruta_runner) + [ruta_script, anio, "Todos"]
                    else:
                        ruta_runner_rel, ruta_runner = normalizar_ruta_script(
                            os.path.join("scripts_python", "bi", "04_ejecutor_procedures.py")
                        )
                        comando = construir_comando_ejecucion(ruta_runner_rel, ruta_runner) + [ruta_script, anio]
                else:
                    comando = construir_comando_ejecucion(ruta_rel_script, ruta_script) + [anio]

                proceso = subprocess.Popen(
                    comando,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    env=entorno,
                    cwd=BASE_DIR,
                    creationflags=CREATE_NO_WINDOW,
                )
                self._registrar_proceso_cancelable(token, nombre_proceso, proceso)

                if proceso.stdout:
                    for linea in proceso.stdout:
                        linea_limpia = linea.strip()
                        if not linea_limpia:
                            continue

                        progreso = self._extraer_progreso(linea_limpia)
                        if progreso and progreso.get("kind") in {"total", "done"}:
                            self._actualizar_ejecucion_global(
                                token,
                                progreso["completado"],
                                progreso["total"],
                                progreso["estado"],
                                progreso["detalle"],
                            )
                            continue

                        self._actualizar_detalle_ejecucion_global(token, linea_limpia)
                        self.after(0, lambda t=linea_limpia: self._append_resultado_reporte_linea(t))

                proceso.wait()
                self._finalizar_ejecucion_global(
                    token,
                    nombre_proceso,
                    proceso.returncode == 0,
                    (
                        f"{nombre_proceso} completado correctamente."
                        if proceso.returncode == 0
                        else f"{nombre_proceso} terminó con errores o advertencias."
                    ),
                )
            except Exception as e:
                self.after(0, lambda: self._mostrar_resultado_reporte("", str(e)))
                self._finalizar_ejecucion_global(token, nombre_proceso, False, str(e))

        threading.Thread(target=proceso, daemon=True).start()

    # ══════════════════════════════════════════════════════════════════════════
    # BOTONES DE REPORTES
    # ══════════════════════════════════════════════════════════════════════════
    def ejecutar_reporte(self, script_name):
        self.pantalla_resultados.delete("1.0", "end")
        self.pantalla_resultados.insert(
            "1.0", f"⏳ Ejecutando {script_name}...\nPor favor espere...\n\n"
        )
        self.update()

        ruta_python_rel, ruta_python = normalizar_ruta_script(
            os.path.join("scripts_python", "bi", "04_generador_reportes.py")
        )
        _, ruta_script = normalizar_ruta_script(os.path.join("scripts_sql", "reportes", script_name))
        anio_val    = self.cb_anio_etl.get() if hasattr(self, "cb_anio_etl") else "2024"
        mes_val     = self.cb_mes_etl.get()  if hasattr(self, "cb_mes_etl")  else "Todos"

        if not os.path.exists(ruta_python):
            self._mostrar_resultado_reporte("", f"Script de reporte no encontrado: {ruta_python}")
            return
        if not os.path.exists(ruta_script):
            self._mostrar_resultado_reporte("", f"Archivo SQL no encontrado: {ruta_script}")
            return

        comando_python = construir_comando_ejecucion(ruta_python_rel, ruta_python)

        def proceso_reporte():
            try:
                entorno = os.environ.copy()
                entorno["PYTHONUTF8"] = "1"
                resultado = subprocess.run(
                    comando_python + [ruta_script, anio_val, mes_val],
                    capture_output=True, text=True, encoding="utf-8", errors="replace",
                    env=entorno,
                    creationflags=CREATE_NO_WINDOW,
                )
                self.after(0, lambda: self._mostrar_resultado_reporte(
                    resultado.stdout, resultado.stderr
                ))
            except Exception as e:
                self.after(0, lambda: self._mostrar_resultado_reporte("", str(e)))

        threading.Thread(target=proceso_reporte, daemon=True).start()

    def _mostrar_resultado_reporte(self, salida, error):
        self.pantalla_resultados.insert("end", "\n" + salida)
        if error:
            self.pantalla_resultados.insert("end", "\n[ERRORES]:\n" + error)


def _ejecutar_script_interno(argumentos: list[str]) -> int:
    if not argumentos:
        print("[ERROR] No se especifico el script a ejecutar.")
        return 1

    ruta_relativa = os.path.normpath(argumentos[0])
    ruta_absoluta = os.path.join(BASE_DIR, ruta_relativa)

    if not os.path.exists(ruta_absoluta):
        print(f"[ERROR] Script no encontrado: {ruta_relativa}")
        return 2

    original_cwd = os.getcwd()
    original_argv = sys.argv[:]
    sys.argv = [ruta_absoluta] + argumentos[1:]

    try:
        os.chdir(os.path.dirname(ruta_absoluta))
        runpy.run_path(ruta_absoluta, run_name="__main__")
    except SystemExit as exc:
        codigo = exc.code if isinstance(exc.code, int) else 0
        return codigo
    except Exception as err:
        print(f"[ERROR] Ejecutando {ruta_relativa}: {err}")
        return 3
    finally:
        os.chdir(original_cwd)
        sys.argv = original_argv

    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--run-script":
        codigo = _ejecutar_script_interno(sys.argv[2:])
        sys.exit(codigo)

    app = SistemaSaludApp()
    app.mainloop()
