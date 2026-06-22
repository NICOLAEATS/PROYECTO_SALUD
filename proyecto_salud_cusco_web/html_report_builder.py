"""HTML Report Builder - Generates CSS-class-based HTML matching reference DIRESA CUSCO style.

Each _sec_*() returns a complete <div> + <table> block using CSS classes
(.section-title, .sub-section-title, .th-dark, .dual-grid, etc.)
"""

# ============================================================
# HELPER FUNCTIONS
# ============================================================
def _esc(v):
    if v is None: return ''
    if isinstance(v, (int, float)): return f'{v:,.0f}'
    s = str(v)
    return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;')

def _fmt(v):
    if v is None: return '0'
    if isinstance(v, (int, float)):
        if v == int(v): return f'{int(v):,}'
        return f'{v:,.1f}'
    s = str(v)
    if s.startswith('#REF!'): return '0'
    return s

def _v(d, k):
    if k is None: return 0
    v = d.get(k, 0)
    if v is None or v == '#REF!': return 0
    if isinstance(v, str):
        try:
            if v.startswith('#'): return 0
            return float(v.replace(',', ''))
        except:
            return 0
    return int(v) if v == int(v) else v

def _num(v):
    n = _v({}, v) if isinstance(v, str) else v
    if n is None or n == '': return '<td class="num">0</td>'
    if isinstance(n, (int, float)):
        if n == 0: return '<td class="zero">0</td>'
        return f'<td class="num">{n:,.0f}</td>'
    return f'<td>{_esc(n)}</td>'

def _td(v, cls=''):
    if v is None or v == '': return f'<td class="{cls}">0</td>'
    if isinstance(v, (int, float)):
        if v == 0: return f'<td class="{cls} zero">0</td>'
        return f'<td class="{cls} num">{v:,.0f}</td>'
    return f'<td class="{cls}">{_esc(v)}</td>'

def _s(d, k):
    """Shortcut: _s(c24, 'C1_col')"""
    return _td(_v(d, k))

def _wrap_tables(html):
    """Wrap each <table> in <div class='table-container'> for horizontal scroll."""
    import re
    return re.sub(r'(<table[\s>])', r'<div class="table-container">\1', html).replace('</table>', '</table></div>')

# ============================================================
# REPORT CSS (inline to avoid parent-style overrides)
# ============================================================
_REPORT_CSS = '''
* { box-sizing: border-box; margin: 0; padding: 0; }
.page { width: 100%; max-width: 1400px; margin: 0 auto; padding: 10px; overflow: auto; }
.header { text-align: center; margin-bottom: 6px; }
.header h2 { font-size: 11px; font-weight: bold; text-transform: uppercase; }
.header h3 { font-size: 10px; font-weight: bold; text-transform: uppercase; }
.header h4 { font-size: 11px; font-weight: bold; text-transform: uppercase; color: #2E75B6; margin-top: 2px; }
.filter-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; font-size: 9px; margin-bottom: 6px; padding: 4px 0; border-top: 1px solid #4472C4; border-bottom: 1px solid #4472C4; }
.filter-row2 { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; font-size: 9px; margin-bottom: 6px; padding: 4px 0; border-bottom: 1px solid #4472C4; }
.filter-cell { display: flex; flex-direction: column; }
.filter-cell label { font-weight: bold; color: #2E75B6; }
.filter-cell span { border-bottom: 1px solid #9DC3E6; }
.section-title { background: #4472C4; color: #fff; font-weight: bold; font-size: 10px; padding: 3px 6px; text-transform: uppercase; margin-bottom: 2px; }
.sub-section-title { background: #D6E4F7; font-weight: bold; font-size: 9px; padding: 2px 6px; margin-bottom: 2px; border-left: 3px solid #4472C4; }
.sub2-title { background: #F2F2F2; font-weight: bold; font-size: 9px; padding: 2px 6px; margin-bottom: 2px; }
.table-container { width: 100%; overflow-x: auto; margin-bottom: 20px; background-color: #fff; }
.table-container table { table-layout: fixed; border-collapse: collapse; width: 100%; min-width: 1300px; font-family: Arial, sans-serif; font-size: 10px; color: #000; }
.table-container th, .table-container td { border: 1px solid #000; padding: 4px 6px; box-sizing: border-box; vertical-align: middle; }
.table-container th.th-dark { background-color: #2E75B6 !important; color: #fff !important; font-weight: bold; text-align: center; }
.table-container th.th-medium { background-color: #BDD7EE !important; color: #000 !important; font-weight: bold; text-align: center; }
.table-container tr.row-sub { background-color: #F2F2F2; }
.table-container tr.row-total { background-color: #2E75B6; color: #fff; font-weight: bold; }
.table-container tr.row-header { background-color: #DDEBF7; font-weight: bold; }
.table-container td:first-child, .table-container td.label-left { text-align: left; white-space: normal !important; font-weight: bold; }
.table-container td:not(:first-child) { text-align: center; white-space: nowrap; }
.table-container td.label-indent { text-align: left; padding-left: 12px; font-size: 8.5px; white-space: normal !important; }
.table-container td.diag-sub { text-align: left; padding-left: 14px; font-size: 8.5px; white-space: normal !important; }
.table-container td.diag { text-align: left; padding-left: 6px; background: #F2F2F2; font-size: 8.5px; }
.table-container td.formula { text-align: left; padding-left: 4px; font-size: 7.5px; color: #595959; font-style: italic; }
.table-container td.nota { font-size: 7.5px; color: #595959; font-style: italic; text-align: left; padding-left: 4px; }
.table-container td.num { font-weight: bold; }
.table-container td.zero { color: #595959; }
.dual-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 6px; }
.note-row td { background: #FFF2CC; font-size: 8px; text-align: left; padding-left: 4px; border: 1px solid #BF9000; }
.th-green { background: #70AD47; color: #fff; }
.th-orange { background: #ED7D31; color: #fff; }
@media print { body { font-size: 8px; } .page { max-width: 100%; padding: 5px; } @page { size: A3 landscape; margin: 10mm; } }
'''

# ============================================================
# HEADER
# ============================================================
def _sec_header(filtros):
    f = filtros or {}
    anio = str(f.get('anio', '2026'))
    html = '''
    <div class="header">
        <h2>DIRECCI\u00d3N REGIONAL DE SALUD CUSCO</h2>
        <h3>DIRECCI\u00d3N DE ESTAD\u00cdSTICA E INFORM\u00c1TICA Y TELECOMUNICACI\u00d3N</h3>
        <h4>INFORME MENSUAL DEL CUIDADO INTEGRAL DEL NI\u00d1O(A)</h4>
    </div>'''
    html += '''
    <div class="filter-row">
        <div class="filter-cell"><label>RED DE SALUD:</label><span>''' + _esc(f.get('red', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MICRO RED:</label><span>''' + _esc(f.get('microred', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>PROVINCIA:</label><span>''' + _esc(f.get('provincia', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>A\u00d1O:</label><span>''' + anio + '''</span></div>
    </div>
    <div class="filter-row2">
        <div class="filter-cell"><label>ESTABLECIMIENTO:</label><span>''' + _esc(f.get('establecimiento', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>DISTRITO:</label><span>''' + _esc(f.get('distrito', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MES INICIO:</label><span>''' + str(f.get('mes_ini', f.get('mes_inicio', '1'))) + '''</span></div>
        <div class="filter-cell"><label>MES FIN:</label><span>''' + str(f.get('mes_fin', f.get('mes_fin', '6'))) + '''</span></div>
        <div class="filter-cell"></div>
    </div>'''
    return html

# ============================================================
# SECTION: CRED CONTROLS
# ============================================================
def _sec_cred_controls(col_names, filas_cred, totales_main):
    html = '<div class="section-title">CONTROL DE CRECIMIENTO Y DESARROLLO DEL NI\u00d1O(A)</div>'
    html += '<div class="sub-section-title">N\u00b0 de Controles de Crecimiento y Desarrollo de 0 a 11 A\u00f1os</div>'
    html += '<table>'
    html += '<colgroup><col style="width:300px"><col style="width:100px">'
    for _ in range(11):
        html += '<col style="width:75px">'
    html += '</colgroup>'
    html += '<thead><tr>'
    html += '<th class="th-dark">GRUPO ETAREO</th>'
    html += '<th class="th-dark">PROGRAMACI\u00d3N</th>'
    ctrl_names = ['1er Ctrl 29-59d','2do Ctrl 60-89d','3er Ctrl 90-119d','4to Ctrl 120-149d',
                  '5to Ctrl 180-209d','6to Ctrl 210-239d','7mo Ctrl 270-299d',
                  '8vo Ctrl','9no Ctrl','10mo Ctrl','11vo Ctrl']
    for cn in ctrl_names:
        html += f'<th class="th-medium">{cn}</th>'
    html += '</tr></thead><tbody>'
    ctrl_keys = ['1ER.CONTROL','2DO.CONTROL','3ER.CONTROL','4TO.CONTROL',
                 '5TO.CONTROL','6TO.CONTROL','7MO.CONTROL','8VO.CONTROL',
                 '9NO.CONTROL','10MO.CONTROL','11VO.CONTROL']
    for ri, fila in enumerate(filas_cred):
        cls = ' class="row-sub"' if ri % 2 == 1 else ''
        html += f'<tr{cls}>'
        html += f'<td class="label-left">{_esc(fila.get("EDADES", ""))}</td>'
        html += '<td></td>'
        for ck in ctrl_keys:
            v = fila.get(ck, 0) or 0
            if v == 0: html += '<td class="zero">0</td>'
            else: html += f'<td class="num">{v:,.0f}</td>'
        html += '</tr>'
    html += '<tr class="row-total"><td>TOTAL</td><td></td>'
    for ck in ctrl_keys:
        v = totales_main.get(ck, 0) or 0
        if v == 0: html += '<td class="zero">0</td>'
        else: html += f'<td class="num">{v:,.0f}</td>'
    html += '</tr></tbody></table>'
    return html

# ============================================================
# SECTION: I. ATENCIÃ“N DEL RECIÃ‰N NACIDO (dual-grid)
# ============================================================
def _sec_atencion_rn(c24, c1, c4):
    html = '<div class="section-title">I. ATENCI\u00d3N DEL RECI\u00c9N NACIDO</div>'
    html += '<div class="dual-grid">'

    # LEFT: A) AtenciÃ³n Inmediata
    html += '<div>'
    html += '<div class="sub2-title">A) Atenci\u00f3n Inmediata</div>'
    html += '<table><thead><tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    left_items = [
        ('Atenci\u00f3n Inmediata', c24, 'C1_atenc_inmediata_rn_sano'),
        ('Corte tard\u00edo del Cord\u00f3n Umbilical', c24, 'C1_corte_cordon_umbilical_cnv'),
        ('Contacto Piel a Piel con la madre', c24, 'C1_contacto_piel_piel'),
        ('Examen f\u00edsico del reci\u00e9n nacido normal', c24, 'C1_examen_fisico_rn_normal'),
        ('Lactancia Materna en la 1\u00aa Hora', c24, 'C1_lactancia_1ra_hora_cnv'),
        ('BCG MENORES A 1m', c24, 'C1_bcg_menores_1m'),
        ('HVB RN', c24, 'C1_hvb_rn'),
    ]
    for i, (label, d, col) in enumerate(left_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # LEFT: B) CondiciÃ³n de Nacimiento
    html += '<div class="sub2-title" style="margin-top:4px;">B) Condici\u00f3n de Nacimiento del Reci\u00e9n Nacido</div>'
    html += '<table><thead><tr><th class="th-dark">DIAGN\u00d3STICOS</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    cond_items = [
        ('Extremadamente bajo peso', c4, 'C4_peso_extremadamente_bajo'),
        ('Muy bajo peso al nacer', c4, 'C4_muy_bajo_peso'),
        ('Bajo peso al nacer', c4, 'C4_bajo_peso'),
        ('Macros\u00f3mico', c4, 'C4_macrosomico'),
        ('Microcefalia', c4, 'C4_microcefalia'),
        ('Reci\u00e9n nacido prematuro', c4, 'C4_prematuro'),
        ('Reci\u00e9n Nacido Normal', c4, 'no_col'),
    ]
    for i, (label, d, col) in enumerate(cond_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # LEFT: B) Resultados del Tamizaje Neonatal
    html += '<div class="sub2-title" style="margin-top:4px;">B) Resultados del Tamizaje Neonatal</div>'
    html += '<table><thead><tr><th class="th-dark">DIAGN\u00d3STICOS</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    tamiz_items = [
        ('Hipotiroidismo Cong\u00e9nito', c4, 'C4_hipotiroidismo_congenito_sin_bocio'),
        ('Fenilcetonuria Cl\u00e1sica', c4, 'C4_fenilcetonuria_clasica'),
        ('Hiperplasia Suprarrenal Cong\u00e9nita', c4, 'C4_hiperplasia_suprarrenal_congenita'),
        ('Tamizaje de Cardiopat\u00eda Cong\u00e9nita', c4, 'C4_cardiopatia_congenita_tipo1'),
        ('Fibrosis Qu\u00edstica, sin otra especificaci\u00f3n', c4, 'C4_fibrosis_quistica_sin_otra_especificacion'),
        ('Catarata Cong\u00e9nita', c4, 'C4_catarata_congenita'),
        ('Cardiopat\u00eda cong\u00e9nita', c4, 'no_col'),
        ('Hipoacusia conductiva', c4, 'C4_hipoacusia_conductiva'),
    ]
    for i, (label, d, col) in enumerate(tamiz_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'
    html += '</div>'  # end left column

    # RIGHT: C) Alojamiento Conjunto
    html += '<div>'
    html += '<div class="sub2-title">C) Atenci\u00f3n de Reci\u00e9n Nacido en Alojamiento Conjunto</div>'
    html += '<table><thead><tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    right_items = [
        ('Atenci\u00f3n del RN en Alojamiento Conjunto', c4, 'C4_atencion_alojamiento_conjunto'),
        ('Evaluaci\u00f3n m\u00e9dica del reci\u00e9n nacido', c4, 'C4_evaluacion_medica_rn'),
        ('Tamizaje neonatal: toma de muestra', c24, 'C1_tamizaje_toma_muestra'),
        ('Tamizaje de hipoacusia', c24, 'C1_tamizaje_hipoacusia'),
        ('Tamizaje de catarata cong\u00e9nita', c24, 'C1_tamizaje_catarata_congenita'),
        ('Tamizaje de cardiopat\u00eda cong\u00e9nita', c24, 'C1_tamizaje_cardiopatia'),
    ]
    for i, (label, d, col) in enumerate(right_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # RIGHT: ConsejerÃ­a
    html += '<div class="sub2-title" style="margin-top:4px;">Consejer\u00eda en Atenci\u00f3n del RN - Alojamiento Conjunto</div>'
    html += '<table><thead><tr><th class="th-dark">ACTIVIDADES</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    cons_items = [
        ('Consejer\u00eda en corte y cuidado del cord\u00f3n umbilical', c4, 'C4_corte_cordon_umbilical'),
        ('Consejer\u00eda en Lactancia Materna Exclusiva', c4, 'C4_conse_lme'),
        ('Consejer\u00eda en importancia del control CRED (4 controles)', c4, 'C4_consej_import_control_cred'),
        ('Consejer\u00eda de identificaci\u00f3n de signos de alarma', c4, 'C4_conse_signos_alarma'),
        ('Consejer\u00eda en higiene del RN y cuidado en el hogar', c4, 'no_col'),
        ('Consejer\u00eda en alimentaci\u00f3n con suced\u00e1neos (neonatos VIH)', c4, 'no_col'),
    ]
    for i, (label, d, col) in enumerate(cons_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'

    # RIGHT: E) AtenciÃ³n RN en VD
    html += '<div class="sub2-title" style="margin-top:4px;">E) Atenci\u00f3n del Reci\u00e9n Nacido en Visita Domiciliaria</div>'
    html += '<table><thead><tr><th class="th-dark">DIAGN\u00d3STICOS</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    vd_items = [
        ('Visita domiciliaria para el cuidado y evaluaci\u00f3n neonatal', c4, 'C4_vd_cuidado_y_evaluacion_neonatal'),
        ('Anamnesis y examen f\u00edsico del RN normal', c4, 'C4_anamnesis_y_ex_fisico_rn_normal'),
        ('Consejer\u00eda en higiene del RN y cuidado en el hogar', c4, 'no_col'),
        ('Consejer\u00eda en cuidado del cord\u00f3n umbilical', c4, 'no_col'),
        ('Consejer\u00eda en importancia del control CRED (4 controles)', c4, 'C4_consej_import_control_cred'),
        ('Consejer\u00eda de identificaci\u00f3n de signos de alarma', c4, 'C4_conse_signos_alarma'),
        ('Consejer\u00eda en higiene de manos', c4, 'no_col'),
        ('Consejer\u00eda en Lactancia Materna Exclusiva hasta 6 meses', c4, 'C4_conse_lme'),
    ]
    for i, (label, d, col) in enumerate(vd_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_s(d, col)}</tr>'
    html += '</tbody></table>'
    html += '</div>'  # end right column
    html += '</div>'  # end dual-grid
    return html

# ============================================================
# SECTION: IX. EVALUACIÃ“N DEL DESARROLLO
# ============================================================
def _sec_evaluacion_desarrollo(all_data):
    html = '<div class="section-title">IX. EVALUACI\u00d3N DEL DESARROLLO</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="3">Edades</th>'
    html += '<th class="th-dark" colspan="10">Retardo del Desarrollo</th>'
    html += '<th class="th-dark" rowspan="3">Evaluac.<br>Normal</th>'
    html += '</tr><tr>'
    for dom in ['Lenguaje', 'Motora', 'Social', 'Coordinaci\u00f3n', 'Cognitiva']:
        html += f'<th class="th-medium" colspan="2">{dom}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '</tr></thead><tbody>'

    dev_groups = [('< 1 a\u00f1o', 'men1a'), ('01 a\u00f1o', '1a'), ('02 a\u00f1os', '2a')]
    for gi, (label, suf) in enumerate(dev_groups):
        cls = ' class="row-sub"' if gi % 2 == 1 else ''
        html += f'<tr{cls}>'
        html += f'<td class="label-left">{label}</td>'
        for dom in ['len', 'mot', 'soc', 'coo', 'cog']:
            html += _td(all_data.get(f'retardo_desarrollo_{dom}_{suf}', 0))
            html += _td(all_data.get(f'rec_retardo_desarrollo_{dom}_{suf}', 0))
        html += '<td class="nota">TD=D+DX=Z006+LAB=ED</td>'
        html += '</tr>'
    html += '<tr class="row-sub"><td colspan="12" style="text-align:left;padding-left:4px;font-size:8px;">Dx: Diagnosticado &nbsp;&nbsp;&nbsp; Recup: Recuperado</td></tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: II. SESIONES DE ATENCIÃ“N TEMPRANA
# ============================================================
def _sec_sesiones(all_data):
    html = '<div class="sub-section-title">II. SESIONES DE ATENCI\u00d3N TEMPRANA (99411)</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark">Edad</th>'
    for s in ['1\u00aa Sesi\u00f3n', '2\u00aa Sesi\u00f3n', '3\u00aa Sesi\u00f3n', '4\u00aa Sesi\u00f3n', '5\u00aa Sesi\u00f3n']:
        html += f'<th class="th-medium">{s}</th>'
    html += '<th class="th-dark">Ni\u00f1o con sesiones completas (Mensual)</th>'
    html += '<th class="th-dark">Ni\u00f1o con sesiones completas (Acum.)</th>'
    html += '</tr></thead><tbody>'
    # RN
    html += '<tr><td class="label-left">RN</td>'
    html += _td(all_data.get('sesion_est_temprana_menor_1a_1', 0))
    html += '<td></td><td></td><td></td><td></td>'
    html += _td(all_data.get('sesion_est_temprana_menor_1a_1', 0))
    html += '<td></td>'
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: VI. LACTANCIA MATERNA EXCLUSIVA
# ============================================================
def _sec_lactancia(all_data):
    html = '<div class="section-title">VI. LACTANCIA MATERNA EXCLUSIVA</div>'
    html += '<table style="width:50%"><thead><tr>'
    html += '<th class="th-dark">CONDICI\u00d3N</th><th class="th-dark">N\u00b0</th>'
    html += '</tr></thead><tbody>'
    for label, key in [
        ('Con lactancia materna exclusiva', 'lactancia_exclusiva'),
        ('Con lactancia materna no exclusiva', 'lactancia_no_exclusiva'),
        ('Con lactancia artificial', 'lactancia_artificial'),
        ('Con alimentaci\u00f3n mixta', 'alimentacion_mixta'),
    ]:
        html += f'<tr><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: X. PLAN DE ATENCIÃ“N INTEGRAL
# ============================================================
def _sec_plan_integral(all_data):
    html = '<div class="section-title">X. PLAN DE ATENCI\u00d3N INTEGRAL</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Edades</th>'
    ages = ['0-28d', '29d-11m', '12-23m', '24-35m', '36-47m', '4a', '5a', '6a', '7a', '8a', '9a', '10a', '11a']
    for a in ages:
        html += f'<th class="th-medium">{a}</th>'
    html += '</tr></thead><tbody>'

    elab_keys = ['plan_ais_ini_rn', 'plan_ais_ini_1m', 'plan_ais_ini_1a',
                 'plan_ais_ini_2a', 'plan_ais_ini_3a', 'plan_ais_ini_4a',
                 'plan_ais_ini_5a', 'plan_ais_ini_6a', 'plan_ais_ini_7a',
                 'plan_ais_ini_8a', 'plan_ais_ini_9a', 'plan_ais_ini_10a', 'plan_ais_ini_11a']
    html += '<tr><td class="label-left">Elaborado</td>'
    for k in elab_keys:
        html += _td(all_data.get(k, 0))
    html += '</tr>'

    ejec_keys = ['plan_ais_ta_rn', 'plan_ais_termino_7m', 'plan_ais_termino_1a',
                 'plan_ais_termino_2a', 'plan_ais_termino_3a', 'plan_ais_termino_4a',
                 'plan_ais_ta_5a', 'plan_ais_ta_6a', 'plan_ais_ta_7a',
                 'plan_ais_ta_8a', 'plan_ais_ta_9a', 'plan_ais_ta_10a', 'plan_ais_ta_11a']
    html += '<tr><td class="label-left">Ejecutado</td>'
    for k in ejec_keys:
        html += _td(all_data.get(k, 0))
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: IV. CONSEJERÃA
# ============================================================
def _sec_consejeria(all_data):
    html = '<div class="section-title">IV. CONSEJER\u00cdA EN LA ATENCI\u00d3N DEL NI\u00d1O(A)</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Tipos / Edades</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    age_labels = ['RN', '<1a', '1a', '2a', '3a', '4a', '5a', '6a', '7a', '8a', '9a', '10a', '11a']
    for a in age_labels:
        html += f'<th class="th-medium">{a}</th>'
    html += '</tr></thead><tbody>'

    consej_items = [
        ('Consejer\u00eda en atenci\u00f3n temprana del desarrollo',
         ['consej_atc_tempra_desarrollo_rn', 'consej_atc_tempra_desarrollo_men_1a',
          'consej_atc_tempra_desarrollo_1a', 'consej_atc_tempra_desarrollo_2a',
          'consej_atc_tempra_desarrollo_3a', 'consej_atc_tempra_desarrollo_4a',
          'consej_atc_tempra_desarrollo_5a', 'consej_atc_tempra_desarrollo_6a',
          'consej_atc_tempra_desarrollo_7a', 'consej_atc_tempra_desarrollo_8a',
          'consej_atc_tempra_desarrollo_9a', 'consej_atc_tempra_desarrollo_10a',
          'consej_atc_tempra_desarrollo_11a']),
        ('Consejer\u00eda en inmunizaciones',
         ['consej_inmunizaciones_rn', 'consej_inmunizaciones_men_1a',
          'consej_inmunizaciones_1a', 'consej_inmunizaciones_2a', 'consej_inmunizaciones_3a',
          'consej_inmunizaciones_4a', 'consej_inmunizaciones_5a', 'consej_inmunizaciones_6a',
          'consej_inmunizaciones_7a', 'consej_inmunizaciones_8a', 'consej_inmunizaciones_9a',
          'consej_inmunizaciones_10a', 'consej_inmunizaciones_11a']),
        ('Consejer\u00eda de identificaci\u00f3n de signos de alarma',
         ['conse_signos_alarma_rn', 'conse_signos_alarma_men_1a',
          'conse_signos_alarma_1a', 'conse_signos_alarma_2a', 'conse_signos_alarma_3a',
          'conse_signos_alarma_4a', 'conse_signos_alarma_5a', 'conse_signos_alarma_6a',
          'conse_signos_alarma_7a', 'conse_signos_alarma_8a', 'conse_signos_alarma_9a',
          'conse_signos_alarma_10a', 'conse_signos_alarma_11a']),
        ('Consejer\u00eda prevenci\u00f3n muerte s\u00fabita del lactante',
         ['conse_prev_muerte_subita_lactant_rn', 'conse_prev_muerte_subita_lactant_men_1a',
          'conse_prev_muerte_subita_lactant_1a', 'conse_prev_muerte_subita_lactant_2a',
          'conse_prev_muerte_subita_lactant_3a', 'conse_prev_muerte_subita_lactant_4a',
          'conse_prev_muerte_subita_lactant_5a', 'conse_prev_muerte_subita_lactant_6a',
          'conse_prev_muerte_subita_lactant_7a', 'conse_prev_muerte_subita_lactant_8a',
          'conse_prev_muerte_subita_lactant_9a', 'conse_prev_muerte_subita_lactant_10a',
          'conse_prev_muerte_subita_lactant_11a']),
        ('Consejer\u00eda prevenci\u00f3n enfermedades prevalentes (EDA, IRA)',
         ['conse_prev_enf_prevalentes_ira_eda_rn', 'conse_prev_enf_prevalentes_ira_eda_men_1a',
          'conse_prev_enf_prevalentes_ira_eda_1a', 'conse_prev_enf_prevalentes_ira_eda_2a',
          'conse_prev_enf_prevalentes_ira_eda_3a', 'conse_prev_enf_prevalentes_ira_eda_4a',
          'conse_prev_enf_prevalentes_ira_eda_5a', 'conse_prev_enf_prevalentes_ira_eda_6a',
          'conse_prev_enf_prevalentes_ira_eda_7a', 'conse_prev_enf_prevalentes_ira_eda_8a',
          'conse_prev_enf_prevalentes_ira_eda_9a', 'conse_prev_enf_prevalentes_ira_eda_10a',
          'conse_prev_enf_prevalentes_ira_eda_11a']),
        ('Consejer\u00eda en salud ocular',
         ['conse_salud_ocular_rn', 'conse_salud_ocular_men_1a',
          'conse_salud_ocular_1a', 'conse_salud_ocular_2a', 'conse_salud_ocular_3a',
          'conse_salud_ocular_4a', 'conse_salud_ocular_5a', 'conse_salud_ocular_6a',
          'conse_salud_ocular_7a', 'conse_salud_ocular_8a', 'conse_salud_ocular_9a',
          'conse_salud_ocular_10a', 'conse_salud_ocular_11a']),
        ('Consejer\u00eda en higiene de manos',
         ['conse_higiene_manos_rn', 'conse_higiene_manos_men_1a',
          'conse_higiene_manos_1a', 'conse_higiene_manos_2a', 'conse_higiene_manos_3a',
          'conse_higiene_manos_4a', 'conse_higiene_manos_5a', 'conse_higiene_manos_6a',
          'conse_higiene_manos_7a', 'conse_higiene_manos_8a', 'conse_higiene_manos_9a',
          'conse_higiene_manos_10a', 'conse_higiene_manos_11a']),
        ('Consejer\u00eda en pautas de crianza, buen trato',
         ['conse_pautas_crianza_rn', 'conse_pautas_crianza_men_1a',
          'conse_pautas_crianza_1a', 'conse_pautas_crianza_2a', 'conse_pautas_crianza_3a',
          'conse_pautas_crianza_4a', 'conse_pautas_crianza_5a', 'conse_pautas_crianza_6a',
          'conse_pautas_crianza_7a', 'conse_pautas_crianza_8a', 'conse_pautas_crianza_9a',
          'conse_pautas_crianza_10a', 'conse_pautas_crianza_11a']),
        ('Consejer\u00eda nutricional: Alimentaci\u00f3n saludable',
         ['conse_aliment_saludable_rn', 'conse_aliment_saludable_men_1a',
          'conse_aliment_saludable_1a', 'conse_aliment_saludable_2a', 'conse_aliment_saludable_3a',
          'conse_aliment_saludable_4a', 'conse_aliment_saludable_5a', 'conse_aliment_saludable_6a',
          'conse_aliment_saludable_7a', 'conse_aliment_saludable_8a', 'conse_aliment_saludable_9a',
          'conse_aliment_saludable_10a', 'conse_aliment_saludable_11a']),
        ('Consejer\u00eda en Lactancia Materna Exclusiva hasta 06m',
         ['', 'conse_lme_6m_men_1a', 'conse_lme_1a', 'conse_lme_2a', 'conse_lme_3a', 'conse_lme_4a',
          'conse_lme_5a', 'conse_lme_6a', 'conse_lme_7a', 'conse_lme_8a', 'conse_lme_9a', 'conse_lme_10a',
          'conse_lme_11a']),
    ]

    for i, (label, keys) in enumerate(consej_items):
        vals = [all_data.get(k, 0) if k else 0 for k in keys]
        total = sum(v for v in vals)
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(total)}'
        for v in vals:
            html += _td(v)
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: V. EVALUACIÃ“N NUTRICIONAL
# ============================================================
def _sec_evaluacion_nutricional(all_data):
    html = '<div class="section-title">V. EVALUACI\u00d3N NUTRICIONAL</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="3">GRUPO DE EDAD</th>'
    html += '<th class="th-dark" colspan="2">Peso para la Edad (PE)</th>'
    html += '<th class="th-dark" colspan="2">Peso para la Edad (TP)</th>'
    html += '<th class="th-dark" colspan="2">Talla para la Edad (TE)</th>'
    html += '</tr><tr>'
    for label in ['Desnutrici\u00f3n Global', 'Obesidad', 'Sobrepeso', 'Desnutrici\u00f3n Aguda', 'Desnutrici\u00f3n Cr\u00f3nica']:
        html += f'<th class="th-medium" colspan="2">{label}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '</tr></thead><tbody>'

    nut_groups = [('< 1 a\u00f1o', 'men1a'), ('1 a\u00f1o', '1a'), ('2 a\u00f1os', '2a'), ('3 a\u00f1os', '3a'), ('4 a\u00f1os', '4a')]
    nut_cols = [
        ('desnutric_global', 'desnutric_global_pr'),
        ('obeso', 'sobre_peso_pr'),
        ('sobre_peso', 'sobre_peso_pr'),
        ('desnutric_aguda', 'desnutric_aguda_pr'),
        ('desnutric_cronica', 'desnutric_cronica_pr'),
    ]
    for gi, (label, suf) in enumerate(nut_groups):
        cls = ' class="row-sub"' if gi % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for dx_base, rec_base in nut_cols:
            html += _td(all_data.get(f'{dx_base}_{suf}', 0))
            html += _td(all_data.get(f'{rec_base}_{suf}', 0))
        html += '</tr>'
    html += '</tbody></table>'

    # 5-11 years IMC
    html += '<div class="sub-section-title">C) En los Ni\u00f1os y Ni\u00f1as de 05 a 11 a\u00f1os</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">GRUPO DE EDAD</th>'
    html += '<th class="th-dark" colspan="2">Obesidad</th>'
    html += '<th class="th-dark" colspan="2">Sobrepeso</th>'
    html += '<th class="th-dark" colspan="2">Talla Alta</th>'
    html += '</tr><tr>'
    html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '<th class="th-medium">Dx.</th><th class="th-medium">Recup.</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-left">05 a 11 a\u00f1os</td>'
    html += _td(all_data.get('obeso_5_11a', 0))
    html += _td(all_data.get('obeso_rec_5_11a', 0))
    html += _td(all_data.get('sobre_peso_5_11a', 0))
    html += _td(all_data.get('sobre_peso_rec_5_11a', 0))
    html += _td(all_data.get('te_alto_5_11a', 0))
    html += _td(all_data.get('te_alto_rec_5_11a', 0))
    html += '</tr></tbody></table>'

    # Parasitosis IMC
    html += '<div class="section-title">VIII PARASITOSIS</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" colspan="2">Evaluaci\u00f3n por IMC de 5 a 11 a\u00f1os</th>'
    html += '<th class="th-dark">Dx</th><th class="th-dark">Recup</th>'
    html += '</tr></thead><tbody>'
    para_items = [
        ('Delgadez', 'delgadez_imc_5_11a', 'delgadez_imc_rec_5_11a'),
        ('Normal', 'normal_imc_5_11a', ''),
        ('Sobrepeso', 'sobrepeso_imc_5_11a', 'sobrepeso_imc_rec_5_11a'),
        ('Obeso', 'obeso_imc_5_11a', 'obeso_imc_rec_5_11a'),
    ]
    for i, (label, dx_key, rec_key) in enumerate(para_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td><td></td>'
        html += _td(all_data.get(dx_key, 0))
        html += _td(all_data.get(rec_key, 0) if rec_key else '')
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: LABORATORIO
# ============================================================
def _sec_laboratorio(all_data):
    html = '<div class="section-title">EX\u00c1MENES DE LABORATORIO / TAMIZAJES</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">ACTIVIDAD</th>'
    for age in ['1 a\u00f1o', '2 a\u00f1os', '3 a\u00f1os', '4 a\u00f1os', '5 a 11 a\u00f1os']:
        html += f'<th class="th-dark" colspan="3">{age}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">Prog</th><th class="th-medium">Mensual</th><th class="th-medium">%</th>'
    html += '</tr></thead><tbody>'

    lab_items = [
        ('Total de Dosaje HB/HTO',
         ['dosa_hb_1a', 'dosa_hb_2a', 'dosa_hb_3a', 'dosa_hb_4a', 'dosa_hb_5_11a']),
        ('Nro Total de Test de Graham',
         ['test_graham_1a', 'test_graham_2a', 'test_graham_3a', 'test_graham_4a', 'test_graham_5_11a']),
        ('Nro de Test de Graham Positivos',
         ['test_graham_posit_1a', 'test_graham_posit_2a', 'test_graham_posit_3a', 'test_graham_posit_4a', 'test_graham_posit_5_11a']),
        ('Nro Total de Examen Seriado de Heces',
         ['seriado_heces_1a', 'seriado_heces_2a', 'seriado_heces_3a', 'seriado_heces_4a', 'seriado_heces_5_11a']),
        ('Nro de Examen Seriado de Heces Positivos',
         ['seriado_heces_positivo_1a', 'seriado_heces_positivo_2a', 'seriado_heces_positivo_3a', 'seriado_heces_positivo_4a', 'seriado_heces_positivo_5_11a']),
    ]
    for i, (label, keys) in enumerate(lab_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for k in keys:
            html += '<td>0</td>'
            html += _td(all_data.get(k, 0))
            html += '<td>0</td>'
        html += '</tr>'

    # Parasitosis tratados
    graham_pos = sum(all_data.get(f'test_graham_posit_{suf}', 0) for suf in ['1a','2a','3a','4a','5_11a'])
    seriado_pos = sum(all_data.get(f'seriado_heces_positivo_{suf}', 0) for suf in ['1a','2a','3a','4a','5_11a'])
    html += f'<tr><td class="label-left">PARASITOSIS TEST GRAHAM O EXAMEN HECES TRATADOS</td>'
    for _ in range(5):
        html += '<td></td><td></td><td></td>'
    html += '</tr>'
    html += f'<tr><td class="label-left">DX DE PARASITOSIS</td><td class="num" colspan="3">{graham_pos + seriado_pos:,}</td>'
    for _ in range(4):
        html += '<td></td><td></td><td></td>'
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: IX. PROFILAXIS ANTIPARASITARIA
# ============================================================
def _sec_profilaxis(all_data):
    html = '<div class="section-title">IX. ADMINISTRACI\u00d3N DE PROFILAXIS ANTIPARASITARIA</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">ACTIVIDADES</th>'
    for age in ['01 a\u00f1o', '02 a\u00f1os', '03 a\u00f1os', '04 a\u00f1os', '05 - 11 a\u00f1os']:
        html += f'<th class="th-dark" colspan="2">{age}</th>'
    html += '</tr><tr>'
    for _ in range(5):
        html += '<th class="th-medium">1\u00ba</th><th class="th-medium">2\u00ba</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-left">Administraci\u00f3n de Profilaxis Antiparasitaria</td>'
    html += _td(all_data.get('antiparasitaria_1_1a', 0))
    html += _td(all_data.get('antiparasitaria_2_1a', 0))
    for k1, k2 in [('antiparasitaria_1_2a','antiparasitaria_2_2a'),
                    ('antiparasitaria_1_3a','antiparasitaria_2_3a'),
                    ('antiparasitaria_1_4a','antiparasitaria_2_4a'),
                    ('antiparasitaria_1_5_11a','antiparasitaria_2_5_11a')]:
        html += _td(all_data.get(k1, 0))
        html += _td(all_data.get(k2, 0))
    html += '</tr></tbody></table>'
    return html

# ============================================================
# SECTION: XII. VISITA DOMICILIARIA
# ============================================================
def _sec_visita_domiciliaria(all_data):
    html = '<div class="section-title">XII. VISITA DOMICILIARIA</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">TIPOS DE VISITA / EDADES</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    for a in ['RN', '<1a', '1a', '2a', '3a', '4a', '5-11a']:
        html += f'<th class="th-medium">{a}</th>'
    html += '</tr></thead><tbody>'

    vd_items = [
        ('Seguimiento al Control CRED', 'vd_seg_cred'),
        ('Seguimiento a Problemas Nutricionales', 'vd_seg_nutric'),
        ('Seguimiento a Problemas del Desarrollo', 'vd_seg_desarrollo'),
        ('Entrega de Suplementaci\u00f3n', 'vd_entrega_suplem'),
        ('Verificaci\u00f3n de Consumo de Micronutrientes', 'vd_verif_micronut'),
    ]
    for i, (label, prefix) in enumerate(vd_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        html += _td(all_data.get(f'{prefix}_total', 0))
        for a_suf in ['rn', 'men_1a', '1a', '2a', '3a', '4a', '5_11a']:
            html += _td(all_data.get(f'{prefix}_{a_suf}', 0))
        html += '</tr>'
    html += '<tr class="row-total"><td>TOTAL</td>'
    html += '<td></td>'
    for _ in range(7):
        html += '<td></td>'
    html += '</tr></tbody></table>'
    return html

# ============================================================
# SECTION: XV. SALUD MENTAL
# ============================================================
def _sec_salud_mental(all_data):
    html = '<div class="section-title">XV. SALUD MENTAL</div>'
    html += '<div class="dual-grid">'
    # Left: Psicosocial
    html += '<div>'
    html += '<div class="sub2-title">2.1 Evaluaci\u00f3n del desarrollo psicosocial con test de habilidades</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    psico_items = [
        ('Muy Bajo', 'sm_eval_psicosocial_muy_bajo'),
        ('Bajo', 'sm_eval_psicosocial_bajo'),
        ('Promedio Bajo', 'sm_eval_psicosocial_prom_bajo'),
        ('Promedio', 'sm_eval_psicosocial_prom'),
        ('Promedio Alto', 'sm_eval_psicosocial_prom_alto'),
        ('Alto', 'sm_eval_psicosocial_alto'),
        ('Muy Alto', 'sm_eval_psicosocial_muy_alto'),
    ]
    for i, (label, key) in enumerate(psico_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'
    html += '</div>'

    # Right column with 2 sections stacked
    html += '<div>'
    # Agudeza visual
    html += '<div class="sub2-title">2.2 Evaluaci\u00f3n de Agudeza visual</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    agudeza_items = [
        ('Normal', 'sm_eval_agudeza_normal'),
        ('Disminuci\u00f3n de Agudeza visual', 'sm_eval_agudeza_disminuida'),
    ]
    for i, (label, key) in enumerate(agudeza_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'

    # Postural
    html += '<div class="sub2-title" style="margin-top:4px;">2.5 Evaluaci\u00f3n F\u00edsico Postural</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    postural_items = [
        ('Normal', 'sm_eval_postural_normal'),
        ('Hiperlordosis', 'sm_eval_postural_hiperlordosis'),
        ('Hipercifosis', 'sm_eval_postural_hipercifosis'),
        ('Escoliosis', 'sm_eval_postural_escoliosis'),
    ]
    for i, (label, key) in enumerate(postural_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'

    # Tanner
    html += '<div class="sub2-title" style="margin-top:4px;">2.4 Desarrollo sexual seg\u00fan Tanner</div>'
    html += '<table><thead><tr><th class="th-dark">Resultado</th><th class="th-dark">N\u00b0</th></tr></thead><tbody>'
    tanner_items = [
        ('Adecuado', 'sm_tanner_adecuado'),
        ('Retardo', 'sm_tanner_retardo'),
        ('Precoz', 'sm_tanner_precoz'),
    ]
    for i, (label, key) in enumerate(tanner_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>{_td(all_data.get(key, 0))}</tr>'
    html += '</tbody></table>'
    html += '</div>'
    html += '</div>'  # end dual-grid
    return html

# ============================================================
# SECTION: TAMIZAJES
# ============================================================
def _sec_tamizajes(all_data):
    html = '<div class="section-title">TAMIZAJES</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">EDAD</th>'
    for h in ['< 1 - 2', '3 - 5', '6 - 9', '10 - 11']:
        html += f'<th class="th-dark">{h}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    tamizajes_items = [
        ('VIOLENCIA FAMILIAR / MALTRATO INFANTIL',
         ['tamizaje_viol_1_2a', 'tamizaje_viol_3_5a', 'tamizaje_viol_6_9a', 'tamizaje_viol_10_11a']),
        ('TRASTORNO DEPRESIVO',
         ['', '', '', 'tamizaje_td_10_11a']),
        ('ALCOHOL Y DROGAS',
         ['', '', 'tamizaje_ad_6_9a', 'tamizaje_ad_10_11a']),
        ('PROBLEMAS DEL NEURODESARROLLO 0-3 A\u00d1OS',
         ['tamizaje_nd_2a', '', '', '']),
        ('TRASTORNOS MENTALES Y DEL COMPORTAMIENTO',
         ['', '', '', '']),
    ]
    for i, (label, keys) in enumerate(tamizajes_items):
        vals = [all_data.get(k, 0) if k else 0 for k in keys]
        total = sum(v for v in vals)
        cls = ' class="row-header"' if i == 0 else (' class="row-sub"' if i % 2 == 0 else '')
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for v in vals:
            html += _td(v)
        html += _td(total)
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: TAMIZAJES POSITIVOS
# ============================================================
def _sec_tamizajes_positivos(all_data):
    html = '<div class="section-title">TAMIZAJES POSITIVOS</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">EDAD</th>'
    for h in ['< 1 - 2', '3 - 5', '6 - 9', '10 - 11']:
        html += f'<th class="th-dark">{h}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    pos_items = [
        ('VIOLENCIA FAMILIAR / MALTRATO INFANTIL',
         ['tamizaje_viol_posit_1_2a', 'tamizaje_viol_posit_3_5a', 'tamizaje_viol_posit_6_9a', 'tamizaje_viol_posit_10_11a']),
        ('TRASTORNO DEPRESIVO', ['', '', '', 'tamizaje_td_posit_10_11a']),
        ('TRASTORNO DE CONSUMO DE ALCOHOL', ['', '', '', 'tamizaje_ad_alcohol_posit_10_11a']),
        ('TRASTORNO DE CONSUMO DE TABACO', ['', '', '', 'tamizaje_ad_tabaco_posit_10_11a']),
        ('TRASTORNO DE CONSUMO DE DROGAS', ['', '', '', 'tamizaje_ad_drogas_posit_10_11a']),
        ('PROBLEMAS DEL NEURODESARROLLO', ['', '', '', '']),
        ('TRASTORNOS MENTALES Y DEL COMPORTAMIENTO', ['', '', '', '']),
    ]
    for i, (label, keys) in enumerate(pos_items):
        vals = [all_data.get(k, 0) if k else 0 for k in keys]
        total = sum(v for v in vals)
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for v in vals:
            html += _td(v)
        html += _td(total)
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: XV. SALUD OCULAR / ROP
# ============================================================
def _sec_rop(all_data):
    html = '<div class="section-title">XV. SALUD OCULAR</div>'
    html += '<div class="sub-section-title">RETINOPAT\u00cdA DE LA PREMATURIDAD - ROP</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Actividad</th>'
    for age in ['< 1m', '1m - 6m', '7m - 11m', '1a - 3a']:
        html += f'<th class="th-medium">{age}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    rop_items = [
        ('Tamizaje y seguimiento de RN con sospecha de ROP', 'o_tamrn_fr'),
        ('Tamizaje de reci\u00e9n nacidos con factores de riesgo', 'o_tamrn_fr_n'),
        ('Seguimiento de reci\u00e9n nacidos con factores de riesgo', 'o_tamrn_fr_s'),
        ('Referencia de reci\u00e9n nacidos con FR de ROP', 'o_tamrn_fr_r'),
        ('Diagn\u00f3stico de RN con ROP', 'o_dx_retinoprema'),
        ('Casos de reci\u00e9n nacidos con ROP', 'o_dx_retinoprema_c'),
        ('Referencia de reci\u00e9n nacidos con ROP', 'o_ref_retinoprema'),
        ('Tratamiento de RN con ROP', 'o_tto_retinoprema'),
        ('Tratamiento con L\u00e1ser', 'o_tto_retinoprema_ct_l'),
        ('Tratamiento con antiangiog\u00e9nico', 'o_tto_retinoprema_ct_a'),
        ('Tratamiento L\u00e1ser + antiangiog\u00e9nico', 'o_tto_retinoprema_ct_lm'),
        ('Tratamiento intrav\u00edtreo', 'o_tto_retinoprema_ct_i'),
    ]
    for i, (label, prefix) in enumerate(rop_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for age_suf in ['0_29d', '6m', '7m11m', '1_3a']:
            html += _td(all_data.get(f'{prefix}_{age_suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'
    html += '<tr class="row-total"><td>TOTAL</td>'
    for _ in range(5):
        html += '<td></td>'
    html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: ATENCIÃ“N SALUD OCULAR < 3a
# ============================================================
def _sec_salud_ocular_menor3(all_data):
    html = '<div class="section-title">ATENCI\u00d3N DE SALUD OCULAR EN NI\u00d1OS MENORES 3 A\u00d1OS</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">Actividad</th>'
    for age in ['< 1a', '1a', '2a', '3a', '4a', '5a']:
        html += f'<th class="th-medium">{age}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    ocular_items = [
        ('Examen de los Ojos y de la Visi\u00f3n - Normal', 'o_ex_ojo_vis_n'),
        ('Examen de los Ojos y de la Visi\u00f3n - Anormal', 'o_ex_ojo_vis_a'),
        ('Evaluaci\u00f3n sospecha alteraciones oculares', 'o_eva_ojo_vis_n'),
        ('Referencia de alteraciones oculares', 'o_ex_ojo_vis_rf'),
    ]
    for i, (label, prefix) in enumerate(ocular_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-left">{label}</td>'
        for age_suf in ['0_11m', '1a', '2a', '3a', '4a', '5a']:
            html += _td(all_data.get(f'{prefix}_{age_suf}', 0))
        html += _td(all_data.get(f'{prefix}_0_5a_total', 0))
        html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: ERRORES DE REFRACCIÃ“N
# ============================================================
def _sec_errores_refraccion(all_data):
    html = '<div class="section-title">ERRORES DE REFRACCI\u00d3N EN NI\u00d1OS DE 3 A 11 A\u00d1OS - ER</div>'
    html += '<table><thead><tr>'
    html += '<th class="th-dark" rowspan="2">EDAD</th>'
    for age in ['3 - 4a', '5 - 7a', '8 - 11a']:
        html += f'<th class="th-medium">{age}</th>'
    html += '<th class="th-dark" rowspan="2">TOTAL</th>'
    html += '</tr></thead><tbody>'

    er_items = [
        ('Tamizaje de ER', [
            ('Detecci\u00f3n de la Agudeza Visual', 'o_determ_agudeza_visual')]),
        ('Evaluaci\u00f3n de ER', [
            ('Evaluaci\u00f3n Errores Refractivos', 'o_determ_agudeza_visual_eva')]),
        ('Diagn\u00f3stico de ER', [
            ('Hipermetrop\u00eda', 'o_dx_errr_hip'),
            ('Miop\u00eda', 'o_dx_errr_mio'),
            ('Astigmatismo', 'o_dx_errr_ast'),
        ]),
    ]
    for cat, items in er_items:
        html += f'<tr class="row-header"><td class="label-left">{cat}</td>'
        for _ in range(4):
            html += '<td></td>'
        html += '</tr>'
        for i, (label, prefix) in enumerate(items):
            cls = ' class="row-sub"' if i % 2 == 1 else ''
            html += f'<tr{cls}><td class="label-indent">{label}</td>'
            for age_suf in ['3_4a', '5_7a', '8_11a']:
                html += _td(all_data.get(f'{prefix}_{age_suf}', 0))
            html += _td(all_data.get(f'{prefix}_total', 0))
            html += '</tr>'
    html += '</tbody></table>'
    return html

# ============================================================
# SECTION: XVI. IRAS/EDAS (within FORMATO NIÃ‘O)
# ============================================================
def _sec_iras_edas(all_data):
    html = '<div class="section-title">XVI. ATENCI\u00d3N DE LAS ENFERMEDADES PREVALENTES DE LA INFANCIA</div>'

    # A. IRA
    html += '<div class="sub-section-title">A. INFECCI\u00d3N RESPIRATORIA AGUDA (IRA)</div>'
    html += '<table>'
    html += '<colgroup><col style="width:350px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:100px"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">DIAGN\u00d3STICOS</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['29d a 59 D\u00edas', '02 - 11 Meses', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    html += '<tr class="row-header"><td class="label-left">1. Total de Casos de IRA (1+2+3)</td>'
    for _ in range(7):
        html += '<td class="zero">0</td>'
    html += '</tr>'

    html += '<tr class="row-sub"><td class="label-left">1.1 N\u00b0 casos de IRA sin complicaciones (a+b+c+d+e)</td>'
    for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
        html += _td(all_data.get(f'ira_sin_compl_{suf}', 0))
    html += _td(all_data.get('ira_sin_compl_total', 0))
    html += '</tr>'

    ira_sub_items = [
        ('a. IRA no complicada', 'ira_no_compl'),
        ('b. Faringoamigdalitis Aguda', 'faringoamigdalitis'),
        ('c. Otitis Media Aguda (OMA)', 'oma'),
        ('d. Sinusitis Aguda', 'sinusitis'),
        ('e. Neumon\u00eda sin complicaciones', 'neumonia_sin_compl'),
    ]
    for i, (label, prefix) in enumerate(ira_sub_items):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'

    html += '<tr class="row-sub"><td class="label-left">1.2 N\u00b0 casos IRA con complicaciones (a+b+c)</td>'
    for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
        html += _td(all_data.get(f'ira_con_compl_{suf}', 0))
    html += _td(all_data.get('ira_con_compl_total', 0))
    html += '</tr>'

    ira_compl = [
        ('a. IRA con complicaciones', 'ira_con_compl'),
        ('b. Neumon\u00eda Grave / EMG < 2 Meses', 'neumonia_grave_men2m'),
        ('c. Neumon\u00eda y EMG en 2m a 4a', 'neumonia_emg_2m_4a'),
    ]
    for i, (label, prefix) in enumerate(ira_compl):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['29d_59d', '2_11m', '1a', '2a', '3a', '4a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'

    html += '</tbody></table>'

    # B. SOB
    html += '<div class="sub-section-title">B. S\u00cdNDROME DE OBSTRUCCI\u00d3N BRONQUIAL (SOB) - ASMA</div>'
    html += '<table>'
    html += '<colgroup><col style="width:350px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:100px"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">DIAGN\u00d3STICOS</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['02 - 11 Meses', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o', '05 - 11 A\u00f1os']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-indent">a. SOB/Asma</td>'
    for suf in ['2_11m', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'sob_asma_{suf}', 0))
    html += _td(all_data.get('sob_asma_total', 0))
    html += '</tr></tbody></table>'

    # C. EDA
    html += '<div class="sub-section-title">C. ENFERMEDAD DIARREICA AGUDA (EDA)</div>'
    html += '<table>'
    html += '<colgroup><col style="width:350px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:100px"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">DIAGN\u00d3STICOS</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['< 01 A\u00f1o', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o', '05 - 11 A\u00f1os']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    html += '<tr class="row-header"><td class="label-left">1. Enfermedades Diarreicas sin complicaciones (a+b+c)</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'eda_sin_compl_{suf}', 0))
    html += _td(all_data.get('eda_sin_compl_total', 0))
    html += '</tr>'

    eda_sub = [
        ('a. Diarrea Aguda Acuosa sin deshidrataci\u00f3n', 'daa_sin_desh'),
        ('b. Diarrea Aguda Disent\u00e9rica sin deshidrataci\u00f3n', 'dad_sin_desh'),
        ('c. Diarrea Persistente sin deshidrataci\u00f3n', 'dp_sin_desh'),
    ]
    for i, (label, prefix) in enumerate(eda_sub):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'

    html += '<tr class="row-header"><td class="label-left">2. Enfermedades Diarreicas con complicaciones (a+b+c+d+e+f)</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'eda_con_compl_{suf}', 0))
    html += _td(all_data.get('eda_con_compl_total', 0))
    html += '</tr>'

    eda_compl = [
        ('a. Diarrea Aguda Acuosa con deshidrataci\u00f3n', 'daa_con_desh'),
        ('b. Diarrea Aguda Disent\u00e9rica con deshidrataci\u00f3n', 'dad_con_desh'),
        ('c. Diarrea Persistente con deshidrataci\u00f3n', 'dp_con_desh'),
        ('d. DAA con deshidrataci\u00f3n con shock', 'daa_con_desh_shock'),
        ('e. DAD con deshidrataci\u00f3n con shock', 'dad_con_desh_shock'),
        ('f. DP con deshidrataci\u00f3n con shock', 'dp_con_desh_shock'),
    ]
    for i, (label, prefix) in enumerate(eda_compl):
        cls = ' class="row-sub"' if i % 2 == 1 else ''
        html += f'<tr{cls}><td class="label-indent">{label}</td>'
        for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
            html += _td(all_data.get(f'{prefix}_{suf}', 0))
        html += _td(all_data.get(f'{prefix}_total', 0))
        html += '</tr>'
    html += '</tbody></table>'

    # Zinc y SRO
    html += '<div class="sub-section-title">ADMINISTRACI\u00d3N DE ZINC Y SAL DE REHIDRATACI\u00d3N ORAL</div>'
    html += '<table>'
    html += '<colgroup><col style="width:350px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:100px"></colgroup>'
    html += '<thead><tr><th class="th-dark" rowspan="2">ACTIVIDADES</th>'
    html += '<th class="th-dark" colspan="6">Grupo de Edad</th>'
    html += '<th class="th-dark" rowspan="2">Total</th>'
    html += '</tr><tr>'
    for h in ['< 1 a\u00f1o', '01 a\u00f1o', '2 a\u00f1o', '3 a\u00f1o', '4 a\u00f1o', '05 - 11 A\u00f1os']:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'
    html += '<tr><td class="label-left">Administraci\u00f3n de tratamiento - SRO</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'sro_{suf}', 0))
    html += _td(all_data.get('sro_total', 0))
    html += '</tr>'
    html += '<tr class="row-sub"><td class="label-left">Administraci\u00f3n de tratamiento - Zinc (ZN)</td>'
    for suf in ['men1a', '1a', '2a', '3a', '4a', '5_11a']:
        html += _td(all_data.get(f'zinc_{suf}', 0))
    html += _td(all_data.get('zinc_total', 0))
    html += '</tr>'
    html += '</tbody></table>'

    return html

# ============================================================
# TOP-LEVEL BUILDER
# ============================================================
def build_page1_html(col_names, filas_cred, totales_main, secciones,
                     c24, c1, c2, c3, c4, data_composite=None, filtros=None):
    """Build Page 1 HTML matching referencia de formato exel cred.txt EXACTLY."""
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    d = data_composite or {}

    # === HEADER ===
    html += _sec_header(filtros or {})

    # === CONTROL CRECIMIENTO Y DESARROLLO ===
    html += _sec_cred_controls(col_names, filas_cred, totales_main)

    # === I. ATENCIÃ“N DEL RECIÃ‰N NACIDO ===
    html += _sec_atencion_rn(c24, c1, c4)

    # === IX. EVALUACIÃ“N DEL DESARROLLO ===
    html += _sec_evaluacion_desarrollo(d)

    # === II. SESIONES + VI. LACTANCIA (dual-grid) ===
    html += '<div class="dual-grid">'
    html += _sec_sesiones(d)
    html += _sec_lactancia(d)
    html += '</div>'

    # === XVI. IRAS/EDAS ===
    html += _sec_iras_edas(d)

    # Footer
    html += '''
    <div style="font-size:8px;color:#595959;margin-top:8px;border-top:1px solid #9DC3E6;padding-top:4px;">
        DIRESA CUSCO &nbsp;|&nbsp; DEIT &nbsp;|&nbsp; Sistema HIS &nbsp;|&nbsp; CRED 2026
    </div>
    </div>'''
    return _wrap_tables(html)


# ============================================================
# IRAS/EDAS STANDALONE PAGE BUILDER
# ============================================================
def build_iras_edas_html(data):
    """Build IRAS/EDAS page matching ref HTML EXACTLY.

    data dict keys:
        filtros, anio, ie (iras_edas_2024 data), diag (diagnosis data with ref age groups),
        proc (CPT procedure data), resumen (monthly summary)
    """
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    f = data.get('filtros', {})
    anio = str(data.get('anio', '2026'))

    # === HEADER ===
    html += '''
    <div class="header">
        <h2>DIRECCI\u00d3N REGIONAL DE SALUD CUSCO</h2>
        <h3>DIRECCI\u00d3N DE ESTAD\u00cdSTICA E INFORM\u00c1TICA Y TELECOMUNICACI\u00d3N</h3>
    </div>'''
    html += '''
    <div class="filter-row">
        <div class="filter-cell"><label>RED DE SALUD:</label><span>''' + _esc(f.get('red', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MICRO RED:</label><span>''' + _esc(f.get('microred', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>PROVINCIA:</label><span>''' + _esc(f.get('provincia', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>A\u00d1O:</label><span>''' + anio + '''</span></div>
    </div>
    <div class="filter-row">
        <div class="filter-cell"><label>ESTABLECIMIENTO:</label><span>''' + _esc(f.get('establecimiento', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>DISTRITO:</label><span>''' + _esc(f.get('distrito', '(Todas)')) + '''</span></div>
        <div class="filter-cell"><label>MES INICIO:</label><span>''' + str(f.get('mes_ini', f.get('mes_inicio', '1'))) + '''</span></div>
        <div class="filter-cell"><label>MES FIN:</label><span>''' + str(f.get('mes_fin', f.get('mes_fin', '6'))) + '''</span></div>
    </div>'''

    html += '<div class="page-number">P\u00e1gina 01</div>'
    html += '<div class="section-title">XVI. ATENCI\u00d3N DE LAS ENFERMEDADES PREVALENTES DE LA INFANCIA</div>'

    ie = data.get('ie', {})
    diag = data.get('diag', {})
    proc = data.get('proc', {})

    def _iv(key):
        return ie.get(f'IE_{key}', 0) or 0

    def _diag(cat, age_key):
        return diag.get(cat, {}).get(age_key, 0) or 0

    # ================================================================
    # A. INFECCIÃ“N RESPIRATORIA AGUDA (IRA)
    # ================================================================
    html += '<div class="sub-section-title">A. INFECCI\u00d3N RESPIRATORIA AGUDA (IRA)</div>'
    html += '''<table>
    <colgroup>
      <col style="width:40px"><col style="width:280px">
      <col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px">
      <col style="width:100px"><col style="width:80px">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGN\u00d3STICOS</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 D\u00edas</th>
        <th class="th-medium">29d a 59 D\u00edas</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
        <th class="th-medium">Total</th>
      </tr>
    </thead>
    <tbody>'''

    AGE5 = ['men29d', '29d_59d', '2_11m', '1_4a', '5_11a']

    def _td_age(val):
        if val == 0: return '<td class="zero">0</td>'
        return f'<td class="num">{val:,}</td>'

    def _row_total(cat):
        return sum(_diag(cat, a) for a in AGE5)

    # -- IRA formula texts --
    F_IRA_NO_COMPL = 'TD=D+DX=J00X, J040, J041, J042, J060, J068, J069, J209'
    F_FARINGO = 'TD=D+DX=J020, J029, J030, J038, J039'
    F_OMA = 'TD=D+DX=H650, H651, H660, H669'
    F_SINUSITIS = 'TD=D+DX=J010, J011, J012, J013, J014, J019'
    F_NEUMONIA = 'TD=D+DX=J129, J159, J189'
    F_IRAS_COMPL = 'TD=D+DX=A369, A370, A371, A378, A379, J120, J121, J122, J123, J128, J13X, J14X, J150\u2026'
    F_NEUM_GRAVE = 'TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110\u2026'
    F_NEUM_EMG = 'TD=D+DX=J050, J051, J851, J860, J869, J90X, J939, J100, J110\u2026'

    def _ira_sum_row(label, cat):
        """Row: label (colspan=2) | 5 formula cells | subtotal | grand_total"""
        r = f'<tr class="row-header"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">{_esc(label)}</td>'
        row_total = _row_total(cat)
        for a in AGE5:
            r += _td_age(_diag(cat, a))
        r += _td_age(row_total)
        r += '<td class="zero">0</td></tr>'
        return r

    def _ira_sub_row(label, formula, cat):
        """Sub-item row: empty | diag-sub | 5 formula cells | subtotal | grand_total"""
        row_total = _row_total(cat)
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        for a in AGE5:
            v = _diag(cat, a)
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(row_total)
        r += '<td class="zero">0</td></tr>'
        return r

    def _ira_sub_row_nf(label, formula, cat):
        """Sub-item row with NO subtotal (neumonia grave has fewer cols)."""
        row_total = _row_total(cat)
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        for a in AGE5:
            v = _diag(cat, a)
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(row_total)
        r += '<td class="zero">0</td></tr>'
        return r

    # 1. Total de Casos de IRA
    html += _ira_sum_row('1. Total de Casos de IRA (1+2+3)', 'ira_total')

    # 1.1 IRA sin complicaciones
    html += f'<tr class="row-sub"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1.1 N\u00b0 casos de IRA sin complicaciones (a+b+c+d+e)</td>'
    sin_compl_total = sum(_diag(c, 'subtotal') for c in ['ira_no_compl','faringo','oma','sinusitis','neumonia_sin_compl'])
    for a in AGE5:
        html += _td_age(sum(_diag(c, a) for c in ['ira_no_compl','faringo','oma','sinusitis','neumonia_sin_compl']))
    html += _td_age(sin_compl_total)
    html += '<td class="zero">0</td></tr>'

    html += _ira_sub_row('a. Infecci\u00f3n Respiratoria Aguda (IRA) no complicada', F_IRA_NO_COMPL, 'ira_no_compl')
    html += _ira_sub_row('b. Faringoamigdalitis Aguda', F_FARINGO, 'faringo')
    html += _ira_sub_row('c. Otitis Media Aguda (OMA)', F_OMA, 'oma')
    html += _ira_sub_row('d. Sinusitis Aguda', F_SINUSITIS, 'sinusitis')
    html += _ira_sub_row('e. Neumon\u00eda sin complicaciones', F_NEUMONIA, 'neumonia_sin_compl')

    # 1.2 IRA con complicaciones
    html += f'<tr class="row-sub"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1.2 N\u00b0 casos IRA con complicaciones (a+b+c)</td>'
    con_compl_total = sum(_diag(c, 'subtotal') for c in ['iras_con_compl','neumonia_grave_men2m','neumonia_emg_2m_4a'])
    for a in AGE5:
        html += _td_age(sum(_diag(c, a) for c in ['iras_con_compl','neumonia_grave_men2m','neumonia_emg_2m_4a']))
    html += _td_age(con_compl_total)
    html += '<td class="zero">0</td></tr>'

    html += _ira_sub_row('a. Infecciones Respiratorias Agudas con complicaciones', F_IRAS_COMPL, 'iras_con_compl')
    html += _ira_sub_row_nf('b. Neumon\u00eda Grave o Enfermedad Muy Grave en Ni\u00f1os Menores de 2 Meses', F_NEUM_GRAVE, 'neumonia_grave_men2m')
    html += _ira_sub_row_nf('c. Neumon\u00eda y Enfermedad Muy Grave en Ni\u00f1os de 2 Meses a 4 A\u00f1os', F_NEUM_EMG, 'neumonia_emg_2m_4a')

    html += '</tbody></table>'

    # ================================================================
    # OXIGENOTERAPIA / OXIMETRÃA
    # ================================================================
    OXI_IRA_F = '(TD=R+DX=(J129,J159,J189)+DX=94799.02)'
    OXM_IRA_F = '(TD=R+DX=(J129,J159,J189)+DX=94760)'

    html += '<div class="sub-section-title">OXIGENOTERAPIA / OXIMETR\u00cdA</div>'
    html += '''<table>
    <colgroup>
      <col style="width:40px"><col style="width:280px">
      <col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px"><col style="width:85px">
      <col style="width:100px"><col style="width:80px">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDAD</th>
        <th class="th-dark" colspan="6">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 29 D\u00edas</th>
        <th class="th-medium">29d a 59 D\u00edas</th>
        <th class="th-medium">02 - 11 Meses</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
        <th class="th-medium">Total</th>
      </tr>
    </thead>
    <tbody>'''

    oxi_ira = proc.get('oxigeno_ira', {})
    oxm_ira = proc.get('oximetria_ira', {})

    def _oxi_row(label, formula, data):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        total = 0
        for a in AGE5:
            v = data.get(a, 0) or 0
            total += v
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(total)
        r += '<td class="zero">0</td></tr>'
        return r

    html += _oxi_row('Oxigenoterapia', OXI_IRA_F, oxi_ira)
    html += _oxi_row('Oximetr\u00eda', OXM_IRA_F, oxm_ira)

    html += '</tbody></table>'

    # ================================================================
    # B. SÃNDROME DE OBSTRUCCIÃ“N BRONQUIAL (SOB) - ASMA
    # ================================================================
    SOB_AGE7 = ['men29d', '29d_59d', '2_11m', '12_23m', '2a', '3_4a', '5_11a']
    SOB_HEADERS = ['< 29 D\u00edas', '29d a 59 D\u00edas', '02 - 11 Meses', '12m - 23m', '02 - 02 A\u00f1os 11m', '03 - 04 A\u00f1os', '05 - 11 A\u00f1os']
    F_SOB = 'TD=D+DX=J210,J211,J218,J219,J440,J441,J448,J449,J450,J451,J459,J46X'

    html += '<div class="sub-section-title">B. S\u00cdNDROME DE OBSTRUCCI\u00d3N BRONQUIAL (SOB) - ASMA</div>'
    html += '''<table>
    <colgroup>
      <col style="width:40px"><col style="width:240px">
      <col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px">
      <col style="width:75px">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGN\u00d3STICOS</th>
        <th class="th-dark" colspan="7">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>'''
    for h in SOB_HEADERS:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    sob_total = sum(_diag('sob_asma', a) for a in SOB_AGE7)
    html += '<tr class="row-header"><td colspan="2" style="text-align:left;padding-left:6px;font-weight:bold;">SOB/Asma</td>'
    for a in SOB_AGE7:
        html += _td_age(_diag('sob_asma', a))
    html += _td_age(sob_total)
    html += '</tr>'

    html += '<tr><td></td><td class="diag-sub">a. SOB/Asma</td>'
    for a in SOB_AGE7:
        v = _diag('sob_asma', a)
        if v == 0:
            html += f'<td class="formula">{_esc(F_SOB)}</td>'
        else:
            html += _td_age(v)
    html += _td_age(sob_total)
    html += '</tr>'

    html += '</tbody></table>'

    # ================================================================
    # OXIGENOTERAPIA Y NEBULIZACIÃ“N
    # ================================================================
    OXI_SOB_F = '(TD=R+DX=(J210\u2026J46X)+DX=94799.02)'
    NEB_SOB_F = '(TD=R+DX=(J210\u2026J46X)+DX=94664)'

    html += '<div class="sub-section-title">OXIGENOTERAPIA Y NEBULIZACI\u00d3N</div>'
    html += '''<table>
    <colgroup>
      <col style="width:40px"><col style="width:240px">
      <col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px"><col style="width:75px">
      <col style="width:75px">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDADES</th>
        <th class="th-dark" colspan="7">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>'''
    for h in SOB_HEADERS:
        html += f'<th class="th-medium">{h}</th>'
    html += '</tr></thead><tbody>'

    oxi_sob = proc.get('oxigeno_sob', {})
    neb_sob = proc.get('nebulizacion_sob', {})

    def _sob_proc_row(label, formula, data):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        total = 0
        for a in SOB_AGE7:
            v = data.get(a, 0) or 0
            total += v
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(total)
        return r + '</tr>'

    html += _sob_proc_row('Oxigenoterapia', OXI_SOB_F, oxi_sob)
    html += _sob_proc_row('Nebulizaci\u00f3n / Inhaloterapia', NEB_SOB_F, neb_sob)
    html += '<tr class="note-row"><td colspan="10">Fuentes Externas &nbsp;&nbsp;&nbsp; Reporte de Egresos</td></tr>'
    html += '</tbody></table>'

    # ================================================================
    # C. ENFERMEDAD DIARREICA AGUDA (EDA)
    # ================================================================
    EDA_AGE3 = ['menor1a', '1a_4a', '5_11a']
    EDA_HEADERS = ['< 01 A\u00f1o', '01 - 04 A\u00f1os', '05 - 11 A\u00f1os']
    F_DAA = 'TD=D+DX=A00.9,A01.0,A01.1,A01.2,A01.3,A01.4,A02.0,A04.0,A04.1,A04.9,A05.9,A06.2,A07.1,A07.2,A08.0,A08.2,A08.3,A08.4,A09.0,A09.9'
    F_DAD = 'TD=D+DX=A03.0,A03.9,A04.2,A04.3,A04.5,A06.0'
    F_DP = 'TD=D+DX=A09X'
    F_DAA_DESH = 'TD=D+DX=A00.9+E86X,A01.0+E86X,A01.1+E86X\u2026A09.9+E86X'
    F_DAD_DESH = 'TD=D+DX=A030+E86X,A039+E86X,A042+E86X,A043+E86X,A045+E86X,A060+E86X'
    F_DP_DESH = 'TD=D+DX=A09X+E86X'
    F_DAA_SHOCK = 'TD=D+DX=A00.9+E86X+R57.1\u2026A09.9+E86X+R57.1'
    F_DAD_SHOCK = 'TD=D+DX=A030+E86X+R57.1\u2026A060+E86X+R57.1'
    F_DP_SHOCK = 'TD=D+DX=A09X+E86X+R57.1'
    F_SRO = '(EDAD <= 11M) + DX=99199.11 + LAB=SRO'
    F_ZN = '(EDAD <= 11M) + DX=99199.11 + LAB=ZINC'

    def _eda_total(prefix, sfx, age_map):
        """Sum iras_edas_2024 columns for EDA diagnosis (sin_compl/desh/shock)."""
        total = 0
        a_keys = {'menor1a': 'menor1a', '1a_4a': '1a', '5_11a': '5_11a'}
        for ref_k, db_k in age_map.items():
            if ref_k == '1a_4a':
                total += (_iv(f'{prefix}{sfx}_{db_k}') + _iv(f'{prefix}{sfx}_2a') +
                         _iv(f'{prefix}{sfx}_3a') + _iv(f'{prefix}{sfx}_4a'))
            else:
                total += _iv(f'{prefix}{sfx}_{db_k}')
        return total

    def _eda_row(label, prefix, sfx=''):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        # <1a
        v1 = _iv(f'{prefix}{sfx}_menor1a')
        # 1-4a
        v2 = (_iv(f'{prefix}{sfx}_1a') + _iv(f'{prefix}{sfx}_2a') +
              _iv(f'{prefix}{sfx}_3a') + _iv(f'{prefix}{sfx}_4a'))
        # 5-11a
        v3 = _iv(f'{prefix}{sfx}_5_11a')
        total = v1 + v2 + v3
        for v in [v1, v2, v3]:
            r += _td_age(v)
        r += _td_age(total)
        return r + '</tr>'

    html += '<div class="sub-section-title">C. ENFERMEDAD DIARREICA AGUDA (EDA)</div>'
    html += '''<table>
    <colgroup>
      <col style="width:40px"><col style="width:350px">
      <col style="width:140px"><col style="width:140px"><col style="width:300px">
      <col style="width:100px">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">DIAGN\u00d3STICOS</th>
        <th class="th-dark" colspan="3">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 01 A\u00f1o</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
      </tr>
    </thead>
    <tbody>'''

    # 1. EDA sin complicaciones
    def _eda_sin_compl_total():
        t = 0
        for pref in ['eda_acuosa', 'disenterica', 'eda_persistente']:
            t += (_iv(f'{pref}_menor1a') + _iv(f'{pref}_1a') + _iv(f'{pref}_2a') +
                  _iv(f'{pref}_3a') + _iv(f'{pref}_4a') + _iv(f'{pref}_5_11a'))
        return t

    html += '<tr class="row-header"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">1. Enfermedades Diarreicas sin complicaciones (a+b+c)</td>'
    s1_men1a = sum(_iv(f'{p}_menor1a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    s1_1a4a = sum(_iv(f'{p}_1a')+_iv(f'{p}_2a')+_iv(f'{p}_3a')+_iv(f'{p}_4a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    s1_5_11 = sum(_iv(f'{p}_5_11a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    html += _td_age(s1_men1a) + _td_age(s1_1a4a) + _td_age(s1_5_11) + _td_age(s1_men1a+s1_1a4a+s1_5_11) + '</tr>'

    html += _eda_row('a. Diarrea Aguda Acuosa sin deshidrataci\u00f3n', 'eda_acuosa')
    html += _eda_row('b. Diarrea Aguda Disent\u00e9rica sin deshidrataci\u00f3n', 'disenterica')
    html += _eda_row('c. Diarrea Persistente sin deshidrataci\u00f3n', 'eda_persistente')

    # 2. EDA con complicaciones
    html += '<tr class="row-header"><td class="bold" colspan="2" style="text-align:left;padding-left:6px;">2. Enfermedades Diarreicas con complicaciones (a+b+c+d+e+f)</td>'
    s2_men1a = sum(_iv(f'{p}_desh_menor1a')+_iv(f'{p}_desh_shock_menor1a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    s2_1a4a = sum(_iv(f'{p}_desh_1a')+_iv(f'{p}_desh_2a')+_iv(f'{p}_desh_3a')+_iv(f'{p}_desh_4a') +
                  _iv(f'{p}_desh_shock_1a')+_iv(f'{p}_desh_shock_2a')+_iv(f'{p}_desh_shock_3a')+_iv(f'{p}_desh_shock_4a')
                  for p in ['eda_acuosa','disenterica','eda_persistente'])
    s2_5_11 = sum(_iv(f'{p}_desh_5_11a')+_iv(f'{p}_desh_shock_5_11a') for p in ['eda_acuosa','disenterica','eda_persistente'])
    html += _td_age(s2_men1a) + _td_age(s2_1a4a) + _td_age(s2_5_11) + _td_age(s2_men1a+s2_1a4a+s2_5_11) + '</tr>'

    html += _eda_row('a. Diarrea Aguda Acuosa con deshidrataci\u00f3n', 'eda_acuosa', '_desh')
    html += _eda_row('b. Diarrea Aguda Disent\u00e9rica con deshidrataci\u00f3n', 'disenterica', '_desh')
    html += _eda_row('c. Diarrea Persistente con deshidrataci\u00f3n', 'eda_persistente', '_desh')
    html += _eda_row('d. Diarrea Aguda Acuosa con deshidrataci\u00f3n con shock', 'eda_acuosa', '_desh_shock')
    html += _eda_row('e. Diarrea Aguda Disent\u00e9rica con deshidrataci\u00f3n con shock', 'disenterica', '_desh_shock')
    html += _eda_row('f. Diarrea Persistente con deshidrataci\u00f3n con shock', 'eda_persistente', '_desh_shock')

    html += '</tbody></table>'

    # ================================================================
    # ADMINISTRACIÃ“N DE ZINC Y SAL DE REHIDRATACIÃ“N ORAL
    # ================================================================
    html += '<div class="sub-section-title">ADMINISTRACI\u00d3N DE ZINC Y SAL DE REHIDRATACI\u00d3N ORAL</div>'
    html += '''<table>
    <colgroup>
      <col style="width:40px"><col style="width:350px">
      <col style="width:140px"><col style="width:140px"><col style="width:300px">
      <col style="width:100px">
    </colgroup>
    <thead>
      <tr>
        <th class="th-dark" colspan="2" rowspan="2">ACTIVIDADES</th>
        <th class="th-dark" colspan="3">Grupo de Edad</th>
        <th class="th-dark" rowspan="2">Total</th>
      </tr>
      <tr>
        <th class="th-medium">&lt; 1 a\u00f1o</th>
        <th class="th-medium">01 - 04 A\u00f1os</th>
        <th class="th-medium">05 - 11 A\u00f1os</th>
      </tr>
    </thead>
    <tbody>'''

    def _sro_row(label, prefix, formula):
        r = f'<tr><td></td><td class="diag-sub">{_esc(label)}</td>'
        v1 = _iv(f'{prefix}_menor1a')
        v2 = _iv(f'{prefix}_1a') + _iv(f'{prefix}_2a') + _iv(f'{prefix}_3a') + _iv(f'{prefix}_4a')
        v3 = _iv(f'{prefix}_5_11a')
        total = v1 + v2 + v3
        for v in [v1, v2, v3]:
            if v == 0:
                r += f'<td class="formula">{_esc(formula)}</td>'
            else:
                r += _td_age(v)
        r += _td_age(total)
        return r + '</tr>'

    html += _sro_row('Administraci\u00f3n de tratamiento (Sales de Rehidrataci\u00f3n Oral - SRO)', 'tto_sro', F_SRO)
    html += _sro_row('Administraci\u00f3n de tratamiento (Zinc - ZN)', 'tto_zn', F_ZN)

    html += '</tbody></table>'

    # ================================================================
    # RESUMEN ACUMULADO
    # ================================================================
    resumen = data.get('resumen', [])
    if not resumen:
        resumen = [{'mes': m} for m in range(1, 7)]

    RH = ['Mes', 'EDA Acuosa <1a', 'EDA Acuosa 1a', 'EDA Acuosa 2a', 'EDA Acuosa 3a', 'EDA Acuosa 4a',
          'IRA no comp <5a', 'Faringoamig. <5a', 'OMA <5a', 'Neumonia <5a', 'IRAS comp.', 'FONI']
    RK = ['eda_acuosa_men1a','eda_acuosa_1a','eda_acuosa_2a','eda_acuosa_3a','eda_acuosa_4a',
          'ira_no_compl_men5a','faringo_men5a','oma_men5a','neumonia_men5a','iras_compl','foni']

    html += f'<div class="sub-section-title">RESUMEN ACUMULADO (Enero - Junio {anio}) - HOJA PROCESO</div>'
    html += '<table><thead><tr>'
    for h in RH:
        cls = ' class="th-dark"' if h in ('Mes', 'FONI') else ' class="th-medium"'
        html += f'<th{cls}>{_esc(h)}</th>'
    html += '</tr></thead><tbody>'

    MESES = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Setiembre','Octubre','Noviembre','Diciembre']
    TR = {k: 0 for k in RK}
    for rm in resumen:
        mi = int(rm.get('mes', 1))
        row_cls = ' class="row-sub"' if mi % 2 == 0 else ''
        html += f'<tr{row_cls}><td>{mi} - {_esc(MESES[mi-1] if mi <= len(MESES) else "")}</td>'
        for k in RK:
            v = int(rm.get(k, 0) or 0)
            html += _td_age(v)
            TR[k] += v
        html += '</tr>'

    html += '<tr style="background:#2E75B6;color:#fff;font-weight:bold;"><td>TOTAL GENERAL</td>'
    for k in RK:
        html += _td_age(TR[k])
    html += '</tr>'

    html += '</tbody></table>'

    # Footer
    html += f'''
    <div style="font-size:8px;color:#595959;margin-top:8px;border-top:1px solid #9DC3E6;padding-top:4px;">
        DIRESA CUSCO &nbsp;|&nbsp; DEIT &nbsp;|&nbsp; Sistema HIS &nbsp;|&nbsp; A\u00f1o {anio} &nbsp;|&nbsp; Impreso: <span id="fecha_ie"></span>
    </div>'''

    html += '</div>'
    return _wrap_tables(html)


def _render_seccion_table(sec):
    """Render a single seccion dict as CSS-class table."""
    titulo = sec.get('titulo', '')
    cols = sec.get('columnas', ['INDICADOR', 'TOTAL'])
    filas = sec.get('filas', [])
    html = f'<div class="section-title">{_esc(titulo)}</div>'
    html += '<table><thead><tr>'
    for c in cols:
        html += f'<th class="th-dark">{_esc(c)}</th>'
    html += '</tr></thead><tbody>'
    for fi, fila in enumerate(filas):
        if isinstance(fila, dict):
            vals = [fila.get(c, 0) for c in cols]
        elif isinstance(fila, list):
            vals = fila
        else:
            vals = [fila]
        cls = ' class="row-sub"' if fi % 2 == 1 else ''
        html += f'<tr{cls}>'
        for vi, v in enumerate(vals):
            if vi == 0:
                html += f'<td class="label-left">{_esc(str(v))}</td>'
            else:
                vn = int(v) if isinstance(v, (int, float)) else 0
                if vn == 0:
                    html += '<td class="zero">0</td>'
                else:
                    html += f'<td class="num">{vn:,}</td>'
        html += '</tr>'
    total = sec.get('total', 0)
    if total:
        html += f'<tr class="row-total"><td>TOTAL</td>'
        for c in cols[1:]:
            vn = int(total) if isinstance(total, (int, float)) else 0
            if vn == 0:
                html += '<td class="zero">0</td>'
            else:
                html += f'<td class="num">{vn:,}</td>'
        html += '</tr>'
    html += '</tbody></table>'
    return html


def build_suplementacion_html(secciones):
    """Build Page 2: Suplementacion."""
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    html += _sec_header({})
    for sec in secciones:
        html += _render_seccion_table(sec)
    html += '</div>'
    return _wrap_tables(html)


def build_tx_anemia_html(secciones):
    """Build Page 3: Tratamiento de Anemia."""
    html = '<style>' + _REPORT_CSS + '</style>'
    html += '<div class="page">'
    html += _sec_header({})
    for sec in secciones:
        html += _render_seccion_table(sec)
    html += '</div>'
    return _wrap_tables(html)

