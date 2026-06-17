// ==================== PADRON NOMINAL ====================
const PN = { pagina: 1, total: 0, porPagina: 50 };

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
    const btn = document.getElementById('btn-pn-cargar');
    btn.disabled = true;
    btn.textContent = '⏳ Cargando...';
    try {
        const r = await fetch('/api/padron/cargar', { method: 'POST' });
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
    const btn = document.getElementById('btn-cnv-cargar');
    btn.disabled = true;
    btn.textContent = '⏳ Cargando...';
    try {
        const r = await fetch('/api/cnv/cargar', { method: 'POST' });
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

async function mapaInit() {
    try {
        const r = await fetch('/api/padron/geojson');
        const d = await r.json();
        var statusEl = document.getElementById('mapa-status-text');
        var statusDot = document.getElementById('mapa-status-dot');
        if (!d.features || d.features.length === 0) {
            statusEl.textContent = '⚠️ No hay pacientes con coordenadas';
            return;
        }
        statusEl.innerHTML = '✅ <strong>' + d.features.length + '</strong> pacientes geo-localizados';
        statusDot.className = 'status-dot ok';
        
        // Load distritos
        cargarDistritos();
        
        // Init map centered on Cusco
        if (!MAPA) {
            MAPA = L.map('mapa-container').setView([-13.5, -71.9], 9);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 18,
                attribution: '&copy; OpenStreetMap'
            }).addTo(MAPA);
        }
        
        // Remove old layer
        if (MAPA_MARKERS) MAPA.removeLayer(MAPA_MARKERS);
        
        MAPA_MARKERS = L.markerClusterGroup ? L.markerClusterGroup() : L.layerGroup();
        d.features.forEach(function(f) {
            var coords = f.geometry.coordinates;
            var props = f.properties;
            var marker = L.marker([coords[1], coords[0]]);
            marker.bindPopup('<b>' + props.nombre + '</b><br>' + props.direccion + '<br>' + props.distrito);
            MAPA_MARKERS.addLayer(marker);
        });
        MAPA.addLayer(MAPA_MARKERS);
        
        // Fit bounds
        if (d.features.length > 1) {
            var bounds = d.features.map(function(f) { return [f.geometry.coordinates[1], f.geometry.coordinates[0]]; });
            MAPA.fitBounds(bounds, { padding: [20, 20] });
        }
    } catch (e) {
        document.getElementById('mapa-status-text').textContent = 'Error: ' + e.message;
    }
}

async function cargarDistritos() {
    try {
        const r = await fetch('/api/mapa/pacientes-por-distrito');
        const d = await r.json();
        var el = document.getElementById('mapa-distritos');
        var html = '<table class="data-table" style="font-size:11px;width:100%;"><tr><th>Distrito</th><th>Total</th><th>Con Coord.</th></tr>';
        d.forEach(function(row) {
            html += '<tr><td>' + row.distrito + '</td><td>' + row.total + '</td><td>' + row.con_coord + '</td></tr>';
        });
        html += '</table>';
        el.innerHTML = html;
    } catch (e) {}
}

async function mapaKDE() {
    var infoEl = document.getElementById('mapa-kde-info');
    infoEl.textContent = '⏳ Generando KDE...';
    try {
        const r = await fetch('/api/mapa/kde', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ anio: '2026' }) });
        const d = await r.json();
        if (d.error) { infoEl.textContent = 'Error: ' + d.error; return; }
        infoEl.textContent = '🔥 KDE generado con ' + d.coords_count + ' puntos. Mostrando ' + d.coordenadas.length + ' en mapa.';
        
        if (!MAPA) { mapaInit(); return; }
        
        // Remove old heat if exists
        if (window.heatLayer) MAPA.removeLayer(window.heatLayer);
        
        // Simple heatmap using circles (no external lib needed)
        var heatPoints = d.coordenadas.map(function(c) { return [c[0], c[1]]; });
        heatPoints.forEach(function(p) {
            var circle = L.circle(p, {
                radius: 200,
                color: '#E74C3C',
                fillColor: '#E74C3C',
                fillOpacity: 0.3
            }).addTo(MAPA);
        });
        window.heatLayer = L.layerGroup(heatPoints);
        toast('KDE generado - ' + d.coords_count + ' puntos', 'info');
    } catch (e) { infoEl.textContent = 'Error: ' + e.message; }
}

// ==================== DASHBOARDS ====================
async function dashCargarResumen() {
    try {
        const r = await fetch('/api/dashboards/resumen');
        const d = await r.json();
        var el = document.getElementById('dash-contenido');
        if (d.error) { el.innerHTML = '<p style="color:#E74C3C;">Error: ' + d.error + '</p>'; return; }
        var html = '<div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-top:12px;">';
        var labels = { 'Padron Nominal': '👶 Padr\u00f3n Nominal', 'CNV': '📋 CNV', 'Vacunas': '💉 Vacunas', 'Materno': '🤱 Materno', 'IRAS/EDAS': '🤒 IRAS/EDAS' };
        var colors = { 'Padron Nominal': '#3498DB', 'CNV': '#9B59B6', 'Vacunas': '#2ECC71', 'Materno': '#F39C12', 'IRAS/EDAS': '#E74C3C' };
        Object.keys(d).forEach(function(k) {
            var count = d[k];
            var label = labels[k] || k;
            var color = colors[k] || '#555';
            var display = count < 0 ? '<span style="color:#E74C3C;">No disponible</span>' : count.toLocaleString();
            html += '<div style="background:var(--card-bg);padding:16px;border-radius:8px;border-left:4px solid ' + color + ';"><div style="font-size:13px;color:var(--text-muted);">' + label + '</div><div style="font-size:28px;font-weight:bold;margin-top:4px;">' + display + '</div></div>';
        });
        html += '</div>';
        
        // Add quick links
        html += '<div style="margin-top:16px;display:flex;gap:8px;flex-wrap:wrap;">';
        html += '<button class="sidebar-btn" style="background:#2ECC71;color:#fff;width:auto;" onclick="switchModule(\'mapa\')">🗺️ Ver Mapa</button>';
        html += '<button class="sidebar-btn" style="background:#3498DB;color:#fff;width:auto;" onclick="switchModule(\'padron\')">👶 Ver Padr\u00f3n Nominal</button>';
        html += '<button class="sidebar-btn" style="background:#9B59B6;color:#fff;width:auto;" onclick="switchModule(\'cnv\')">📋 Ver CNV</button>';
        html += '</div>';
        
        el.innerHTML = html;
        document.getElementById('dash-status-text').textContent = '✅ Resumen cargado';
        document.getElementById('dash-status-dot').className = 'status-dot ok';
    } catch (e) {
        document.getElementById('dash-contenido').innerHTML = '<p style="color:#E74C3C;">Error: ' + e.message + '</p>';
    }
}

async function dashMostrar(vista) {
    if (vista === 'resumen') dashCargarResumen();
    if (vista === 'mapa') switchModule('mapa');
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

// ==================== NAV HOOKS ====================
document.querySelectorAll('.nav-btn[data-module]').forEach(function(b) {
    b.addEventListener('click', function() {
        var m = this.dataset.module;
        if (m === 'poblacion') { pobSwitchTab('pn'); }
        if (m === 'mapa') { setTimeout(mapaInit, 300); }
        if (m === 'dashboards') { setTimeout(dashCargarResumen, 100); }
    });
});

// ==================== INIT ====================
function initModules() {
    setTimeout(pnStatus, 500);
    setTimeout(cnvStatus, 700);
    setTimeout(dashCargarResumen, 1000);
}
setTimeout(initModules, 1500);
