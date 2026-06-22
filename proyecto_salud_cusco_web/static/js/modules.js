var dashReloadTimer = null;
// ==================== SELECTOR NATIVO DE CARPETA ====================
async function _seleccionarCarpeta(inputId, infoId) {
    try {
        const r = await fetch('/api/seleccionar-carpeta', { method: 'POST' });
        const d = await r.json();
        if (d.ruta) {
            document.getElementById(inputId).value = d.ruta;
            document.getElementById(inputId).dispatchEvent(new Event('input'));
            document.getElementById(infoId).textContent = '✅ Carpeta: ' + d.ruta;
        }
    } catch (e) {
        toast('Error al abrir explorador: ' + e.message, 'error');
    }
}

// ==================== PADRON NOMINAL ====================
const PN = { pagina: 1, total: 0, porPagina: 50 };

function pnRutaGuardar() {
    var val = document.getElementById('pn-ruta-carpeta').value.trim();
    try { localStorage.setItem('pn_ruta_carpeta', val); } catch(e) {}
}
function pnRutaCargar() {
    try {
        var val = localStorage.getItem('pn_ruta_carpeta') || '';
        document.getElementById('pn-ruta-carpeta').value = val;
    } catch(e) {}
}
function pnExplorarCarpeta() { _seleccionarCarpeta('pn-ruta-carpeta', 'pn-ruta-info'); }

async function pnStatus() {
    try {
        const r = await fetch('/api/padron/status');
        const d = await r.json();
        const el = document.getElementById('pn-status-text');
        if (d.existe) {
            el.innerHTML = '✅ <strong>' + d.total.toLocaleString() + '</strong> registros cargados';
            el.parentElement.className = 'status-indicator ok';
            document.getElementById('btn-pn-cargar').textContent = '🔄 Recargar Padr\u00f3n Nominal';
        } else {
            el.textContent = '⚠️ No hay datos de Padr\u00f3n Nominal. Cargue el CSV.';
            el.parentElement.className = 'status-indicator warning';
        }
    } catch (e) {}
}

async function pnCargar() {
    pnRutaGuardar();
    const btn = document.getElementById('btn-pn-cargar');
    btn.disabled = true;
    btn.textContent = '⏳ Cargando...';
    var ruta = document.getElementById('pn-ruta-carpeta').value.trim();
    try {
        const r = await fetch('/api/padron/cargar', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ruta_carpeta: ruta }) });
        const d = await r.json();
        if (d.token) startPolling(d.token, {
            onComplete: function() { pnStatus(); pnConsultar(1); toast('Padr\u00f3n Nominal cargado', 'success'); },
            onError: function(s) { toast('Error: ' + s.error, 'error'); btn.disabled = false; btn.textContent = '📥 Cargar Padr\u00f3n Nominal'; },
            onCancel: function() { btn.disabled = false; btn.textContent = '📥 Cargar Padr\u00f3n Nominal'; }
        });
    } catch (e) { toast('Error: ' + e.message, 'error'); btn.disabled = false; btn.textContent = '📥 Cargar Padr\u00f3n Nominal'; }
}

async function pnConsultar(pag) {
    PN.pagina = pag || 1;
    const busq = document.getElementById('pn-busqueda').value;
    try {
        const r = await fetch('/api/padron/consulta', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ pagina: PN.pagina, por_pagina: PN.porPagina, busqueda: busq }) });
        const d = await r.json();
        PN.total = d.total;
        var totalPag = Math.ceil(d.total / d.por_pagina) || 1;
        document.getElementById('pn-total-info').textContent = d.total + ' registros encontrados (p\u00e1g. ' + d.pagina + '/' + totalPag + ')';
        document.getElementById('pn-page-info').textContent = 'P\u00e1g. ' + d.pagina;
        document.getElementById('pn-paginacion').style.display = d.total > d.por_pagina ? 'block' : 'none';
        var el = document.getElementById('pn-resultados');
        if (!d.filas || d.filas.length === 0) { el.innerHTML = '<p style="color:var(--text-muted);padding:16px;">Sin resultados</p>'; return; }
        var html = '<table class="data-table" style="font-size:11px;"><tr><th>N\u00b0</th><th>Apellidos/Nombres</th><th>Edad</th><th>Direcci\u00f3n</th><th>Distrito</th><th>Madre</th><th>Celular</th><th>EESS</th><th>Coord</th></tr>';
        d.filas.forEach(function(f) {
            var coords = (f.latitud && f.longitud) ? (f.latitud.toFixed(4) + ', ' + f.longitud.toFixed(4)) : '\u2014';
            html += '<tr><td>' + (f.nro || '') + '</td><td>' + (f.apellido_pat_nino || '') + ' ' + (f.apellido_mat_nino || '') + ', ' + (f.nombre_nino || '') + '</td><td>' + (f.edad_actual || '') + '</td><td>' + (f.direccion || '') + '</td><td>' + (f.dist_nino || '') + '</td><td>' + (f.nombre_madre || '') + '</td><td>' + (f.celular || '') + '</td><td>' + (f.nombre_eess || '') + '</td><td style="font-size:10px;">' + coords + '</td></tr>';
        });
        html += '</table>';
        el.innerHTML = html;
    } catch (e) { toast('Error: ' + e.message, 'error'); }
}

function pnCambiarPag(dir) {
    var totalPag = Math.ceil(PN.total / PN.porPagina);
    var nueva = PN.pagina + dir;
    if (nueva < 1 || nueva > totalPag) return;
    pnConsultar(nueva);
}

// ==================== CNV ====================
const CNV = { pagina: 1, total: 0, porPagina: 50 };

function cnvRutaGuardar() {
    var val = document.getElementById('cnv-ruta-carpeta').value.trim();
    try { localStorage.setItem('cnv_ruta_carpeta', val); } catch(e) {}
}
function cnvRutaCargar() {
    try {
        var val = localStorage.getItem('cnv_ruta_carpeta') || '';
        document.getElementById('cnv-ruta-carpeta').value = val;
    } catch(e) {}
}
function cnvExplorarCarpeta() { _seleccionarCarpeta('cnv-ruta-carpeta', 'cnv-ruta-info'); }

async function cnvStatus() {
    try {
        const r = await fetch('/api/cnv/status');
        const d = await r.json();
        const el = document.getElementById('cnv-status-text');
        if (d.existe) {
            el.innerHTML = '✅ <strong>' + d.total.toLocaleString() + '</strong> registros cargados';
            el.parentElement.className = 'status-indicator ok';
            document.getElementById('btn-cnv-cargar').textContent = '🔄 Recargar CNV';
        } else {
            el.textContent = '⚠️ No hay datos CNV. Cargue el CSV.';
            el.parentElement.className = 'status-indicator warning';
        }
    } catch (e) {}
}

async function cnvCargar() {
    cnvRutaGuardar();
    const btn = document.getElementById('btn-cnv-cargar');
    btn.disabled = true;
    btn.textContent = '⏳ Cargando...';
    var ruta = document.getElementById('cnv-ruta-carpeta').value.trim();
    try {
        const r = await fetch('/api/cnv/cargar', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ruta_carpeta: ruta }) });
        const d = await r.json();
        if (d.token) startPolling(d.token, {
            onComplete: function() { cnvStatus(); cnvConsultar(1); toast('CNV cargado', 'success'); },
            onError: function(s) { toast('Error: ' + s.error, 'error'); btn.disabled = false; btn.textContent = '📥 Cargar CNV'; },
            onCancel: function() { btn.disabled = false; btn.textContent = '📥 Cargar CNV'; }
        });
    } catch (e) { toast('Error: ' + e.message, 'error'); btn.disabled = false; btn.textContent = '📥 Cargar CNV'; }
}

async function cnvConsultar(pag) {
    CNV.pagina = pag || 1;
    const busq = document.getElementById('cnv-busqueda').value;
    try {
        const r = await fetch('/api/cnv/consulta', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ pagina: CNV.pagina, por_pagina: CNV.porPagina, busqueda: busq }) });
        const d = await r.json();
        CNV.total = d.total;
        var totalPag = Math.ceil(d.total / d.por_pagina) || 1;
        document.getElementById('cnv-total-info').textContent = d.total + ' registros encontrados (p\u00e1g. ' + d.pagina + '/' + totalPag + ')';
        document.getElementById('cnv-page-info').textContent = 'P\u00e1g. ' + d.pagina;
        document.getElementById('cnv-paginacion').style.display = d.total > d.por_pagina ? 'block' : 'none';
        var el = document.getElementById('cnv-resultados');
        if (!d.filas || d.filas.length === 0) { el.innerHTML = '<p style="color:var(--text-muted);padding:16px;">Sin resultados</p>'; return; }
        var html = '<table class="data-table" style="font-size:11px;"><tr><th>NU_CNV</th><th>Madre</th><th>Edad Madre</th><th>Distrito</th><th>Sexo</th><th>Peso</th><th>EESS</th><th>Fecha Nac.</th></tr>';
        d.filas.forEach(function(f) {
            html += '<tr><td>' + (f.nu_cnv || '') + '</td><td>' + (f.pri_ape_madre || '') + ' ' + (f.seg_ape_madre || '') + ', ' + (f.prenom_madre || '') + '</td><td>' + (f.edad_madre || '') + '</td><td>' + (f.dist_madre || '') + '</td><td>' + (f.sexo_nacido || '') + '</td><td>' + (f.peso_nacido || '') + '</td><td>' + (f.nombre_eess || '') + '</td><td>' + (f.fe_nacido || '') + '</td></tr>';
        });
        html += '</table>';
        el.innerHTML = html;
    } catch (e) { toast('Error: ' + e.message, 'error'); }
}

function cnvCambiarPag(dir) {
    var totalPag = Math.ceil(CNV.total / CNV.porPagina);
    var nueva = CNV.pagina + dir;
    if (nueva < 1 || nueva > totalPag) return;
    cnvConsultar(nueva);
}

// ==================== MAPA / GEOLOCALIZACION ====================
var MAPA = null;
var MAPA_MARKERS = null;
var MAPA_HEAT = null;
var MAPA_EESS = null;
var MAPA_HOTSPOTS = null;

async function mapaInit() {
    try {
        const r = await fetch('/api/padron/geojson');
        const d = await r.json();
        var statusEl = document.getElementById('mapa-status-text');
        var statusDot = document.getElementById('mapa-status-dot');
        if (!d.features || d.features.length === 0) {
            statusEl.textContent = '⚠ No hay pacientes con coordenadas';
            return;
        }
        statusEl.innerHTML = '✅ <strong>' + d.features.length + '</strong> pacientes geo-localizados';
        statusDot.className = 'status-dot ok';

        cargarDistritos();

        if (!MAPA) {
            MAPA = L.map('mapa-container').setView([-13.5, -71.9], 9);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 18, attribution: '&copy; OpenStreetMap' }).addTo(MAPA);
        }
        setTimeout(function() { if (MAPA) MAPA.invalidateSize(); }, 100);

        if (MAPA_MARKERS) MAPA.removeLayer(MAPA_MARKERS);
        MAPA_MARKERS = L.layerGroup();
        d.features.forEach(function(f) {
            var coords = f.geometry.coordinates;
            var props = f.properties;
            var marker = L.marker([coords[1], coords[0]]);
            marker.bindPopup('<b>' + (props.nombre||'') + '</b><br>' + (props.direccion||'') + '<br>' + (props.distrito||''));
            MAPA_MARKERS.addLayer(marker);
        });
        MAPA.addLayer(MAPA_MARKERS);

        if (d.features.length > 1) {
            var bounds = d.features.map(function(f) { return [f.geometry.coordinates[1], f.geometry.coordinates[0]]; });
            MAPA.fitBounds(bounds, { padding: [20, 20] });
        }

        // Load establishments
        mapaCargarEESS();
    } catch (e) {
        document.getElementById('mapa-status-text').textContent = 'Error: ' + e.message;
    }
}

async function mapaCargarEESS() {
    try {
        const r = await fetch('/api/mapa/establecimientos');
        const d = await r.json();
        var el = document.getElementById('mapa-eess');
        if (!d || d.length === 0) { el.innerHTML = '<p style="color:var(--text-muted);">Sin datos</p>'; return; }
        var html = '<table class="data-table" style="font-size:10px;width:100%;"><tr><th>EESS</th><th>Cat</th><th>Distrito</th></tr>';
        d.forEach(function(e) {
            html += '<tr><td>' + (e.nombre||'') + '</td><td>' + (e.categoria||'') + '</td><td>' + (e.distrito||'') + '</td></tr>';
        });
        html += '</table>';
        el.innerHTML = html;

        if (MAPA_EESS) MAPA.removeLayer(MAPA_EESS);
        MAPA_EESS = L.layerGroup();
        d.forEach(function(e) {
            if (e.ubigueo && e.ubigueo.length >= 6) {
                var lat = parseFloat('-' + e.ubigueo.substring(0,2)) || -13.5;
                var lng = parseFloat('-7' + e.ubigueo.substring(2,4)) || -71.9;
                var icon = L.divIcon({
                    className: 'eess-marker',
                    html: e.categoria && e.categoria.includes('H') ? '🏥' : '🏪',
                    iconSize: [20, 20]
                });
                var marker = L.marker([lat, lng], { icon: icon });
                marker.bindPopup('<b>' + e.nombre + '</b><br>' + e.categoria + '<br>' + e.distrito + '<br>' + e.microred);
                MAPA_EESS.addLayer(marker);
            }
        });
        MAPA.addLayer(MAPA_EESS);
    } catch (e) {}
}

async function cargarDistritos() {
    try {
        const r = await fetch('/api/mapa/pacientes-por-distrito');
        const d = await r.json();
        var el = document.getElementById('mapa-distritos');
        var html = '<table class="data-table" style="font-size:11px;width:100%;"><tr><th>Distrito</th><th>Total</th><th>Coord</th></tr>';
        d.forEach(function(row) {
            html += '<tr><td>' + (row.distrito||'') + '</td><td>' + (row.total||0) + '</td><td>' + (row.con_coord||0) + '</td></tr>';
        });
        html += '</table>';
        el.innerHTML = html;
    } catch (e) {}
}

async function mapaKDE() {
    var infoEl = document.getElementById('mapa-kde-info');
    var filtro = document.getElementById('mapa-kde-filtro').value;
    var anio = document.getElementById('mapa-kde-anio').value;
    infoEl.textContent = '⏳ Generando KDE con ' + filtro + '...';
    try {
        const r = await fetch('/api/mapa/kde', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ anio: anio, filtro: filtro }) });
        const d = await r.json();
        if (d.error) { infoEl.textContent = 'Error: ' + d.error; return; }
        infoEl.textContent = '🔥 KDE: ' + d.coords_count + ' pts, tipo=' + (d.type||'') + ', mostrando ' + (d.coordenadas||[]).length;

        if (!MAPA) { mapaInit(); return; }
        if (MAPA_HEAT) MAPA.removeLayer(MAPA_HEAT);
        if (MAPA_HOTSPOTS) MAPA.removeLayer(MAPA_HOTSPOTS);

        var heatData = (d.coordenadas || []).map(function(c) { return [c[0], c[1], c[2]||0.3]; });
        MAPA_HEAT = L.heatLayer(heatData, { radius: 24, blur: 16, maxZoom: 17, max: 1.0, gradient: {0.3: 'blue', 0.55: 'lime', 0.7: 'yellow', 0.9: 'red'} });
        MAPA.addLayer(MAPA_HEAT);

        MAPA_HOTSPOTS = L.layerGroup();
        (d.hotspots || []).forEach(function(h) {
            var marker = L.circleMarker([h.latitud, h.longitud], {
                radius: 6 + Math.round((h.densidad || 0) * 8),
                color: '#C0392B',
                weight: 2,
                fillColor: '#E74C3C',
                fillOpacity: 0.75
            });
            marker.bindPopup('<b>Hotspot #' + h.rank + '</b><br>Densidad: ' + ((h.densidad || 0) * 100).toFixed(1) + '%<br>' + h.latitud + ', ' + h.longitud);
            MAPA_HOTSPOTS.addLayer(marker);
        });
        MAPA.addLayer(MAPA_HOTSPOTS);

        var fallbackTxt = d.fallback ? ' | datos ' + d.anio_datos + ' por fallback' : '';
        var html = '<div><strong>KDE gaussiano:</strong> ' + dashNum(d.coords_count) + ' registros, ' + dashNum(d.source_points) + ' puntos fuente, grilla ' + (d.grid_size || '') + fallbackTxt + '</div>';
        html += '<div class="dash-card-sub">Hotspots: percentil 90 = ' + ((d.threshold_p90 || 0) * 100).toFixed(1) + '% | tipo=' + (d.type || '') + '</div>';
        if (d.warning) html += '<div class="dash-meta" style="margin:6px 0;">' + d.warning + '</div>';
        if (d.hotspots && d.hotspots.length) {
            html += '<div class="mapa-hotspots"><table class="data-table"><tr><th>#</th><th>Lat</th><th>Lng</th><th>Densidad</th></tr>';
            d.hotspots.slice(0, 8).forEach(function(h) {
                html += '<tr><td>' + h.rank + '</td><td>' + h.latitud + '</td><td>' + h.longitud + '</td><td>' + ((h.densidad || 0) * 100).toFixed(1) + '%</td></tr>';
            });
            html += '</table></div>';
        }
        infoEl.innerHTML = html;
        toast('KDE generado - ' + d.coords_count + ' puntos', 'info');
    } catch (e) { infoEl.textContent = 'Error: ' + e.message; }
}

// ==================== DASHBOARDS ====================
var dashCharts = {};
var dashReloadTimer = null;

function dashRecargar() {
    clearTimeout(dashReloadTimer);
    dashReloadTimer = setTimeout(function() {
        var actual = document.querySelector('.dash-btn.active');
        if (actual) dashCambiar(actual.dataset.dash);
    }, 250);
}

function dashCambiar(vista) {
    document.querySelectorAll('.dash-btn').forEach(function(b) { b.classList.remove('active'); });
    document.querySelector('.dash-btn[data-dash="' + vista + '"]').classList.add('active');
    // Destroy old charts
    Object.keys(dashCharts).forEach(function(k) { if (dashCharts[k]) { dashCharts[k].destroy(); delete dashCharts[k]; } });
    dashCharts = {};
    if (vista === 'resumen') dashResumen();
    else if (vista === 'iras-edas') dashIRASEDAS();
    else if (vista === 'vacunacion') dashVacunacion();
    else if (vista === 'cred') dashCRED();
    else if (vista === 'suplementacion') dashSuplementacion();
    else if (vista === 'materno') dashMaterno();
    else if (vista === 'poblacion') dashPoblacion();
}

function dashCard(label, value, color, sub) {
    return '<div class="dash-card" style="border-left:4px solid ' + color + ';"><div class="dash-card-label">' + label + '</div><div class="dash-card-value">' + value + '</div>' + (sub ? '<div class="dash-card-sub">' + sub + '</div>' : '') + '</div>';
}

function dashChartContainer(title, id, type) {
    return '<div class="dash-chart-box"><h4>' + title + '</h4><div class="dash-chart-wrap"><canvas id="' + id + '"></canvas></div></div>';
}

function dashTable(id) {
    return '<div class="dash-table-wrap" id="' + id + '"></div>';
}

function dashNum(v) {
    return (Number(v) || 0).toLocaleString();
}

function dashPct(part, total) {
    part = Number(part) || 0;
    total = Number(total) || 0;
    return total ? ((part * 100 / total).toFixed(1) + '%') : '0%';
}

function dashSemaforoBadge(valor) {
    var cls = 'sin-dato';
    var txt = 'Sin dato';
    if (valor === 'verde') { cls = 'verde'; txt = 'Verde'; }
    else if (valor === 'amarillo') { cls = 'amarillo'; txt = 'Amarillo'; }
    else if (valor === 'rojo') { cls = 'rojo'; txt = 'Rojo'; }
    return '<span class="semaforo-badge ' + cls + '">' + txt + '</span>';
}

function dashMeta(meta) {
    if (!meta) return '';
    var txt = 'Tabla: ' + (meta.tabla || (meta.tablas || []).join(', ')) + ' | datos ' + (meta.anio_datos || '') + ' | solicitado ' + (meta.anio_solicitado || '');
    if (meta.fallback) txt += ' | FALLBACK';
    return '<div class="dash-meta">' + txt + '</div>';
}

function dashFallbackBanner(meta) {
    if (!meta || !meta.fallback) return '';
    var anioReq = meta.anio_solicitado || '';
    var anioDat = meta.anio_datos || '';
    return '<div class="dash-fallback-banner">⚠️ Mostrando datos de <strong>' + anioDat + '</strong> (solicitaste <strong>' + anioReq + '</strong>). ' +
        'No hay tablas agregadas para ' + anioReq + ' en BD. ' +
        '<a href="#" onclick="dashCheckYear(\'' + anioReq + '\');return false;">🔍 Diagnosticar</a> | ' +
        '<span style="cursor:help;" title="Ejecuta Reportes → Ejecutar Scripts → selecciona año ' + anioReq + ' (ingesta + tablas agregadas)">❓ ¿Cómo generar?</span></div>';
}

async function dashCheckYear(anio) {
    try {
        const r = await fetch('/api/dashboards/check-year?anio=' + anio);
        const d = await r.json();
        if (d.error) { toast('Error: ' + d.error, 'error'); return; }
        var c = d.checks || {};
        var html = '<div style="font-size:11px;line-height:1.6;text-align:left;">';
        html += '<b>🔍 Diagnóstico año ' + anio + '</b><br><br>';
        html += '<table style="width:100%;border-collapse:collapse;">';
        html += '<tr style="border-bottom:1px solid var(--border);"><th style="text-align:left;padding:2px 4px;">Tabla</th><th style="text-align:center;padding:2px 4px;">Existe</th><th style="text-align:center;padding:2px 4px;">Reg.</th></tr>';
        for (var k in c) {
            var v = c[k];
            if (typeof v === 'object') {
                html += '<tr><td style="padding:2px 4px;">' + k + '</td><td style="text-align:center;">' + (v.exists ? '✅' : '❌') + '</td><td style="text-align:center;">' + (v.count||0) + '</td></tr>';
            }
        }
        html += '</table>';
        html += '<br><i style="color:var(--text-muted);font-size:11px;">👉 Para ' + anio + ': ejecuta primero "Ingesta de datos" (módulo Reportes) y luego "Generar tablas agregadas".</i>';
        html += '</div>';
        toast(html, 'info');
    } catch (e) {
        toast('Error: ' + e.message, 'error');
    }
}

function dashCoverageTable(rows, title) {
    rows = rows || [];
    if (!rows.length) return '';
    var html = '<div class="dash-table-wrap"><h4>' + (title || 'Cobertura') + '</h4><table class="data-table"><tr><th>Indicador</th><th>Avance</th><th>Denominador</th><th>%</th><th>Meta</th><th>Semáforo</th></tr>';
    rows.forEach(function(r) {
        html += '<tr><td>' + (r.nombre || '') + '<div class="dash-card-sub">' + (r.metodo || '') + '</div></td><td>' + dashNum(r.numerador) + '</td><td>' + dashNum(r.denominador) + '<div class="dash-card-sub">' + (r.denominador_nombre || '') + '</div></td><td>' + (r.porcentaje == null ? 'S/D' : r.porcentaje.toFixed(1) + '%') + '</td><td>' + (r.meta || 95) + '%</td><td>' + dashSemaforoBadge(r.semaforo) + '</td></tr>';
    });
    html += '</table></div>';
    return html;
}

function dashChartTheme() {
    var st = getComputedStyle(document.documentElement);
    return {
        text: (st.getPropertyValue('--text-secondary') || '#ccc').trim(),
        muted: (st.getPropertyValue('--text-muted') || '#999').trim(),
        grid: (st.getPropertyValue('--border') || '#333').trim()
    };
}

function makeChart(id, type, labels, datasets, opts) {
    var ctx = document.getElementById(id);
    if (!ctx) return null;
    var theme = dashChartTheme();
    var baseOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { labels: { color: theme.text, font: { size: 11 } } } },
        scales: type !== 'pie' && type !== 'doughnut' ? {
            x: { ticks: { color: theme.muted, font: { size: 10 } }, grid: { color: theme.grid } },
            y: { beginAtZero: true, ticks: { color: theme.muted, font: { size: 10 } }, grid: { color: theme.grid } }
        } : {}
    };
    var userOptions = opts || {};
    if (userOptions.plugins) {
        userOptions = Object.assign({}, userOptions, {
            plugins: Object.assign({}, baseOptions.plugins, userOptions.plugins, {
                legend: Object.assign({}, baseOptions.plugins.legend, userOptions.plugins.legend || {})
            })
        });
    }
    var cfg = {
        type: type, data: { labels: labels, datasets: datasets },
        options: Object.assign({}, baseOptions, userOptions)
    };
    var chart = new Chart(ctx, cfg);
    dashCharts[id] = chart;
    return chart;
}

// ---------- Resumen ----------
async function dashResumen() {
    document.getElementById('dash-title').textContent = '📊 Resumen General del Sistema';
    var el = document.getElementById('dash-contenido');
    el.innerHTML = '<p style="color:var(--text-muted);">Cargando...</p>';
    try {
        const r = await fetch('/api/dashboards/resumen');
        const d = await r.json();
        var labels = { 'Padron Nominal': '👶 Padr\u00f3n Nominal', 'CNV': '📋 CNV', 'Vacunas': '💉 Vacunas', 'Materno': '🤱 Materno', 'IRAS/EDAS': '🤒 IRAS/EDAS' };
        var colors = { 'Padron Nominal': '#3498DB', 'CNV': '#9B59B6', 'Vacunas': '#2ECC71', 'Materno': '#F39C12', 'IRAS/EDAS': '#E74C3C' };
        var html = '<div class="dash-cards">';
        Object.keys(d).forEach(function(k) {
            var count = d[k];
            html += dashCard(labels[k]||k, count < 0 ? 'No disponible' : count.toLocaleString(), colors[k]||'#555');
        });
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Registros por tabla', 'chart-resumen', 'bar');
        html += '</div>';
        html += '<div style="margin-top:12px;display:flex;gap:8px;flex-wrap:wrap;">';
        html += '<button class="sidebar-btn" style="background:#2ECC71;color:#fff;width:auto;" onclick="dashCambiar(\'iras-edas\')">🤒 IRAS/EDAS</button>';
        html += '<button class="sidebar-btn" style="background:#3498DB;color:#fff;width:auto;" onclick="dashCambiar(\'vacunacion\')">💉 Vacunaci\u00f3n</button>';
        html += '<button class="sidebar-btn" style="background:#F39C12;color:#fff;width:auto;" onclick="dashCambiar(\'cred\')">📏 CRED</button>';
        html += '</div>';
        el.innerHTML = html;
        document.getElementById('dash-status-text').textContent = '✅ Resumen cargado';
        document.getElementById('dash-status-dot').className = 'status-dot ok';
        setTimeout(function() {
            makeChart('chart-resumen', 'bar',
                Object.keys(d).map(function(k) { return labels[k]||k; }),
                [{ label: 'Registros', data: Object.values(d).map(function(v) { return v < 0 ? 0 : v; }), backgroundColor: Object.values(colors) }],
                { plugins: { legend: { display: false } } }
            );
        }, 100);
    } catch (e) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>'; }
}

// ---------- IRAS/EDAS ----------
async function dashIRASEDAS() {
    document.getElementById('dash-title').textContent = '🤒 Dashboard IRAS/EDAS';
    var el = document.getElementById('dash-contenido');
    el.innerHTML = '<p style="color:var(--text-muted);">Cargando...</p>';
    var anio = document.getElementById('dash-anio').value;
    var microred = document.getElementById('dash-microred').value;
    try {
        const r = await fetch('/api/dashboards/iras-edas?anio=' + anio + '&microred=' + encodeURIComponent(microred));
        const d = await r.json();
        if (d.error) { el.innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        var s = d.summary;
        var html = '<div class="dash-cards">';
        html += dashCard('Total IRA', s.total_ira.toLocaleString(), '#E74C3C');
        html += dashCard('Total EDA', s.total_eda.toLocaleString(), '#F39C12');
        html += dashCard('Neumonías', s.total_neumonia.toLocaleString(), '#C0392B');
        html += '</div>' + dashMeta(d.meta) + dashFallbackBanner(d.meta) + '<div class="dash-charts-row">';
        html += dashChartContainer('Tendencia Mensual', 'chart-iras-mensual', 'line');
        html += dashChartContainer('Top Establecimientos', 'chart-iras-top', 'bar');
        html += '</div>';
        html += dashTable('tabla-iras-est');
        el.innerHTML = html;

        // Monthly trend
        var meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
        var labels = d.monthly.map(function(m) { return meses[m.mes-1]||m.mes; });
        makeChart('chart-iras-mensual', 'line', labels, [
            { label: 'Total IRA', data: d.monthly.map(function(m){return m.total_ira || 0;}), borderColor: '#E74C3C', backgroundColor: 'transparent', tension: 0.3 },
            { label: 'Total EDA', data: d.monthly.map(function(m){return m.total_eda || 0;}), borderColor: '#F39C12', backgroundColor: 'transparent', tension: 0.3 },
            { label: 'Neumonía', data: d.monthly.map(function(m){return m.neumonia || 0;}), borderColor: '#C0392B', backgroundColor: 'transparent', tension: 0.3 },
            { label: 'SOB/Asma', data: d.monthly.map(function(m){return m.sob_asma || 0;}), borderColor: '#8E44AD', backgroundColor: 'transparent', tension: 0.3 },
        ], { scales: { y: { beginAtZero: true } } });

        // Top establishments
        var topE = d.top_establecimientos;
        makeChart('chart-iras-top', 'bar', topE.map(function(e){return e.nombre ? e.nombre.substring(0,25) : '?';}), [
            { label: 'IRA', data: topE.map(function(e){return e.total_ira;}), backgroundColor: '#E74C3C' },
            { label: 'EDA', data: topE.map(function(e){return e.total_eda;}), backgroundColor: '#F39C12' },
        ]);

        // Table
        var tbl = '<table class="data-table"><tr><th>Establecimiento</th><th>IRA</th><th>EDA</th><th>Total</th></tr>';
        topE.forEach(function(e) {
            tbl += '<tr><td>' + (e.nombre||'') + '</td><td>' + (e.total_ira||0).toLocaleString() + '</td><td>' + (e.total_eda||0).toLocaleString() + '</td><td>' + ((e.total_ira||0)+(e.total_eda||0)).toLocaleString() + '</td></tr>';
        });
        tbl += '</table>';
        document.getElementById('tabla-iras-est').innerHTML = tbl;
    } catch (e) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>'; }
}

// ---------- Vacunación ----------
async function dashVacunacion() {
    document.getElementById('dash-title').textContent = '💉 Dashboard Vacunación';
    var el = document.getElementById('dash-contenido');
    el.innerHTML = '<p style="color:var(--text-muted);">Cargando...</p>';
    var anio = document.getElementById('dash-anio').value;
    var microred = document.getElementById('dash-microred').value;
    try {
        const r = await fetch('/api/dashboards/vacunacion?anio=' + anio + '&microred=' + encodeURIComponent(microred));
        const d = await r.json();
        if (d.error) { el.innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        var vs = d.vaccine_summary;

        var html = '<div class="dash-cards">';
        var vacColors = { 'BCG':'#3498DB','HVB':'#2ECC71','Rotavirus':'#E74C3C','Neumococo':'#F39C12','APO':'#9B59B6','SPR':'#1ABC9C','DPT':'#E67E22','Influenza':'#2980B9','Varicela':'#16A085','Fiebre_Amarilla':'#D35400','Hepatitis_A':'#8E44AD' };
        Object.keys(vs).forEach(function(k) {
            html += dashCard('💉 ' + k, vs[k].toLocaleString(), vacColors[k]||'#555');
        });
        html += '</div>' + dashMeta(d.meta) + dashFallbackBanner(d.meta) + dashCoverageTable(d.coverage_summary, 'Semáforo de cobertura estimada') + '<div class="dash-charts-row">';
        html += dashChartContainer('Dosis por Vacuna', 'chart-vac-dosis', 'bar');
        html += dashChartContainer('Tendencia Mensual', 'chart-vac-trend', 'line');
        html += '</div>';
        html += dashChartContainer('Cobertura por Establecimiento (Top 15)', 'chart-vac-est', 'bar');
        html += dashTable('tabla-vac-est');
        el.innerHTML = html;

        // Vaccine doses bar chart
        var vacNames = Object.keys(vs);
        makeChart('chart-vac-dosis', 'bar', vacNames, [
            { label: 'Dosis aplicadas', data: vacNames.map(function(k){return vs[k];}), backgroundColor: vacNames.map(function(k){return vacColors[k]||'#555';}) }
        ], { plugins: { legend: { display: false } }, indexAxis: 'y' });

        // Monthly trend - group by vaccine types
        var trend = d.monthly_trend;
        var meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
        if (trend && trend.length > 0) {
            var labels = trend.map(function(m){return meses[m.mes-1]||m.mes;});
            var ds = [];
            var keyOrder = ['BCG','Rotavirus','Neumococo','SPR','DPT','Influenza'];
            keyOrder.forEach(function(k) {
                var hasData = trend.some(function(m){return m[k];});
                if (hasData) ds.push({ label: k, data: trend.map(function(m){return m[k]||0;}), borderColor: vacColors[k]||'#555', backgroundColor: 'transparent', tension: 0.3 });
            });
            makeChart('chart-vac-trend', 'line', labels, ds, {});
        }

        // By establishment
        var est = d.by_establecimiento;
        if (est && est.length > 0) {
            makeChart('chart-vac-est', 'bar',
                est.map(function(e){return e.nombre ? e.nombre.substring(0,20) : '?';}),
                [{ label: 'Dosis totales', data: est.map(function(e){return e.total;}), backgroundColor: '#3498DB' }],
                { plugins: { legend: { display: false } }, indexAxis: 'y' }
            );
            var tblVac = '<table class="data-table"><tr><th>Establecimiento</th><th>Dosis totales</th></tr>';
            est.forEach(function(e) { tblVac += '<tr><td>' + (e.nombre || '') + '</td><td>' + dashNum(e.total) + '</td></tr>'; });
            tblVac += '</table>';
            document.getElementById('tabla-vac-est').innerHTML = tblVac;
        }
    } catch (e) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>'; }
}

// ---------- CRED ----------
async function dashCRED() {
    document.getElementById('dash-title').textContent = '📏 Dashboard CRED';
    var el = document.getElementById('dash-contenido');
    el.innerHTML = '<p style="color:var(--text-muted);">Cargando...</p>';
    var anio = document.getElementById('dash-anio').value;
    try {
        const r = await fetch('/api/dashboards/cred?anio=' + anio);
        const d = await r.json();
        if (d.error) { el.innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        var n = d.nutritional, s = d.suplementacion, dv = d.desarrollo, hb = d.hemoglobina, cc = d.cumplimiento_cred || {};

        var html = '<div class="dash-cards">';
        html += dashCard('CRED al día estimado', dashNum(cc.al_dia_estimado), '#2ECC71', (cc.porcentaje == null ? 'S/D' : cc.porcentaje + '%') + ' ' + dashSemaforoBadge(cc.semaforo));
        html += dashCard('Atraso estimado', dashNum(cc.atrasado_estimado), '#E74C3C', 'contra padrón referencia');
        html += dashCard('🥩 Desnutrición Aguda', n.desnutric_aguda.toLocaleString(), '#E74C3C');
        html += dashCard('🥩 Desnutrición Crónica', n.desnutric_cronica.toLocaleString(), '#C0392B');
        html += dashCard('⚠ Sobrepeso', n.sobre_peso.toLocaleString(), '#F39C12');
        html += dashCard('⚠ Obesidad', n.obeso.toLocaleString(), '#E67E22');
        html += '</div>' + dashMeta(d.meta) + dashFallbackBanner(d.meta) + dashCoverageTable(d.coverage, 'Semáforos CRED estimados') + '<div class="dash-charts-row">';
        html += dashChartContainer('Estado Nutricional', 'chart-cred-nut', 'doughnut');
        html += dashChartContainer('Suplementación', 'chart-cred-sup', 'bar');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Retrasos del Desarrollo', 'chart-cred-dev', 'bar');
        html += dashChartContainer('Hemoglobina por Grupo', 'chart-cred-hb', 'bar');
        html += '</div>';
        el.innerHTML = html;

        // Nutritional pie
        var nutLabels = ['Desnut. Aguda','Desnut. Crónica','Desnut. Global','Desnut. Severa','Sobrepeso','Obesidad'];
        var nutData = [n.desnutric_aguda, n.desnutric_cronica, n.desnutric_global, n.desnutric_severa, n.sobre_peso, n.obeso];
        makeChart('chart-cred-nut', 'doughnut', nutLabels, [
            { data: nutData, backgroundColor: ['#E74C3C','#C0392B','#8E44AD','#2C3E50','#F39C12','#E67E22'] }
        ], { plugins: { legend: { position: 'right' } } });

        // Supplementation bar
        makeChart('chart-cred-sup', 'bar', ['Gestantes','Puerperas','MEF','Niños'],
            [{ label: 'Suplementación', data: [s.gestantes, s.puerperas, s.mef, s.ninos], backgroundColor: ['#9B59B6','#8E44AD','#3498DB','#2ECC71'] }],
            { plugins: { legend: { display: false } } }
        );

        // Development bar
        makeChart('chart-cred-dev', 'bar', ['Lenguaje','Motor','Social','Coordinación','Cognitivo'],
            [{ label: 'Casos con retraso', data: [dv.lenguaje, dv.motor, dv.social, dv.coordinacion, dv.cognitivo], backgroundColor: '#E74C3C' }],
            { plugins: { legend: { display: false } } }
        );

        // Hemoglobin bar
        makeChart('chart-cred-hb', 'bar', ['6-11m','12-23m','24-35m','Gestante'],
            [{ label: 'Dosajes Hb', data: [hb.hb_6_11m, hb.hb_12_23m, hb.hb_24_35m, hb.hb_gestante], backgroundColor: '#E74C3C' }],
            { plugins: { legend: { display: false } } }
        );
    } catch (e) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>'; }
}

// ---------- Suplementación DL1153 ----------
async function dashSuplementacion() {
    document.getElementById('dash-title').textContent = '💊 DL1153 - Suplementación de Hierro';
    var el = document.getElementById('dash-contenido');
    el.innerHTML = '<p style="color:var(--text-muted);">Cargando...</p>';
    var anio = document.getElementById('dash-anio').value;
    try {
        const r = await fetch('/api/dashboards/suplementacion?anio=' + anio);
        const d = await r.json();
        if (d.error) { el.innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        var sm = d.summary || {};
        var html = '<div class="dash-cards">';
        html += dashCard('Suplementación niños', dashNum(sm.ninos), '#2ECC71', 'Padrón ref: ' + dashNum(sm.padron_ref));
        html += dashCard('Suplementación gestantes', dashNum(sm.gestantes), '#9B59B6', 'Gestantes ref: ' + dashNum(sm.gestantes_ref));
        html += '</div>' + dashMeta(d.meta) + dashFallbackBanner(d.meta) + dashCoverageTable(d.coverage, 'Semáforos DL1153 estimados') + '<div class="dash-charts-row">';
        html += dashChartContainer('Tendencia Mensual', 'chart-sup-trend', 'line');
        html += dashChartContainer('Por Establecimiento (Top 15)', 'chart-sup-est', 'bar');
        html += '</div>';
        html += dashTable('tabla-sup-est');
        el.innerHTML = html;

        var meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
        var monthly = d.monthly;
        if (monthly && monthly.length > 0) {
            makeChart('chart-sup-trend', 'line', monthly.map(function(m){return meses[m.mes-1]||m.mes;}), [
                { label: 'Gestantes', data: monthly.map(function(m){return m.gestantes;}), borderColor: '#9B59B6', backgroundColor: 'transparent', tension: 0.3 },
                { label: 'Niños <36m', data: monthly.map(function(m){return m.ninos;}), borderColor: '#2ECC71', backgroundColor: 'transparent', tension: 0.3 },
            ]);
        }

        var est = d.by_establecimiento;
        if (est && est.length > 0) {
            makeChart('chart-sup-est', 'bar',
                est.map(function(e){return e.nombre ? e.nombre.substring(0,20) : '?';}),
                [
                    { label: 'Gestantes', data: est.map(function(e){return e.gestantes;}), backgroundColor: '#9B59B6' },
                    { label: 'Niños', data: est.map(function(e){return e.ninos;}), backgroundColor: '#2ECC71' },
                ],
                { indexAxis: 'y' }
            );
        }

        var tbl = '<table class="data-table"><tr><th>Establecimiento</th><th>Gestantes</th><th>Puerperas</th><th>MEF</th><th>Niños</th></tr>';
        (est||[]).forEach(function(e) {
            tbl += '<tr><td>' + (e.nombre||'') + '</td><td>' + (e.gestantes||0).toLocaleString() + '</td><td>' + (e.puerperas||0).toLocaleString() + '</td><td>' + (e.mef||0).toLocaleString() + '</td><td>' + (e.ninos||0).toLocaleString() + '</td></tr>';
        });
        tbl += '</table>';
        document.getElementById('tabla-sup-est').innerHTML = tbl;
    } catch (e) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>'; }
}

// ---------- Materno ----------
async function dashMaterno() {
    document.getElementById('dash-title').textContent = '🤱 Dashboard Materno';
    var el = document.getElementById('dash-contenido');
    el.innerHTML = '<p style="color:var(--text-muted);">Cargando...</p>';
    var anio = document.getElementById('dash-anio').value;
    var microred = document.getElementById('dash-microred').value;
    try {
        const r = await fetch('/api/dashboards/materno?anio=' + anio + '&microred=' + encodeURIComponent(microred));
        const d = await r.json();
        if (d.error) { el.innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        var s = d.summary;
        var html = '<div class="dash-cards">';
        html += dashCard('Atenciones', dashNum(s.total_atenciones), '#E67E22');
        html += dashCard('Pacientes', dashNum(s.pacientes), '#D35400');
        html += dashCard('Establecimientos', dashNum(s.establecimientos), '#F39C12');
        html += dashCard('Distritos', dashNum(s.distritos), '#1ABC9C');
        html += dashCard('Edad promedio', (s.edad_promedio || 0) + ' años', '#9B59B6');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Tendencia Mensual', 'chart-mat-trend', 'line');
        html += dashChartContainer('Top Establecimientos', 'chart-mat-est', 'bar');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Atenciones por Distrito', 'chart-mat-dist', 'bar');
        html += dashChartContainer('Edad de Pacientes/Gestantes', 'chart-mat-edad', 'doughnut');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Tipo de Diagnóstico', 'chart-mat-tipo', 'bar');
        html += dashChartContainer('Códigos HIS más Frecuentes', 'chart-mat-codigo', 'bar');
        html += '</div>';
        html += dashTable('tabla-mat-est');
        html += dashTable('tabla-mat-codigo');
        el.innerHTML = html;

        var meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
        if (d.monthly && d.monthly.length > 0) {
            makeChart('chart-mat-trend', 'line', d.monthly.map(function(m){return meses[m.mes-1]||m.mes;}), [
                { label: 'Atenciones', data: d.monthly.map(function(m){return m.total;}), borderColor: '#E67E22', backgroundColor: 'transparent', tension: 0.3, fill: true }
            ]);
        }

        if (d.by_establecimiento && d.by_establecimiento.length > 0) {
            makeChart('chart-mat-est', 'bar',
                d.by_establecimiento.map(function(e){return e.nombre ? e.nombre.substring(0,20) : '?';}),
                [{ label: 'Atenciones', data: d.by_establecimiento.map(function(e){return e.total;}), backgroundColor: '#E67E22' }],
                { plugins: { legend: { display: false } }, indexAxis: 'y' }
            );
        }

        if (d.by_distrito && d.by_distrito.length > 0) {
            makeChart('chart-mat-dist', 'bar',
                d.by_distrito.map(function(x){return x.distrito ? x.distrito.substring(0,22) : '?';}),
                [{ label: 'Atenciones', data: d.by_distrito.map(function(x){return x.total;}), backgroundColor: '#1ABC9C' }],
                { plugins: { legend: { display: false } }, indexAxis: 'y' }
            );
        }

        if (d.by_edad && d.by_edad.length > 0) {
            makeChart('chart-mat-edad', 'doughnut',
                d.by_edad.map(function(x){return x.grupo;}),
                [{ data: d.by_edad.map(function(x){return x.total;}), backgroundColor: ['#95A5A6','#E74C3C','#2ECC71','#F39C12','#9B59B6','#34495E'] }],
                { plugins: { legend: { position: 'right' } } }
            );
        }

        if (d.by_tipo_diagnostico && d.by_tipo_diagnostico.length > 0) {
            makeChart('chart-mat-tipo', 'bar',
                d.by_tipo_diagnostico.map(function(x){return x.tipo || 'Sin dato';}),
                [{ label: 'Atenciones', data: d.by_tipo_diagnostico.map(function(x){return x.total;}), backgroundColor: '#9B59B6' }],
                { plugins: { legend: { display: false } } }
            );
        }

        if (d.by_codigo && d.by_codigo.length > 0) {
            makeChart('chart-mat-codigo', 'bar',
                d.by_codigo.map(function(x){return x.codigo || '?';}),
                [{ label: 'Atenciones', data: d.by_codigo.map(function(x){return x.total;}), backgroundColor: '#E67E22' }],
                { plugins: { legend: { display: false } }, indexAxis: 'y' }
            );
        }

        var tbl = '<table class="data-table"><tr><th>Establecimiento</th><th>Atenciones</th></tr>';
        (d.by_establecimiento||[]).forEach(function(e) {
            tbl += '<tr><td>' + (e.nombre||'') + '</td><td>' + dashNum(e.total) + '</td></tr>';
        });
        tbl += '</table>';
        document.getElementById('tabla-mat-est').innerHTML = tbl;

        var codTbl = '<table class="data-table"><tr><th>Código HIS</th><th>Atenciones</th><th>Pacientes</th></tr>';
        (d.by_codigo||[]).forEach(function(e) {
            codTbl += '<tr><td>' + (e.codigo||'') + '</td><td>' + dashNum(e.total) + '</td><td>' + dashNum(e.pacientes) + '</td></tr>';
        });
        codTbl += '</table>';
        document.getElementById('tabla-mat-codigo').innerHTML = codTbl;
    } catch (e) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>'; }
}

// ---------- Población ----------
async function dashPoblacion() {
    document.getElementById('dash-title').textContent = '👥 Dashboard Población';
    var el = document.getElementById('dash-contenido');
    el.innerHTML = '<p style="color:var(--text-muted);">Cargando...</p>';
    var anio = document.getElementById('dash-anio').value;
    try {
        const r = await fetch('/api/dashboards/poblacion?anio=' + anio);
        const d = await r.json();
        if (d.error) { el.innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        var c = d.completitud || {};
        var cnv = (d.cnv && d.cnv.summary) ? d.cnv.summary : {};
        var html = '<div class="dash-cards">';
        html += dashCard('Total Padrón', dashNum(d.total), '#1ABC9C');
        html += dashCard('Con coordenadas', dashNum(c.con_coord), '#3498DB', dashPct(c.con_coord, d.total));
        html += dashCard('Visitados', dashNum(c.visitados), '#2ECC71', dashPct(c.visitados, d.total));
        html += dashCard('Con celular', dashNum(c.con_celular), '#9B59B6', dashPct(c.con_celular, d.total));
        html += dashCard('CNV ' + anio, dashNum(cnv.total), '#E67E22');
        html += dashCard('Bajo peso', dashNum(cnv.bajo_peso), '#E74C3C', dashPct(cnv.bajo_peso, cnv.total));
        html += dashCard('Prematuros', dashNum(cnv.prematuros), '#C0392B', dashPct(cnv.prematuros, cnv.total));
        html += dashCard('Cesáreas', dashNum(cnv.cesareas), '#F39C12', dashPct(cnv.cesareas, cnv.total));
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Distribución por Edad', 'chart-pob-edad', 'doughnut');
        html += dashChartContainer('Porcentaje por Género', 'chart-pob-gen', 'pie');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Población por Distrito', 'chart-pob-dist', 'bar');
        html += dashChartContainer('Completitud del Padrón', 'chart-pob-comp', 'bar');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('Top EESS del Padrón', 'chart-pob-eess', 'bar');
        html += dashChartContainer('Nacimientos CNV por Mes', 'chart-cnv-month', 'line');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('CNV por Peso al Nacer', 'chart-cnv-peso', 'doughnut');
        html += dashChartContainer('CNV por Edad de Madre', 'chart-cnv-edad', 'bar');
        html += '</div><div class="dash-charts-row">';
        html += dashChartContainer('CNV por Distrito Madre', 'chart-cnv-dist', 'bar');
        html += dashChartContainer('CNV por Sexo', 'chart-cnv-sexo', 'pie');
        html += '</div>';
        html += dashTable('tabla-pob-dist');
        html += dashTable('tabla-cnv-eess');
        el.innerHTML = html;

        var edad = d.by_edad;
        makeChart('chart-pob-edad', 'doughnut',
            Object.keys(edad).filter(function(k){return k !== 'sin_dato' && edad[k] > 0;}), [
            { data: Object.keys(edad).filter(function(k){return k !== 'sin_dato' && edad[k] > 0;}).map(function(k){return edad[k];}), backgroundColor: ['#3498DB','#2ECC71','#F39C12','#E74C3C','#95A5A6'] }
        ], { plugins: { legend: { position: 'right' } } });

        if (d.by_genero && d.by_genero.length > 0) {
            makeChart('chart-pob-gen', 'pie',
                d.by_genero.map(function(g){return g.genero||'?';}), [
                { data: d.by_genero.map(function(g){return g.total;}), backgroundColor: ['#3498DB','#E74C3C','#95A5A6'] }
            ], { plugins: { legend: { position: 'right' } } });
        }

        if (d.by_distrito && d.by_distrito.length > 0) {
            var topDist = d.by_distrito.slice(0, 20);
            makeChart('chart-pob-dist', 'bar',
                topDist.map(function(dd){return dd.distrito||'?';}), [
                { label: 'Población', data: topDist.map(function(dd){return dd.total;}), backgroundColor: '#1ABC9C' }
            ], { plugins: { legend: { display: false } }, indexAxis: 'y' });

            var tbl = '<table class="data-table"><tr><th>Distrito</th><th>Total</th><th>Con Coordenadas</th></tr>';
            (d.by_distrito||[]).forEach(function(dd) {
                tbl += '<tr><td>' + (dd.distrito||'') + '</td><td>' + dashNum(dd.total) + '</td><td>' + dashNum(dd.con_coord) + '</td></tr>';
            });
            tbl += '</table>';
            document.getElementById('tabla-pob-dist').innerHTML = tbl;
        }

        makeChart('chart-pob-comp', 'bar', ['Coordenadas','Celular','Dirección','EESS','Seguro','Visitados'], [
            { label: 'Registros', data: [c.con_coord||0, c.con_celular||0, c.con_direccion||0, c.con_eess||0, c.con_seguro||0, c.visitados||0], backgroundColor: ['#3498DB','#9B59B6','#F39C12','#1ABC9C','#2ECC71','#E67E22'] }
        ], { plugins: { legend: { display: false } }, indexAxis: 'y' });

        if (d.by_eess && d.by_eess.length > 0) {
            makeChart('chart-pob-eess', 'bar',
                d.by_eess.map(function(e){return e.nombre ? e.nombre.substring(0,22) : '?';}),
                [{ label: 'Niños', data: d.by_eess.map(function(e){return e.total;}), backgroundColor: '#1ABC9C' }],
                { plugins: { legend: { display: false } }, indexAxis: 'y' }
            );
        }

        var meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
        var cnvMonthly = (d.cnv && d.cnv.monthly) ? d.cnv.monthly : [];
        if (cnvMonthly.length > 0) {
            makeChart('chart-cnv-month', 'line', cnvMonthly.map(function(m){return meses[m.mes-1]||m.mes;}), [
                { label: 'Nacimientos', data: cnvMonthly.map(function(m){return m.total;}), borderColor: '#E67E22', backgroundColor: 'transparent', tension: 0.3 },
                { label: 'Bajo peso', data: cnvMonthly.map(function(m){return m.bajo_peso;}), borderColor: '#E74C3C', backgroundColor: 'transparent', tension: 0.3 }
            ]);
        }

        var cnvPeso = (d.cnv && d.cnv.by_peso) ? d.cnv.by_peso : [];
        if (cnvPeso.length > 0) {
            makeChart('chart-cnv-peso', 'doughnut', cnvPeso.map(function(x){return x.grupo;}), [
                { data: cnvPeso.map(function(x){return x.total;}), backgroundColor: ['#C0392B','#E74C3C','#2ECC71','#F39C12','#95A5A6'] }
            ], { plugins: { legend: { position: 'right' } } });
        }

        var cnvEdad = (d.cnv && d.cnv.by_edad_madre) ? d.cnv.by_edad_madre : [];
        if (cnvEdad.length > 0) {
            makeChart('chart-cnv-edad', 'bar', cnvEdad.map(function(x){return x.grupo;}), [
                { label: 'Madres', data: cnvEdad.map(function(x){return x.total;}), backgroundColor: '#9B59B6' }
            ], { plugins: { legend: { display: false } } });
        }

        var cnvDist = (d.cnv && d.cnv.by_distrito) ? d.cnv.by_distrito : [];
        if (cnvDist.length > 0) {
            makeChart('chart-cnv-dist', 'bar', cnvDist.map(function(x){return x.distrito ? x.distrito.substring(0,20) : '?';}), [
                { label: 'Nacimientos', data: cnvDist.map(function(x){return x.total;}), backgroundColor: '#E67E22' }
            ], { plugins: { legend: { display: false } }, indexAxis: 'y' });
        }

        var cnvSexo = (d.cnv && d.cnv.by_sexo) ? d.cnv.by_sexo : [];
        if (cnvSexo.length > 0) {
            makeChart('chart-cnv-sexo', 'pie', cnvSexo.map(function(x){return x.sexo;}), [
                { data: cnvSexo.map(function(x){return x.total;}), backgroundColor: ['#3498DB','#E74C3C','#95A5A6'] }
            ], { plugins: { legend: { position: 'right' } } });
        }

        var cnvEess = (d.cnv && d.cnv.by_eess) ? d.cnv.by_eess : [];
        var cnvTbl = '<table class="data-table"><tr><th>EESS CNV</th><th>Nacimientos</th></tr>';
        cnvEess.forEach(function(e) {
            cnvTbl += '<tr><td>' + (e.nombre||'') + '</td><td>' + dashNum(e.total) + '</td></tr>';
        });
        cnvTbl += '</table>';
        document.getElementById('tabla-cnv-eess').innerHTML = cnvTbl;
    } catch (e) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>'; }
}

// ==================== POBLACION TAB SWITCH ====================
function pobSwitchTab(tab) {
    document.querySelectorAll('[data-tab-pob]').forEach(function(b) { b.classList.remove('active'); });
    document.querySelector('[data-tab-pob="' + tab + '"]').classList.add('active');
    document.getElementById('pob-pn-section').style.display = tab === 'pn' ? '' : 'none';
    document.getElementById('pob-cnv-section').style.display = tab === 'cnv' ? '' : 'none';
    document.getElementById('pob-title').textContent = tab === 'pn' ? 'Padr\u00f3n Nominal' : 'CNV';
    document.getElementById('pn-total-info').style.display = tab === 'pn' ? '' : 'none';
    document.getElementById('pn-resultados').style.display = tab === 'pn' ? '' : 'none';
    document.getElementById('cnv-total-info').style.display = tab === 'cnv' ? '' : 'none';
    document.getElementById('cnv-resultados').style.display = tab === 'cnv' ? '' : 'none';
    if (tab === 'pn') { setTimeout(pnStatus, 100); setTimeout(pnConsultar, 300); }
    if (tab === 'cnv') { setTimeout(cnvStatus, 100); setTimeout(cnvConsultar, 300); }
}
// ==================== FORMATOS MINSA ====================
var RM_DATA = null;
var RM_TAB_ACTUAL = 0;

async function rmInit() {
    try {
        const r = await fetch('/api/reportes-minsa/filtros');
        const d = await r.json();
        // Cargar años
        var anioSel = document.getElementById('rm-anio');
        var anios = d.anios_disponibles || ['2024','2025','2026'];
        anioSel.innerHTML = '';
        anios.forEach(function(a) {
            anioSel.innerHTML += '<option>' + a + '</option>';
        });
        // Cargar selects
        ['red','microred','nombre_establecimiento','provincia','distrito'].forEach(function(k) {
            var sel = document.getElementById(k === 'nombre_establecimiento' ? 'rm-establecimiento' : 'rm-' + k);
            var items = d[k] || [];
            if (items.length > 100 && k === 'nombre_establecimiento') items = items.slice(0, 100);
            sel.innerHTML = '<option value="">-- ' + (k.charAt(0).toUpperCase() + k.slice(1).replace('_',' ')) + ' (Todas) --</option>';
            items.forEach(function(v) {
                sel.innerHTML += '<option value="' + v.replace(/"/g,'&quot;') + '">' + v + '</option>';
            });
            if (items.length > 100 && k === 'nombre_establecimiento') {
                sel.innerHTML += '<option value="__mas__">... (+' + (d[k].length - 100) + ' m&aacute;s)</option>';
            }
        });
    } catch (e) {
        toast('Error cargando filtros: ' + e.message, 'error');
    }
}

function rmTipoChange() {
    document.getElementById('rm-resultado').innerHTML = '<p style="color:var(--text-muted);text-align:center;padding:40px;">Tipo cambiado. Presione <b>PROCESAR</b></p>';
    document.getElementById('rm-exportar').disabled = true;
}

function rmGetMeses() {
    var checked = [];
    document.querySelectorAll('#rm-meses input[type=checkbox]:checked').forEach(function(cb) {
        checked.push(parseInt(cb.value));
    });
    return checked;
}

async function rmEjecutar() {
    var btn = document.getElementById('rm-procesar');
    btn.disabled = true;
    btn.textContent = '\u23f3 Procesando...';
    document.getElementById('rm-exportar').disabled = true;
    var tipo = document.getElementById('rm-tipo').value;
    var anio = document.getElementById('rm-anio').value;
    var meses = rmGetMeses();
    if (meses.length === 0) { toast('Seleccione al menos un mes', 'warning'); btn.disabled = false; btn.textContent = '\u25b6 PROCESAR'; return; }
    var body = { tipo: tipo, anio: anio, meses: meses };
    ['red','microred','nombre_establecimiento','provincia','distrito'].forEach(function(k) {
        var v = document.getElementById(k === 'nombre_establecimiento' ? 'rm-establecimiento' : 'rm-' + k).value;
        if (v && v !== '__mas__') body[k] = v;
    });
    try {
        const r = await fetch('/api/reportes-minsa/ejecutar', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(body)
        });
        const d = await r.json();
        if (d.error) { toast('Error: ' + d.error, 'error'); document.getElementById('rm-resultado').innerHTML = '<p style="color:#E74C3C;">' + d.error + '</p>'; return; }
        RM_DATA = d;
        RM_TAB_ACTUAL = 0;
        rmRender(d);
        document.getElementById('rm-exportar').disabled = false;
        toast('Reporte generado', 'success');
    } catch (e) {
        toast('Error: ' + e.message, 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = '\u25b6 PROCESAR';
    }
}

function rmRender(d) {
    var el = document.getElementById('rm-resultado');
    var html = '<div style="margin-bottom:8px;font-size:11px;color:var(--text-muted);">';
    html += 'Reporte: <b>' + d.tipo + '</b> | A&ntilde;o: ' + d.anio + ' | Meses: ' + (d.meses || []).join(', ');
    var f = d.filtros || {};
    if (Object.keys(f).length) html += ' | Filtros: ' + Object.keys(f).map(function(k){return k + '=' + f[k];}).join(', ');
    html += '</div>';

    var paginas = d.paginas || [];
    if (paginas.length > 1) {
        html += '<div class="rm-tabs" style="display:flex;gap:4px;margin-bottom:8px;border-bottom:2px solid var(--border);padding-bottom:4px;">';
        paginas.forEach(function(p, i) {
            var active = i === RM_TAB_ACTUAL ? ' style="background:var(--accent);color:#fff;border-color:var(--accent);"' : '';
            html += '<button class="rm-tab-btn" data-idx="' + i + '"' + active + ' style="padding:4px 12px;border:1px solid var(--border);border-radius:4px;cursor:pointer;background:var(--bg);font-size:11px;' + (i === RM_TAB_ACTUAL ? 'background:var(--accent);color:#fff;border-color:var(--accent);' : '') + '">' + (p.titulo || p.id || 'P\u00e1gina ' + (i+1)) + '</button>';
        });
        html += '</div>';
    }

    // Inject report CSS into <head> (extract from first page's tabla_html)
    if (paginas.length > 0 && paginas[0].tabla_html) {
        var match = paginas[0].tabla_html.match(/<style>([\s\S]*?)<\/style>/);
        if (match) {
            var cssId = 'rm-report-css';
            if (!document.getElementById(cssId)) {
                var s = document.createElement('style');
                s.id = cssId;
                s.textContent = match[1];
                document.head.appendChild(s);
            }
        }
    }

    // Render active page
    var p = paginas[RM_TAB_ACTUAL];
    if (!p) { el.innerHTML = '<p style="color:var(--text-muted);padding:40px;">Sin datos</p>'; return; }
    html += rmRenderPagina(p);
    el.innerHTML = html;

    // Bind tab events
    document.querySelectorAll('.rm-tab-btn').forEach(function(btn) {
        btn.onclick = function() {
            RM_TAB_ACTUAL = parseInt(this.dataset.idx);
            rmRender(RM_DATA);
        };
    });
}

function rmRenderPagina(p) {
    var h = '<div class="rm-pagina">';
    if (p.tabla_html && p.tabla_html.length > 0) {
        // DEBUG: write raw HTML to console
        console.log('tabla_html exists, length=' + p.tabla_html.length + ', startsWith=' + p.tabla_html.substring(0, 50));
        // Render directly without stripping - use as-is
        h += p.tabla_html;
    } else if (p.id === 'formato_nino') {
        var cols = p.columnas || [];
        h += '<div style="overflow-x:auto;"><table class="data-table" style="font-size:10px;width:100%;white-space:nowrap;"><thead><tr>';
        cols.forEach(function(c) { h += '<th style="text-align:center;">' + c + '</th>'; });
        h += '</tr></thead><tbody>';
        (p.filas || []).forEach(function(fila) {
            h += '<tr>';
            cols.forEach(function(c) {
                var v = fila[c];
                if (v != null && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v || '') + '</td>';
            });
            h += '</tr>';
        });
        var totes = p.totales || {};
        h += '<tr style="font-weight:bold;background:var(--accent-light, #f0f4ff);">';
        cols.forEach(function(c) {
            if (c === 'EDADES') { h += '<td style="text-align:center;font-weight:bold;">TOTALES</td>'; }
            else { var v = totes[c]; if (v != null && typeof v === 'number') v = v.toLocaleString(); h += '<td style="text-align:center;font-weight:bold;">' + (v || '0') + '</td>'; }
        });
        h += '</tr></tbody></table></div>';
        // Sub-secciones
        (p.secciones || []).forEach(function(sec) { h += rmRenderSeccion(sec); });
    } else if (p.secciones) {
        p.secciones.forEach(function(sec) { h += rmRenderSeccion(sec); });
    }
    h += '</div>';
    return h;
}

function rmRenderSeccion(sec) {
    var h = '<div class="rm-seccion" style="margin-bottom:12px;"><h3 style="font-size:13px;margin:8px 0 4px;color:var(--accent);">' + (sec.titulo || '') + '</h3>';
    if (sec.tipo === 'side_by_side' && sec.izquierda && sec.derecha) {
        h += '<table style="width:100%;border-collapse:collapse;"><tr>';
        h += '<td style="width:50%;vertical-align:top;padding-right:6px;">' + rmRenderSeccion(sec.izquierda) + '</td>';
        h += '<td style="width:50%;vertical-align:top;padding-left:6px;">' + rmRenderSeccion(sec.derecha) + '</td>';
        h += '</tr></table></div>';
        return h;
    }
    if (sec.tipo === 'grid' && sec.grid) {
        var g = sec.grid;
        h += '<div style="overflow-x:auto;"><table class="data-table" style="font-size:10px;width:auto;white-space:nowrap;"><thead><tr>';
        g.headers.forEach(function(c) { h += '<th style="text-align:center;">' + c + '</th>'; });
        h += '</tr></thead><tbody>';
        g.rows.forEach(function(row) {
            h += '<tr>';
            row.forEach(function(v, i) {
                if (i > 0 && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v || '') + '</td>';
            });
            h += '</tr>';
        });
        if (g.totales) {
            h += '<tr style="font-weight:bold;border-top:2px solid var(--border);">';
            g.totales.forEach(function(v, i) {
                if (i > 0 && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v || '') + '</td>';
            });
            h += '</tr>';
        }
        h += '</tbody></table></div></div>';
        return h;
    }
    if (sec.columnas && sec.filas) {
        h += '<table class="data-table" style="font-size:11px;width:100%;"><thead><tr>';
        sec.columnas.forEach(function(c) { h += '<th style="text-align:center;">' + c + '</th>'; });
        h += '</tr></thead><tbody>';
        sec.filas.forEach(function(item) {
            h += '<tr>';
            sec.columnas.forEach(function(c, ci) {
                var v = null;
                if (item[c] != null) v = item[c];
                else if (item[c.toLowerCase()] != null) v = item[c.toLowerCase()];
                else if (ci === 0) v = item['label'] != null ? item['label'] : item['nombre'] || '';
                else if (ci === 1) v = item['valor'] != null ? item['valor'] : item['total'] || 0;
                if (v != null && typeof v === 'number') v = v.toLocaleString();
                h += '<td style="text-align:center;">' + (v != null ? v : '') + '</td>';
            });
            h += '</tr>';
        });
        var totes = sec.totales || {};
        if (sec.total != null) {
            h += '<tr style="font-weight:bold;border-top:2px solid var(--border);"><td>TOTAL</td><td style="text-align:center;">' + sec.total.toLocaleString() + '</td></tr>';
        } else if (Object.keys(totes).length) {
            h += '<tr style="font-weight:bold;background:var(--accent-light, #f0f4ff);">';
            sec.columnas.forEach(function(c) {
                if (c === sec.columnas[0]) { h += '<td style="text-align:center;">TOTALES</td>'; }
                else { var v = totes[c]; if (v != null && typeof v === 'number') v = v.toLocaleString(); h += '<td style="text-align:center;">' + (v || '0') + '</td>'; }
            });
            h += '</tr>';
        }
        h += '</tbody></table></div>';
    } else if (sec.diagnosticos) {
        sec.diagnosticos.forEach(function(diag) {
            h += '<div style="margin:6px 0 4px 12px;"><b>' + diag.diagnostico + '</b>';
            if (diag.items && diag.items.length) {
                h += '<table class="data-table" style="font-size:10px;width:auto;margin:2px 0 4px;"><thead><tr><th>Edad</th><th>Total</th></tr></thead><tbody>';
                diag.items.forEach(function(item) { h += '<tr><td>' + item.label + '</td><td style="text-align:center;">' + (item.valor != null ? item.valor.toLocaleString() : '') + '</td></tr>'; });
                h += '</tbody></table>';
            }
            h += '<div style="font-size:11px;font-weight:bold;">Total: ' + (diag.total != null ? diag.total.toLocaleString() : '0') + '</div></div>';
        });
    }
    h += '</div>';
    return h;
}

async function rmExportar() {
    if (!RM_DATA) { toast('No hay datos para exportar', 'warning'); return; }
    try {
        const r = await fetch('/api/reportes-minsa/exportar', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({data: RM_DATA})
        });
        if (!r.ok) { toast('Error al exportar', 'error'); return; }
        var blob = await r.blob();
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = 'reporte_minsa.xlsx';
        a.click();
        URL.revokeObjectURL(url);
        toast('Excel descargado', 'success');
    } catch (e) {
        toast('Error: ' + e.message, 'error');
    }
}

// ==================== NAV HOOKS ====================
document.querySelectorAll('.nav-btn[data-module]').forEach(function(b) {
    b.addEventListener('click', function() {
        var m = this.dataset.module;
        if (m === 'poblacion') { pobSwitchTab('pn'); }
        if (m === 'mapa') { setTimeout(mapaInit, 300); }
        if (m === 'dashboards') { setTimeout(function() { dashCambiar('resumen'); }, 100); }
        if (m === 'reportes-minsa') { setTimeout(rmInit, 100); }
    });
});

window.addEventListener('resize', function() {
    if (MAPA) MAPA.invalidateSize();
});

// ==================== INIT ====================
function initModules() {
    pnRutaCargar();
    cnvRutaCargar();
    document.getElementById('pn-ruta-carpeta').addEventListener('input', pnRutaGuardar);
    document.getElementById('cnv-ruta-carpeta').addEventListener('input', cnvRutaGuardar);
    setTimeout(pnStatus, 500);
    setTimeout(cnvStatus, 700);
    setTimeout(function() { dashCambiar('resumen'); }, 1000);
}
setTimeout(initModules, 1500);
