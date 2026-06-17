"""
modulo_maestros.py
Módulo de gestión de maestros para integrar en main.py.

Proporciona la clase ModuloMaestros que se puede embeber
en cualquier CTkFrame del proyecto.
"""
import threading
import subprocess
import sys
import os
import re
import time
import psycopg2
import customtkinter as ctk
from tkinter import filedialog

CREATE_NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)


BASE_DIR = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)

from db_config import get_db_config


def normalizar_ruta_script(ruta_script: str) -> tuple[str, str]:
    ruta_norm = os.path.normpath(ruta_script)
    ruta_abs = (
        ruta_norm
        if os.path.isabs(ruta_norm)
        else os.path.join(BASE_DIR, ruta_norm)
    )
    ruta_rel = os.path.relpath(ruta_abs, BASE_DIR)
    return ruta_rel, ruta_abs


def construir_comando_ejecucion(ruta_relativa: str, ruta_absoluta: str) -> list[str]:
    if getattr(sys, "frozen", False):
        return [sys.executable, "--run-script", ruta_relativa]
    return [sys.executable, ruta_absoluta]

def get_db():
    """Obtiene la configuración actual de la base de datos."""
    cfg = get_db_config()
    return {
        "user": cfg.user,
        "pass": cfg.password,
        "host": cfg.host,
        "port": cfg.port,
        "db":   cfg.database
    }

def get_esquema():
    """Obtiene el esquema actual."""
    return get_db_config().schema

def conectar():
    """Conecta a la base de datos con la configuración actual."""
    db = get_db()
    return psycopg2.connect(
        dbname=db["db"], user=db["user"],
        password=db["pass"], host=db["host"], port=db["port"]
    )

DESCRIPCION_MAESTROS = {
    "maestro_paciente":              "Paciente (DNI, nombre, fecha nac., género, etnia)",
    "maestro_personal":              "Personal de salud (colegio profesional)",
    "eess2025":                      "Establecimiento (red, microred, provincia, distrito)",
    "maestro_his_establecimiento":   "Establecimientos crudos HIS (fuente para reconstruir eess2025)",
    "maestro_his_cie_cpms":          "Diagnósticos CIE / Procedimientos CPT",
    "maestro_his_etnia":             "Etnias (descripción)",
    "maestro_his_ups":               "Unidades Productoras de Servicios (UPS)",
    "maestro_his_colegio":           "Colegios profesionales",
    "maestro_his_actividad":         "Actividades HIS",
    "maestro_his_centro_poblado":    "Centros poblados",
    "maestro_his_condicion_contrato":"Condición de contrato del personal",
    "maestro_his_dosis":             "Dosis de vacunas",
    "maestro_his_financiador":       "Financiadores (SIS, ESSALUD, etc.)",
    "maestro_his_gruporiesgo_lab":   "Grupos de riesgo (lab)",
    "maestro_his_institucion_edu":   "Instituciones educativas",
    "maestro_his_lab":               "Laboratorio (parámetros)",
    "maestro_his_otra_condicion":    "Otra condición clínica",
    "maestro_his_pais":              "Países (código y nombre)",
    "maestro_his_profesion":         "Profesiones del personal",
    "maestro_his_sistema":           "Sistemas de salud",
    "maestro_his_tipo_doc":          "Tipos de documento de identidad",
    "maestro_his_ubigeo":            "Ubigeos INEI / RENIEC",
    "maestro_his_susalud":           "SUSALUD (establecimientos supervisados)",
    "maestro_eess_susalud":          "SUSALUD crudo (fuente para reconstruir eess2025)",
}

MAESTROS_SOPORTADOS = {
    "maestro_his_cie_cpms",
    "maestro_paciente",
    "maestro_personal",
    "maestro_his_ups",
    "eess2025",
}

MAESTROS_CADENA = {
    "maestro_his_etnia",
    "maestro_his_colegio",
}


def obtener_tablas_en_bd() -> list[str]:
    """Devuelve todas las tablas del esquema es_ivan que parecen maestros."""
    try:
        esquema = get_esquema()
        conn = conectar()
        cur  = conn.cursor()
        cur.execute(f"""
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = '{esquema}'
              AND table_type = 'BASE TABLE'
              AND (
                  table_name LIKE 'maestro%%'
                  OR table_name = 'eess2025'
                  OR table_name LIKE '%%susalud%%'
              )
            ORDER BY table_name;
        """)
        tablas = [row[0] for row in cur.fetchall()]
        cur.close()
        conn.close()
        return tablas
    except Exception:
        return []


def eliminar_tabla_maestra(nombre_tabla: str) -> tuple[bool, str]:
    """Elimina una tabla maestra de la base de datos."""
    try:
        esquema = get_esquema()
        conn = conectar()
        cur = conn.cursor()
        cur.execute(f'DROP TABLE IF EXISTS "{esquema}"."{nombre_tabla}" CASCADE;')
        conn.commit()
        cur.close()
        conn.close()
        return True, f"Tabla {nombre_tabla} eliminada correctamente."
    except Exception as e:
        return False, f"Error al eliminar {nombre_tabla}: {e}"


def eliminar_todas_las_maestras() -> tuple[bool, str]:
    """Elimina todas las tablas maestras de la base de datos."""
    try:
        tablas = obtener_tablas_en_bd()
        if not tablas:
            return False, "No hay tablas maestras para eliminar."

        esquema = get_esquema()
        conn = conectar()
        cur = conn.cursor()

        for tabla in tablas:
            cur.execute(f'DROP TABLE IF EXISTS "{esquema}"."{tabla}" CASCADE;')

        conn.commit()
        cur.close()
        conn.close()
        return True, f"Se eliminaron {len(tablas)} tablas maestras."
    except Exception as e:
        return False, f"Error al eliminar maestros: {e}"


class ModuloMaestros(ctk.CTkFrame):
    """
    Frame reutilizable con:
    - Selector de carpeta de maestros
    - Lista de CSV disponibles para cargar
    - Vista de maestros cargados en BD (informativa)
    - Botones para generar/refrescar his_proceso
    - Función para eliminar tablas maestras
    """

    def __init__(
        self,
        parent,
        log_callback=None,
        editor_enabled=False,
        edit_script_callback=None,
        execution_start_callback=None,
        execution_progress_callback=None,
        execution_finish_callback=None,
        process_register_callback=None,
        **kwargs,
    ):
        super().__init__(parent, fg_color="transparent", **kwargs)

        self.log_callback          = log_callback or print
        self.editor_enabled        = bool(editor_enabled)
        self.edit_script_callback  = edit_script_callback
        self.execution_start_callback = execution_start_callback
        self.execution_progress_callback = execution_progress_callback
        self.execution_finish_callback = execution_finish_callback
        self.process_register_callback = process_register_callback
        self.ruta_maestros         = None
        self.checks_csv            = {}
        self.var_checks_csv        = {}
        self._progreso_total       = 0
        self._progreso_completado  = 0
        self._progreso_inicio      = None
        self._maestros_csv_disponibles = []
        self._maestros_csv_estado = {}
        self._maestros_csv_estado_backup = {}
        self._todos_maestros_csv = True
        self._todos_maestros_csv_backup = True
        self._menu_maestros_csv = None
        self._execution_token_actual = None

        self._construir_ui()

    def _formatear_duracion(self, segundos: float) -> str:
        total = max(0, int(segundos))
        minutos, segs = divmod(total, 60)
        horas, mins = divmod(minutos, 60)
        if horas > 0:
            return f"{horas:02d}:{mins:02d}:{segs:02d}"
        return f"{mins:02d}:{segs:02d}"

    def _reiniciar_progreso(self, nombre_proceso: str):
        def _ui():
            self._progreso_total = 0
            self._progreso_completado = 0
            self._progreso_inicio = time.monotonic()
            self.barra_progreso_tarea.set(0)
            self.lbl_progreso_tarea.configure(
                text=f"Progreso: {nombre_proceso} (iniciando)",
                text_color="white",
            )
            self.lbl_eta_tarea.configure(text="ETA: calculando...", text_color="gray")

        self.after(0, _ui)

    def _actualizar_progreso(self, completado: int, total: int, estado: str, detalle: str):
        def _ui():
            self._progreso_total = max(total, 1)
            self._progreso_completado = max(0, min(completado, self._progreso_total))
            self.barra_progreso_tarea.set(self._progreso_completado / self._progreso_total)

            texto_estado = "OK" if estado == "ok" else "ERROR"
            self.lbl_progreso_tarea.configure(
                text=(
                    f"Progreso: {self._progreso_completado}/{self._progreso_total} "
                    f"({texto_estado}) - {detalle}"
                )
            )

            if self._progreso_inicio and self._progreso_completado > 0:
                transcurrido = time.monotonic() - self._progreso_inicio
                restantes = max(self._progreso_total - self._progreso_completado, 0)
                if restantes == 0:
                    self.lbl_eta_tarea.configure(
                        text=f"ETA: 00:00 | Total: {self._formatear_duracion(transcurrido)}",
                        text_color="gray",
                    )
                else:
                    promedio = transcurrido / self._progreso_completado
                    eta_segundos = promedio * restantes
                    self.lbl_eta_tarea.configure(
                        text=(
                            f"ETA: {self._formatear_duracion(eta_segundos)} "
                            f"| Transcurrido: {self._formatear_duracion(transcurrido)}"
                        ),
                        text_color="gray",
                    )

        self.after(0, _ui)
        if self.execution_progress_callback and self._execution_token_actual is not None:
            self.execution_progress_callback(
                self._execution_token_actual,
                completado,
                total,
                estado,
                detalle,
            )

    def _finalizar_progreso(self, exito: bool):
        def _ui():
            color = "#2ECC71" if exito else "orange"
            estado = "finalizada" if exito else "finalizada con incidencias"
            total = self._progreso_total or self._progreso_completado
            if total > 0:
                self.barra_progreso_tarea.set(self._progreso_completado / total)
            self.lbl_progreso_tarea.configure(
                text=(
                    f"Progreso: {estado} "
                    f"({self._progreso_completado}/{total if total else 0})"
                ),
                text_color=color,
            )

            if self._progreso_inicio:
                transcurrido = time.monotonic() - self._progreso_inicio
                self.lbl_eta_tarea.configure(
                    text=f"Duración total: {self._formatear_duracion(transcurrido)}",
                    text_color="gray",
                )

        self.after(0, _ui)

    def _procesar_linea_progreso(self, linea: str) -> bool:
        if not linea.startswith("[PROGRESS]"):
            return False

        payload = linea[len("[PROGRESS]"):].strip()
        if payload.startswith("TOTAL="):
            try:
                total = int(payload.split("=", 1)[1])
            except ValueError:
                return True
            self._actualizar_progreso(0, total, "ok", "Preparando...")
            return True

        if payload.startswith("DONE="):
            body = payload.split("=", 1)[1]
            partes = body.split("|")
            avance = partes[0]
            match = re.match(r"^(\d+)/(\d+)$", avance)
            if not match:
                return True

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

            if archivo and mes and mes != "--":
                detalle = f"Mes {mes} - {archivo}"
            elif archivo:
                detalle = archivo
            elif mes and mes != "--":
                detalle = f"Mes {mes}"
            else:
                detalle = f"Paso {completado}/{total}"

            self._actualizar_progreso(completado, total, estado, detalle)
            return True

        return True

    def _ejecutar_script_stream(
        self,
        ruta_script: str,
        argumentos=None,
        nombre_proceso: str = "",
        mostrar_progreso: bool = False,
    ) -> int:
        argumentos = list(argumentos) if argumentos else []
        ruta_relativa, ruta_absoluta = normalizar_ruta_script(ruta_script)
        nombre_visible = nombre_proceso or os.path.basename(ruta_script)
        token = None

        if self.execution_start_callback:
            token = self.execution_start_callback(nombre_visible, determinate=False)
            self._execution_token_actual = token

        if not os.path.exists(ruta_absoluta):
            self.log_callback(f"❌ No se encontró el script: {ruta_absoluta}")
            if mostrar_progreso:
                self._finalizar_progreso(False)
            if token is not None and self.execution_finish_callback:
                self.execution_finish_callback(token, nombre_visible, False, f"Script no encontrado: {ruta_absoluta}")
            self._execution_token_actual = None
            return 1

        comando = construir_comando_ejecucion(ruta_relativa, ruta_absoluta) + argumentos
        entorno = os.environ.copy()
        entorno["PYTHONUTF8"] = "1"

        if mostrar_progreso:
            self._reiniciar_progreso(nombre_proceso or os.path.basename(ruta_script))

        try:
            proceso = subprocess.Popen(
                comando,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
                env=entorno,
                creationflags=CREATE_NO_WINDOW,
            )
            if token is not None and self.process_register_callback:
                self.process_register_callback(token, nombre_visible, proceso)

            if proceso.stdout:
                for linea in proceso.stdout:
                    linea_limpia = linea.strip()
                    if not linea_limpia:
                        continue
                    if mostrar_progreso and self._procesar_linea_progreso(linea_limpia):
                        continue
                    if token is not None and self.execution_progress_callback:
                        self.execution_progress_callback(token, 0, 1, "ok", linea_limpia)
                    self.log_callback(f"   {linea_limpia}")

            proceso.wait()
            codigo = proceso.returncode or 0
        except Exception as e:
            self.log_callback(f"❌ Error ejecutando script: {e}")
            codigo = 1

        if mostrar_progreso:
            self._finalizar_progreso(codigo == 0)

        if token is not None and self.execution_finish_callback:
            self.execution_finish_callback(
                token,
                nombre_visible,
                codigo == 0,
                (
                    f"{nombre_visible} completado correctamente."
                    if codigo == 0
                    else f"{nombre_visible} terminó con errores o advertencias."
                ),
            )
        self._execution_token_actual = None

        return codigo

    def _construir_ui(self):
        self.grid_columnconfigure(0, weight=1)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(1, weight=1)

        ctk.CTkLabel(
            self, text="🗂️  Gestión de Maestros",
            font=ctk.CTkFont(size=20, weight="bold")
        ).grid(row=0, column=0, columnspan=2, sticky="w", padx=20, pady=(16, 8))

        frame_izq = ctk.CTkFrame(self, corner_radius=10)
        frame_izq.grid(row=1, column=0, sticky="nsew", padx=(16, 8), pady=(0, 16))
        frame_izq.grid_rowconfigure(3, weight=1)
        frame_izq.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(
            frame_izq, text="📂  Cargar archivos CSV de maestros",
            font=ctk.CTkFont(size=14, weight="bold")
        ).grid(row=0, column=0, sticky="w", padx=14, pady=(12, 6))

        frame_ruta = ctk.CTkFrame(frame_izq, fg_color="transparent")
        frame_ruta.grid(row=1, column=0, sticky="ew", padx=14, pady=4)
        frame_ruta.grid_columnconfigure(0, weight=1)

        self.lbl_ruta = ctk.CTkLabel(
            frame_ruta, text="Ninguna carpeta seleccionada",
            text_color="gray", font=ctk.CTkFont(size=11),
            wraplength=300, justify="left"
        )
        self.lbl_ruta.grid(row=0, column=0, sticky="w")

        ctk.CTkButton(
            frame_ruta, text="📂 Seleccionar carpeta",
            height=32, command=self._seleccionar_carpeta
        ).grid(row=1, column=0, sticky="ew", pady=(4, 0))

        ctk.CTkLabel(
            frame_izq, text="Archivos encontrados:",
            font=ctk.CTkFont(size=12), text_color="gray"
        ).grid(row=2, column=0, sticky="w", padx=14, pady=(10, 2))

        self.scroll_csv = ctk.CTkScrollableFrame(frame_izq, height=200)
        self.scroll_csv.grid(row=3, column=0, sticky="nsew", padx=10, pady=(0, 8))
        self.scroll_csv.grid_columnconfigure(0, weight=1)

        self.lbl_sin_csv = ctk.CTkLabel(
            self.scroll_csv, text="(selecciona una carpeta)",
            text_color="gray"
        )
        self.lbl_sin_csv.pack(pady=20)

        frame_btns_csv = ctk.CTkFrame(frame_izq, fg_color="transparent")
        frame_btns_csv.grid(row=4, column=0, sticky="ew", padx=10, pady=(0, 12))
        frame_btns_csv.grid_columnconfigure(0, weight=1)
        frame_btns_csv.grid_columnconfigure(1, weight=1)

        ctk.CTkButton(
            frame_btns_csv, text="☑ Selec. todos",
            height=30, fg_color="#2c3e50",
            command=self._seleccionar_todos_csv
        ).grid(row=0, column=0, padx=4, pady=4, sticky="ew")

        ctk.CTkButton(
            frame_btns_csv, text="🚀 Cargar seleccionados",
            height=30, fg_color="#1f538d", hover_color="#14375e",
            command=self._cargar_csv_seleccionados
        ).grid(row=0, column=1, padx=4, pady=4, sticky="ew")

        ctk.CTkLabel(
            frame_btns_csv,
            text="Actualización rápida (crudos):",
            font=ctk.CTkFont(size=11),
            text_color="gray"
        ).grid(row=1, column=0, columnspan=2, sticky="w", padx=4, pady=(8, 2))

        self.btn_maestro_critico_csv = ctk.CTkButton(
            frame_btns_csv,
            text="Todos los maestros",
            width=170,
            fg_color="#34495E",
            hover_color="#2C3E50",
            command=self._mostrar_menu_maestros_csv,
        )
        self.btn_maestro_critico_csv.grid(row=2, column=0, padx=4, pady=4, sticky="ew")

        ctk.CTkButton(
            frame_btns_csv,
            text="🔄 Actualizar maestro",
            height=30,
            fg_color="#2E4053",
            hover_color="#1B2631",
            command=self._actualizar_maestro_critico_desde_csv,
        ).grid(row=2, column=1, padx=4, pady=4, sticky="ew")

        frame_btn_eess = ctk.CTkFrame(frame_btns_csv, fg_color="transparent")
        frame_btn_eess.grid(row=3, column=0, columnspan=2, padx=4, pady=(8, 4), sticky="ew")
        frame_btn_eess.grid_columnconfigure(0, weight=1)

        ctk.CTkButton(
            frame_btn_eess,
            text="🏥 Procesar EESS principal",
            height=30,
            fg_color="#0E6655",
            hover_color="#0B5345",
            command=self._procesar_eess_principal,
        ).grid(row=0, column=0, sticky="ew")

        self.btn_editar_eess_principal = ctk.CTkButton(
            frame_btn_eess,
            text="✏️",
            width=42,
            fg_color="#34495E",
            hover_color="#2C3E50",
            command=lambda: self._editar_script(
                "Procesar EESS principal",
                os.path.join(
                    "scripts_sql",
                    "scripst tabla y reportes vacunas-cred",
                    "EESS_PRINCIPAL_2026     moshe.sql",
                ),
            ),
        )
        self.btn_editar_eess_principal.grid(row=0, column=1, padx=(6, 0))

        frame_der = ctk.CTkFrame(self, corner_radius=10)
        frame_der.grid(row=1, column=1, sticky="nsew", padx=(8, 16), pady=(0, 16))
        frame_der.grid_rowconfigure(2, weight=1)
        frame_der.grid_columnconfigure(0, weight=1)

        encabezado = ctk.CTkFrame(frame_der, fg_color="transparent")
        encabezado.grid(row=0, column=0, sticky="ew", padx=14, pady=(12, 6))
        encabezado.grid_columnconfigure(0, weight=1)

        ctk.CTkLabel(
            encabezado, text="🔗  Maestros en PostgreSQL",
            font=ctk.CTkFont(size=14, weight="bold")
        ).grid(row=0, column=0, sticky="w")

        ctk.CTkButton(
            encabezado, text="🔄 Actualizar lista",
            height=28, width=140,
            command=self._actualizar_ambos
        ).grid(row=0, column=1, padx=(8, 0))

        ctk.CTkLabel(
            frame_der,
            text="Maestros detectados en BD:",
            font=ctk.CTkFont(size=11), text_color="gray"
        ).grid(row=1, column=0, sticky="w", padx=14, pady=(0, 4))

        self.scroll_bd = ctk.CTkScrollableFrame(frame_der, height=220)
        self.scroll_bd.grid(row=2, column=0, sticky="nsew", padx=10, pady=(0, 8))
        self.scroll_bd.grid_columnconfigure(0, weight=1)

        self.lbl_sin_maestros = ctk.CTkLabel(
            self.scroll_bd,
            text="No se detectaron maestros\nen la base de datos.\nPresiona 'Actualizar lista'.",
            text_color="gray"
        )
        self.lbl_sin_maestros.pack(pady=20)

        frame_gen = ctk.CTkFrame(frame_der, fg_color="transparent")
        frame_gen.grid(row=3, column=0, sticky="ew", padx=10, pady=(0, 12))
        frame_gen.grid_columnconfigure(0, weight=1)
        frame_gen.grid_columnconfigure(1, weight=1)

        ctk.CTkLabel(
            frame_gen,
            text="Generar HIS Proceso:",
            font=ctk.CTkFont(size=11, weight="bold"),
            text_color="#3498DB"
        ).grid(row=0, column=0, columnspan=2, sticky="w", padx=4, pady=(2, 4))

        frame_btn_his = ctk.CTkFrame(frame_gen, fg_color="transparent")
        frame_btn_his.grid(row=1, column=0, columnspan=2, padx=4, pady=(2, 4), sticky="ew")
        frame_btn_his.grid_columnconfigure(0, weight=1)

        ctk.CTkButton(
            frame_btn_his,
            text="⚙️  Generar HIS Proceso",
            height=36,
            fg_color="#27AE60",
            hover_color="#1E8449",
            font=ctk.CTkFont(weight="bold"),
            command=self._generar_his_proceso,
        ).grid(row=0, column=0, sticky="ew")

        self.btn_editar_generar_his = ctk.CTkButton(
            frame_btn_his,
            text="✏️",
            width=42,
            fg_color="#34495E",
            hover_color="#2C3E50",
            command=lambda: self._editar_script(
                "Generar HIS Proceso",
                os.path.join("scripts_sql", "reportes", "generar_his_proceso_editor.sql"),
            ),
        )
        self.btn_editar_generar_his.grid(row=0, column=1, padx=(6, 0))

        frame_anio_mes = ctk.CTkFrame(frame_gen, fg_color="transparent")
        frame_anio_mes.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(4, 0))

        ctk.CTkLabel(frame_anio_mes, text="Año:").pack(side="left", padx=(4, 2))
        self.cb_anio = ctk.CTkOptionMenu(
            frame_anio_mes,
            values=["2021", "2022", "2023", "2024", "2025", "2026"],
            width=80
        )
        self.cb_anio.pack(side="left", padx=2)
        self.cb_anio.set("2024")

        ctk.CTkLabel(frame_anio_mes, text="Mes:").pack(side="left", padx=(8, 2))
        self.cb_mes = ctk.CTkOptionMenu(
            frame_anio_mes,
            values=["Todos", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"],
            width=80
        )
        self.cb_mes.pack(side="left", padx=2)
        self.cb_mes.set("Todos")

        frame_refresco = ctk.CTkFrame(frame_gen, fg_color="transparent")
        frame_refresco.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(8, 0))
        frame_refresco.grid_columnconfigure(0, weight=1)
        frame_refresco.grid_columnconfigure(1, weight=1)

        self.cb_refresco_his = ctk.CTkOptionMenu(
            frame_refresco,
            values=["todos", "maestro_paciente", "maestro_personal"],
            width=170
        )
        self.cb_refresco_his.grid(row=0, column=0, padx=(4, 2), pady=4, sticky="ew")
        self.cb_refresco_his.set("todos")

        ctk.CTkButton(
            frame_refresco,
            text="♻️ Actualizar HIS Proceso",
            height=30,
            fg_color="#0E6655",
            hover_color="#0B5345",
            command=self._actualizar_his_proceso_maestros,
        ).grid(row=0, column=1, padx=(2, 4), pady=4, sticky="ew")

        frame_eliminar = ctk.CTkFrame(frame_der, fg_color="transparent")
        frame_eliminar.grid(row=4, column=0, sticky="ew", padx=10, pady=(12, 0))
        frame_eliminar.grid_columnconfigure(0, weight=1)
        frame_eliminar.grid_columnconfigure(1, weight=1)

        ctk.CTkLabel(
            frame_eliminar,
            text="🗑️ Eliminar tablas maestras",
            font=ctk.CTkFont(size=12, weight="bold"),
            text_color="#E74C3C"
        ).grid(row=0, column=0, columnspan=2, sticky="w", pady=(4, 6))

        self.checks_eliminar = {}
        self.var_checks_eliminar = {}

        self.scroll_eliminar = ctk.CTkScrollableFrame(frame_eliminar, height=100)
        self.scroll_eliminar.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(0, 6))

        ctk.CTkButton(
            frame_eliminar,
            text="☑ Selec. todos",
            height=28,
            command=self._seleccionar_todos_eliminar
        ).grid(row=2, column=0, padx=(0, 2), pady=4, sticky="ew")

        ctk.CTkButton(
            frame_eliminar,
            text="🗑️ Eliminar seleccionados",
            height=28,
            fg_color="#C0392B",
            hover_color="#922B21",
            command=self._eliminar_maestros_seleccionados
        ).grid(row=2, column=1, padx=(2, 0), pady=4, sticky="ew")

        ctk.CTkButton(
            frame_eliminar,
            text="⚠️ Eliminar TODOS los maestros",
            height=28,
            fg_color="#92241D",
            hover_color="#6D1810",
            command=self._eliminar_todos_maestros
        ).grid(row=3, column=0, columnspan=2, pady=(4, 0), sticky="ew")

        frame_progreso = ctk.CTkFrame(frame_der, corner_radius=8)
        frame_progreso.grid(row=5, column=0, sticky="ew", padx=10, pady=(10, 12))

        self.lbl_progreso_tarea = ctk.CTkLabel(
            frame_progreso,
            text="Progreso: en espera",
            anchor="w",
            text_color="gray",
            font=ctk.CTkFont(size=11, weight="bold"),
        )
        self.lbl_progreso_tarea.pack(fill="x", padx=12, pady=(8, 3))

        self.barra_progreso_tarea = ctk.CTkProgressBar(frame_progreso, height=9)
        self.barra_progreso_tarea.pack(fill="x", padx=12, pady=3)
        self.barra_progreso_tarea.set(0)

        self.lbl_eta_tarea = ctk.CTkLabel(
            frame_progreso,
            text="ETA: --:--",
            anchor="w",
            text_color="gray",
            font=ctk.CTkFont(size=10),
        )
        self.lbl_eta_tarea.pack(fill="x", padx=12, pady=(2, 8))

        self._actualizar_lista_bd()
        self._actualizar_combo_maestros_csv(silencioso=True)
        self._actualizar_lista_eliminar()
        self._actualizar_controles_editor()

    def set_editor_mode(self, enabled: bool):
        self.editor_enabled = bool(enabled)
        self._actualizar_controles_editor()

    def _editar_script(self, titulo: str, ruta_script: str):
        if not self.edit_script_callback:
            self.log_callback("⚠️ El modo editor no está disponible en este módulo.")
            return
        self.edit_script_callback(titulo, ruta_script)

    def _actualizar_controles_editor(self):
        for boton in (
            getattr(self, "btn_editar_eess_principal", None),
            getattr(self, "btn_editar_generar_his", None),
        ):
            if boton is None:
                continue
            if self.editor_enabled and self.edit_script_callback:
                boton.grid()
            else:
                boton.grid_remove()

    def _seleccionar_carpeta(self):
        ruta = filedialog.askdirectory(title="Seleccionar carpeta de maestros")
        if not ruta:
            return
        self.ruta_maestros = ruta
        nombre_corto = os.path.basename(ruta) or ruta
        self.lbl_ruta.configure(
            text=f"📁 .../{nombre_corto}",
            text_color="#2ECC71"
        )
        self._listar_csvs(ruta)

    def _listar_csvs(self, carpeta: str):
        for w in self.scroll_csv.winfo_children():
            w.destroy()
        self.checks_csv.clear()
        self.var_checks_csv.clear()

        csvs = sorted([f for f in os.listdir(carpeta) if f.lower().endswith(".csv")])

        if not csvs:
            ctk.CTkLabel(self.scroll_csv, text="No hay archivos CSV", text_color="gray").pack()
            return

        for archivo in csvs:
            var = ctk.BooleanVar(value=True)
            self.var_checks_csv[archivo] = var

            fila = ctk.CTkFrame(self.scroll_csv, fg_color="transparent")
            fila.pack(fill="x", padx=4, pady=2)

            ctk.CTkCheckBox(
                fila, text=archivo, variable=var,
                font=ctk.CTkFont(size=11)
            ).pack(side="left")

            self.checks_csv[archivo] = var

    def _seleccionar_todos_csv(self):
        for var in self.var_checks_csv.values():
            var.set(True)

    def _get_maestros_csv_seleccionados(self) -> list[str]:
        if self._todos_maestros_csv:
            return list(self._maestros_csv_disponibles)
        return [
            tabla for tabla, seleccionado in self._maestros_csv_estado.items()
            if seleccionado
        ]

    def _actualizar_btn_maestros_csv(self):
        if not hasattr(self, "btn_maestro_critico_csv"):
            return

        seleccionados = self._get_maestros_csv_seleccionados()
        if not self._maestros_csv_disponibles:
            texto = "Todos los maestros"
        elif not seleccionados:
            texto = "Seleccionar maestros"
        elif self._todos_maestros_csv or len(seleccionados) == len(self._maestros_csv_disponibles):
            texto = "Todos los maestros"
        elif len(seleccionados) == 1:
            texto = seleccionados[0]
        else:
            vista = ", ".join(seleccionados[:2])
            sufijo = "..." if len(seleccionados) > 2 else ""
            texto = f"{len(seleccionados)} maestros ({vista}{sufijo})"

        self.btn_maestro_critico_csv.configure(text=texto)

    def _mostrar_menu_maestros_csv(self):
        if self._menu_maestros_csv and self._menu_maestros_csv.winfo_exists():
            return

        self._maestros_csv_estado_backup = self._maestros_csv_estado.copy()
        self._todos_maestros_csv_backup = self._todos_maestros_csv

        ventana = ctk.CTkToplevel(self)
        ventana.title("Seleccionar maestros")
        ventana.geometry("320x420")
        ventana.transient(self.winfo_toplevel())
        ventana.grab_set()
        self._menu_maestros_csv = ventana

        frame = ctk.CTkFrame(ventana)
        frame.pack(fill="both", expand=True, padx=10, pady=10)

        self.check_todos_maestros_csv = ctk.CTkCheckBox(
            frame,
            text="Todos los maestros",
            command=self._on_todos_maestros_csv_clicked,
        )
        self.check_todos_maestros_csv.pack(anchor="w", padx=12, pady=(12, 6))
        if self._todos_maestros_csv:
            self.check_todos_maestros_csv.select()
        else:
            self.check_todos_maestros_csv.deselect()

        self.maestros_csv_vars = {}
        contenedor = ctk.CTkScrollableFrame(frame, height=260)
        contenedor.pack(fill="both", expand=True, padx=12, pady=6)

        if not self._maestros_csv_disponibles:
            ctk.CTkLabel(
                contenedor,
                text="No hay tablas detectadas aún.\nSi continúas, se cargarán todos los CSV de la carpeta.",
                text_color="gray",
                justify="center",
            ).pack(pady=20)

        for tabla in self._maestros_csv_disponibles:
            var = ctk.BooleanVar(value=self._maestros_csv_estado.get(tabla, True))
            self.maestros_csv_vars[tabla] = var
            ctk.CTkCheckBox(
                contenedor,
                text=tabla,
                variable=var,
                command=lambda t=tabla: self._on_maestro_csv_clicked(t),
            ).pack(anchor="w", padx=8, pady=2)

        botones = ctk.CTkFrame(frame, fg_color="transparent")
        botones.pack(fill="x", padx=12, pady=(8, 12))
        botones.grid_columnconfigure(0, weight=1)
        botones.grid_columnconfigure(1, weight=1)

        ctk.CTkButton(
            botones,
            text="Cancelar",
            fg_color="#566573",
            command=self._cancelar_menu_maestros_csv,
        ).grid(row=0, column=0, padx=(0, 4), sticky="ew")

        ctk.CTkButton(
            botones,
            text="Aceptar",
            command=self._aceptar_menu_maestros_csv,
        ).grid(row=0, column=1, padx=(4, 0), sticky="ew")

        ventana.protocol("WM_DELETE_WINDOW", self._cancelar_menu_maestros_csv)

    def _on_todos_maestros_csv_clicked(self):
        activo = bool(self.check_todos_maestros_csv.get())
        self._todos_maestros_csv = activo
        for tabla, var in self.maestros_csv_vars.items():
            var.set(activo)
            self._maestros_csv_estado[tabla] = activo

    def _on_maestro_csv_clicked(self, tabla: str):
        valor = bool(self.maestros_csv_vars[tabla].get())
        self._maestros_csv_estado[tabla] = valor
        self._todos_maestros_csv = bool(self._maestros_csv_estado) and all(self._maestros_csv_estado.values())
        if self._todos_maestros_csv:
            self.check_todos_maestros_csv.select()
        else:
            self.check_todos_maestros_csv.deselect()

    def _aceptar_menu_maestros_csv(self):
        self._actualizar_btn_maestros_csv()
        self._cerrar_menu_maestros_csv()

    def _cancelar_menu_maestros_csv(self):
        self._maestros_csv_estado = self._maestros_csv_estado_backup.copy()
        self._todos_maestros_csv = self._todos_maestros_csv_backup
        self._actualizar_btn_maestros_csv()
        self._cerrar_menu_maestros_csv()

    def _cerrar_menu_maestros_csv(self):
        if self._menu_maestros_csv and self._menu_maestros_csv.winfo_exists():
            self._menu_maestros_csv.destroy()
        self._menu_maestros_csv = None

    def _actualizar_combo_maestros_csv(self, silencioso=False):
        if not hasattr(self, "btn_maestro_critico_csv"):
            return

        seleccion_previa = set(self._get_maestros_csv_seleccionados())
        todos_previo = self._todos_maestros_csv
        tablas = obtener_tablas_en_bd()
        self._maestros_csv_disponibles = list(tablas)

        if not self._maestros_csv_disponibles:
            self._maestros_csv_estado = {}
            self._todos_maestros_csv = True
        elif todos_previo or not seleccion_previa:
            self._maestros_csv_estado = {tabla: True for tabla in self._maestros_csv_disponibles}
            self._todos_maestros_csv = True
        else:
            self._maestros_csv_estado = {
                tabla: tabla in seleccion_previa for tabla in self._maestros_csv_disponibles
            }
            self._todos_maestros_csv = all(self._maestros_csv_estado.values())

        self._actualizar_btn_maestros_csv()

        if not silencioso:
            self.log_callback(
                f"🔄 Lista de maestros para actualización rápida: {len(self._maestros_csv_disponibles)} tabla(s)."
            )

    def _cargar_csv_seleccionados(self):
        ruta_maestros = self.ruta_maestros
        if not ruta_maestros:
            self.log_callback("⚠️ Primero selecciona una carpeta de maestros.")
            return

        seleccionados = [
            archivo for archivo, var in self.var_checks_csv.items()
            if var.get()
        ]

        if not seleccionados:
            self.log_callback("⚠️ Ningún archivo seleccionado.")
            return

        def tarea():
            self.log_callback(f"\n📄 Cargando {len(seleccionados)} archivo(s) de maestros...")
            codigo = self._ejecutar_script_stream(
                os.path.join("scripts_python", "ingesta", "cargar_maestros.py"),
                [ruta_maestros, "--archivos", *seleccionados],
                nombre_proceso=f"Carga maestros ({len(seleccionados)} archivo(s))",
                mostrar_progreso=True,
            )

            if codigo == 0:
                self.log_callback("\n✅ Carga de maestros finalizada.")
            else:
                self.log_callback("\n❌ La carga de maestros terminó con errores.")

            seleccion_lc = {a.lower() for a in seleccionados}
            if any("maestro_his_establecimiento" in a for a in seleccion_lc) or any("susalud" in a for a in seleccion_lc):
                self.log_callback("ℹ️ Sugerencia: ejecuta '🏥 Procesar EESS principal' para reconstruir eess2025.")
            self.after(500, self._actualizar_lista_bd)

        threading.Thread(target=tarea, daemon=True).start()

    def _procesar_eess_principal(self):
        self.log_callback("\n🏥 Procesando EESS principal (normalización y reconstrucción de eess2025)...")

        def tarea():
            codigo = self._ejecutar_script_stream(
                os.path.join("scripts_python", "ingesta", "procesar_eess_principal.py"),
                [],
                nombre_proceso="Procesar EESS principal",
                mostrar_progreso=False,
            )

            if codigo == 0:
                self.log_callback("✅ EESS principal procesado correctamente.")
                self._actualizar_combo_maestros_csv(silencioso=True)
                self.after(500, self._actualizar_lista_bd)
            else:
                self.log_callback("❌ El procesamiento de EESS principal terminó con errores.")

        threading.Thread(target=tarea, daemon=True).start()

    def _actualizar_maestro_critico_desde_csv(self):
        self._actualizar_combo_maestros_csv(silencioso=True)

        ruta_maestros = self.ruta_maestros
        if not ruta_maestros:
            self.log_callback("⚠️ Primero selecciona una carpeta de maestros.")
            return

        seleccionados = self._get_maestros_csv_seleccionados()
        if not seleccionados and self._maestros_csv_disponibles:
            self.log_callback("⚠️ Selecciona al menos un maestro para actualizar.")
            return

        requiere_eess = "eess2025" in seleccionados
        tablas_csv = [tabla for tabla in seleccionados if tabla != "eess2025"]
        todas_las_tablas_csv = [tabla for tabla in self._maestros_csv_disponibles if tabla != "eess2025"]
        cargar_todos = not self._maestros_csv_disponibles or self._todos_maestros_csv or set(tablas_csv) == set(todas_las_tablas_csv)

        if requiere_eess and not tablas_csv:
            self.log_callback("ℹ️ eess2025 se reconstruye desde maestros base (no desde CSV directo).")
        else:
            resumen = "todos los maestros" if cargar_todos else ", ".join(tablas_csv)
            self.log_callback(f"\n🔄 Actualizando {resumen} desde CSV crudo...")

        def tarea():
            codigo = 0

            if tablas_csv or cargar_todos:
                argumentos = [ruta_maestros]
                if not cargar_todos and tablas_csv:
                    argumentos.extend(["--tablas", *tablas_csv])

                codigo = self._ejecutar_script_stream(
                    os.path.join("scripts_python", "ingesta", "cargar_maestros.py"),
                    argumentos,
                    nombre_proceso=(
                        "Actualizar maestros desde CSV"
                        if cargar_todos
                        else f"Actualizar {len(tablas_csv)} maestro(s)"
                    ),
                    mostrar_progreso=True,
                )

            if codigo == 0 and requiere_eess:
                self.log_callback("ℹ️ Reconstruyendo eess2025 desde maestros base...")
                codigo = self._ejecutar_script_stream(
                    os.path.join("scripts_python", "ingesta", "procesar_eess_principal.py"),
                    [],
                    nombre_proceso="Procesar EESS principal",
                    mostrar_progreso=False,
                )

            if codigo == 0:
                self.log_callback("✅ Actualización rápida completada correctamente.")
                self._actualizar_combo_maestros_csv(silencioso=True)
                self.after(500, self._actualizar_lista_bd)
            else:
                self.log_callback("❌ Falló la actualización rápida de maestros.")

        threading.Thread(target=tarea, daemon=True).start()

    def _actualizar_ambos(self):
        self._actualizar_lista_bd()
        self._actualizar_lista_eliminar()

    def _actualizar_lista_bd(self):
        for w in self.scroll_bd.winfo_children():
            w.destroy()

        tablas = obtener_tablas_en_bd()
        self._actualizar_combo_maestros_csv(silencioso=True)

        if not tablas:
            ctk.CTkLabel(
                self.scroll_bd,
                text="No se detectaron maestros en la BD.\nCarga primero los CSVs.",
                text_color="gray",
            ).pack(pady=20)
            self.log_callback("🔄 No se detectaron maestros cargados en la BD.")
            return

        tablas_set = set(tablas)
        maestros_his_fijo = [
            "maestro_his_cie_cpms",
            "maestro_paciente",
            "maestro_personal",
            "maestro_his_ups",
            "maestro_his_etnia",
            "maestro_his_colegio",
            "eess2025",
            "maestro_his_establecimiento",
        ]

        cargados_his = [t for t in maestros_his_fijo if t in tablas_set]
        otros_cargados = [t for t in tablas if t not in set(maestros_his_fijo)]

        ctk.CTkLabel(
            self.scroll_bd,
            text="✅ Maestros usados por HIS Proceso (cargados)",
            font=ctk.CTkFont(size=11, weight="bold"),
            text_color="#2ECC71",
        ).pack(anchor="w", padx=8, pady=(10, 5))

        if cargados_his:
            for tabla in cargados_his:
                desc = DESCRIPCION_MAESTROS.get(tabla, tabla)

                fila = ctk.CTkFrame(self.scroll_bd, fg_color=("gray90", "gray17"), corner_radius=6)
                fila.pack(fill="x", padx=4, pady=3)
                fila.grid_columnconfigure(0, weight=1)

                ctk.CTkLabel(
                    fila,
                    text=f"{tabla}",
                    font=ctk.CTkFont(size=12, weight="bold"),
                    anchor="w",
                ).grid(row=0, column=0, sticky="w", padx=10, pady=(6, 0))

                ctk.CTkLabel(
                    fila,
                    text=desc,
                    font=ctk.CTkFont(size=10),
                    text_color="gray",
                    anchor="w",
                    wraplength=280,
                    justify="left",
                ).grid(row=1, column=0, sticky="w", padx=10, pady=(0, 6))

                ctk.CTkLabel(
                    fila,
                    text="Cargado",
                    text_color="#2ECC71",
                    font=ctk.CTkFont(size=10, weight="bold"),
                ).grid(row=0, column=1, rowspan=2, padx=10, pady=6)
        else:
            ctk.CTkLabel(
                self.scroll_bd,
                text="No hay maestros del modelo HIS fijo cargados todavía.",
                text_color="gray",
            ).pack(anchor="w", padx=12, pady=(2, 6))

        if otros_cargados:
            ctk.CTkLabel(
                self.scroll_bd,
                text="📚 Otros maestros cargados en la BD",
                font=ctk.CTkFont(size=11, weight="bold"),
                text_color="#5DADE2",
            ).pack(anchor="w", padx=8, pady=(12, 5))

            for tabla in otros_cargados:
                desc = DESCRIPCION_MAESTROS.get(tabla, "Maestro disponible")
                fila = ctk.CTkFrame(self.scroll_bd, fg_color=("gray95", "gray20"), corner_radius=6)
                fila.pack(fill="x", padx=4, pady=3)
                fila.grid_columnconfigure(0, weight=1)

                ctk.CTkLabel(
                    fila,
                    text=tabla,
                    font=ctk.CTkFont(size=11, weight="bold"),
                    anchor="w",
                ).grid(row=0, column=0, sticky="w", padx=10, pady=(5, 0))

                ctk.CTkLabel(
                    fila,
                    text=desc,
                    font=ctk.CTkFont(size=9),
                    text_color="gray",
                    anchor="w",
                    wraplength=280,
                    justify="left",
                ).grid(row=1, column=0, sticky="w", padx=10, pady=(0, 5))

        self.log_callback(
            f"🔄 Maestros cargados: {len(tablas)} | Usados por HIS Proceso: {len(cargados_his)}"
        )

    def _generar_his_proceso(self):
        anio = self.cb_anio.get()
        mes = self.cb_mes.get()

        if not anio.isdigit():
            self.log_callback("❌ Selecciona un año específico (2021-2026), no 'Todos'.")
            return

        self.log_callback(f"\n🚀 Generando HIS Proceso — Año: {anio} | Mes: {mes}")

        def tarea():
            codigo = self._ejecutar_script_stream(
                os.path.join("scripts_python", "ingesta", "generar_his_proceso.py"),
                [anio, mes],
                nombre_proceso=f"Generar HIS Proceso {anio}-{mes}",
                mostrar_progreso=True,
            )

            if codigo == 0:
                self.log_callback("✅ Generación de HIS Proceso completada.")
            else:
                self.log_callback("❌ La generación de HIS Proceso terminó con errores.")

        threading.Thread(target=tarea, daemon=True).start()

    def _actualizar_his_proceso_maestros(self):
        anio = self.cb_anio.get().strip()
        mes = self.cb_mes.get().strip()
        objetivo = self.cb_refresco_his.get().strip()

        if not anio.isdigit():
            self.log_callback("❌ Selecciona un año válido para refrescar HIS Proceso.")
            return

        try:
            mes_arg = "Todos" if mes == "Todos" else str(int(mes))
        except ValueError:
            self.log_callback("❌ Selecciona un mes válido (1-12 o 'Todos').")
            return

        self.log_callback(
            f"\n♻️ Refrescando HIS Proceso — Año: {anio} | Mes: {mes_arg} | Objetivo: {objetivo}"
        )

        def tarea():
            codigo = self._ejecutar_script_stream(
                os.path.join("scripts_python", "ingesta", "actualizar_his_proceso_maestros.py"),
                [anio, mes_arg, objetivo],
                nombre_proceso=f"Refresco HIS Proceso ({objetivo})",
                mostrar_progreso=True,
            )

            if codigo == 0:
                self.log_callback("✅ Refresco de HIS Proceso completado.")
            else:
                self.log_callback("❌ El refresco de HIS Proceso terminó con errores.")

        threading.Thread(target=tarea, daemon=True).start()

    def _actualizar_lista_eliminar(self):
        for w in self.scroll_eliminar.winfo_children():
            w.destroy()
        self.checks_eliminar.clear()
        self.var_checks_eliminar.clear()

        tablas = obtener_tablas_en_bd()
        if not tablas:
            ctk.CTkLabel(
                self.scroll_eliminar,
                text="No hay tablas maestras",
                text_color="gray"
            ).pack(pady=10)
            return

        for tabla in tablas:
            var = ctk.BooleanVar(value=False)
            self.var_checks_eliminar[tabla] = var

            fila = ctk.CTkFrame(self.scroll_eliminar, fg_color="transparent")
            fila.pack(fill="x", padx=2, pady=1)

            ctk.CTkCheckBox(
                fila, text=tabla, variable=var,
                font=ctk.CTkFont(size=10)
            ).pack(side="left")

            self.checks_eliminar[tabla] = var

    def _seleccionar_todos_eliminar(self):
        for var in self.var_checks_eliminar.values():
            var.set(True)

    def _eliminar_maestros_seleccionados(self):
        seleccionados = [
            tabla for tabla, var in self.checks_eliminar.items()
            if var.get()
        ]

        if not seleccionados:
            self.log_callback("⚠️ Selecciona al menos una tabla para eliminar.")
            return

        from tkinter import messagebox
        if not messagebox.askyesno(
            "Confirmar eliminación",
            f"Se eliminará(n):\n{', '.join(seleccionados)}\n\n¿Continuar?"
        ):
            return

        self.log_callback(f"\n🗑️ Eliminando {len(seleccionados)} tabla(s)...")

        def tarea():
            for tabla in seleccionados:
                ok, msg = eliminar_tabla_maestra(tabla)
                self.log_callback(f"   {'✅' if ok else '❌'} {tabla}: {msg}")

            self.log_callback("✅ Eliminación completada.")
            self.after(500, self._actualizar_lista_bd)
            self.after(500, self._actualizar_lista_eliminar)

        threading.Thread(target=tarea, daemon=True).start()

    def _eliminar_todos_maestros(self):
        from tkinter import messagebox
        if not messagebox.askyesno(
            "⚠️ PELIGRO EXTREMO",
            "Se eliminarán TODAS las tablas maestras.\n\n¿Estás seguro?"
        ):
            return

        self.log_callback("\n🗑️ Eliminando TODOS los maestros...")

        def tarea():
            ok, msg = eliminar_todas_las_maestras()
            self.log_callback(f"{'✅' if ok else '❌'} {msg}")
            self.after(500, self._actualizar_lista_bd)
            self.after(500, self._actualizar_lista_eliminar)

        threading.Thread(target=tarea, daemon=True).start()
