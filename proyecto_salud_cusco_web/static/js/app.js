// ==================== STATE ====================
const S = {
    bdOk: false, editorMode: false, ejecutando: false,
    activeToken: 0,
    meses: [1,2,3,4,5,6,7,8,9,10,11,12],
    mesesBackup: [],
    rutaCrudos: null,
    ingTotal: 0, ingDone: 0, ingStart: 0, ingEta: '',
    reportes: null,
    pollTimer: null,
    pollLastLine: {},
};

const MESES = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];

// ==================== FETCH WITH TIMEOUT ====================
async function fetchTimeout(url, options, timeoutMs=5000){
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
        const r = await fetch(url, {...options, signal: controller.signal});
        return r;
    } finally {
        clearTimeout(timer);
    }
}

// ==================== TOAST ====================
function toast(m,t='info'){const c=document.getElementById('toast-container'),e=document.createElement('div');e.className=`toast ${t}`;e.innerHTML=m;c.appendChild(e);setTimeout(()=>{e.style.opacity='0';e.style.transition='opacity .3s';setTimeout(()=>e.remove(),300)},6000)}

// ==================== MODAL ====================
function openModal(id){document.getElementById(id).classList.add('active')}
function closeModal(id){document.getElementById(id).classList.remove('active')}
document.querySelectorAll('.modal-overlay').forEach(o=>o.addEventListener('click',e=>{if(e.target===o)o.classList.remove('active')}))

// ==================== NAV ====================
document.querySelectorAll('.nav-btn[data-module]').forEach(b=>{
    b.addEventListener('click',function(){
        const m=this.dataset.module;
        if((m==='ingesta'||m==='reportes'||m==='maestros')&&!S.bdOk){
            toast('Debe validar PostgreSQL + BD + esquema desde Configurar BD','warning');
            switchModule('bd'); return;
        }
        switchModule(m);
    })
})

function switchModule(m){
    document.querySelectorAll('.nav-btn[data-module]').forEach(b=>b.classList.remove('active'));
    const btn=document.querySelector(`.nav-btn[data-module="${m}"]`);
    if(btn)btn.classList.add('active');
    document.querySelectorAll('.module').forEach(x=>x.classList.remove('active'));
    const el=document.getElementById(`module-${m}`);
    if(el)el.classList.add('active');
    if(m==='maestros')setTimeout(()=>maesActualizarAmbos(),300);
}

// ==================== THEME ====================
function setThemeMode(theme){
    const h=document.documentElement;
    const mode=theme==='light'?'light':'dark';
    h.setAttribute('data-theme',mode);
    document.getElementById('theme-toggle').textContent=mode==='dark'?'🌙':'☀️';
    try{localStorage.setItem('psc_theme',mode)}catch(e){}
}
try{setThemeMode(localStorage.getItem('psc_theme')||document.documentElement.getAttribute('data-theme')||'light')}catch(e){setThemeMode('light')}
document.getElementById('theme-toggle').addEventListener('click',()=>{
    const h=document.documentElement;
    const n=h.getAttribute('data-theme')==='dark'?'light':'dark';
    setThemeMode(n);
    setTimeout(()=>{
        if(typeof dashRecargar==='function'&&document.getElementById('module-dashboards')?.classList.contains('active'))dashRecargar();
        if(typeof MAPA!=='undefined'&&MAPA)MAPA.invalidateSize();
    },80);
})

// ==================== TABS ====================
document.querySelectorAll('.tab-btn').forEach(b=>{
    b.addEventListener('click',function(){
        const p=this.closest('.content-panel'); if(!p)return;
        p.querySelectorAll('.tab-btn').forEach(x=>x.classList.remove('active')); this.classList.add('active');
        p.querySelectorAll('.tab-content').forEach(x=>x.classList.remove('active'));
        const t=document.getElementById('tab-'+this.dataset.tab); if(t)t.classList.add('active');
    })
})

// ==================== CONSOLE / LOG ====================
function logTo(id, line, className='log-info'){
    const el=document.getElementById(id); if(!el)return;
    const d=document.createElement('div'); d.className=className||'log-info'; d.textContent=line; el.appendChild(d);
    el.scrollTop=el.scrollHeight;
}

function logBD(line, cls){ logTo('bd-log',line,cls); logTo('bd-monitor-console',line,cls); logTo('bd-logs-console',line,cls); }
function logIng(line, cls){ logTo('ing-monitor-console',line,cls); logTo('ing-logs-console',line,cls); }
function logMaes(line, cls){ logTo('maes-logs-console',line,cls); }
function logGlobal(line){ const el=document.getElementById('global-detail'); if(el)el.textContent=line; }

function logClass(line){
    if(!line) return 'log-info';
    if(line.includes('[ERROR]')||line.toLowerCase().includes('error')) return 'log-error';
    if(line.includes('[PROGRESS]')) return 'log-progress';
    if(line.includes('✅')||line.toLowerCase().includes('completado')||line.toLowerCase().includes('éxito')) return 'log-success';
    if(line.includes('⚠️')||line.toLowerCase().includes('warning')||line.toLowerCase().includes('advertencia')) return 'log-warning';
    return 'log-info';
}

// ==================== POLLING ENGINE ====================
function startPolling(token, callbacks){
    if(S.pollTimer){
        clearTimeout(S.pollTimer);
        S.pollTimer = null;
    }
    S.activeToken = token;
    S.pollLastLine[token] = 0;

    const interval = callbacks.interval || 1000;
    let stopped = false;

    function poll(){
        if(stopped || S.activeToken !== token){
            S.pollTimer = null;
            return;
        }

        fetch(`/api/ejecucion/status/${token}`)
        .then(r => {
            if(r.status === 404) {
                if(callbacks.onError) callbacks.onError('Ejecución no encontrada');
                stopped = true; S.pollTimer = null;
                return null;
            }
            return r.json();
        })
        .then(state => {
            if(!state || stopped || S.activeToken !== token){
                S.pollTimer = null;
                return;
            }

            // Process new lines
            const lastIdx = S.pollLastLine[token] || 0;
            const newLines = state.lines.slice(lastIdx);
            if(newLines.length > 0 && callbacks.onLine){
                newLines.forEach(line => callbacks.onLine(line));
            }
            S.pollLastLine[token] = state.line_count;

            // Process progress
            if(state.progress && callbacks.onProgress){
                callbacks.onProgress(state.progress);
            }

            // Check terminal states
            if(state.status === 'completed'){
                stopped = true; S.pollTimer = null;
                if(callbacks.onComplete) callbacks.onComplete(state);
            } else if(state.status === 'error'){
                stopped = true; S.pollTimer = null;
                if(callbacks.onError) callbacks.onError(state.error || 'Error de ejecución');
            } else if(state.status === 'cancelled'){
                stopped = true; S.pollTimer = null;
                if(callbacks.onCancel) callbacks.onCancel();
            } else {
                S.pollTimer = setTimeout(poll, interval);
            }
        })
        .catch(err => {
            if(!stopped && S.activeToken === token){
                S.pollTimer = setTimeout(poll, interval * 2);
            }
        });
    }

    poll();
    return () => { stopped = true; if(S.pollTimer){ clearTimeout(S.pollTimer); S.pollTimer = null; } };
}

function stopPolling(){
    if(S.pollTimer){
        clearTimeout(S.pollTimer);
        S.pollTimer = null;
    }
}

// ==================== GLOBAL PROGRESS ====================
function globalStart(nombre, determinate=false){
    S.ejecutando=true;
    document.getElementById('global-status').textContent=`⏳ ${nombre}`;
    document.getElementById('global-status').style.color='yellow';
    document.getElementById('btn-cancelar').style.display='inline-block';
    const track=document.getElementById('global-progress-track'); track.style.display='block';
    const bar=document.getElementById('global-progress-bar');
    if(determinate){ bar.style.width='0%'; bar.className='progress-bar-fill'; }
    else{ bar.style.width='30%'; bar.style.animation='pulse 1.5s ease infinite'; bar.className='progress-bar-fill'; }
    document.getElementById('global-detail').textContent=nombre;
}

function globalProgress(token, done, total, estado, detalle){
    if(token !== 0 && token !== S.activeToken) return;
    const bar=document.getElementById('global-progress-bar');
    bar.style.animation='none';
    bar.className='progress-bar-fill';
    const pct=Math.max(0,Math.min(done,total))/Math.max(total,1);
    bar.style.width=(pct*100)+'%';
    if(estado==='error') bar.classList.add('error');
    document.getElementById('global-detail').textContent=detalle||'';
}

function globalFinish(nombre, exito, detalle){
    S.ejecutando=false;
    const bar=document.getElementById('global-progress-bar');
    bar.style.animation='none';
    bar.style.width=exito?'100%':'0%';
    bar.className='progress-bar-fill'+(exito?' success':' error');
    const status=document.getElementById('global-status');
    if(exito){
        status.textContent=`✅ ${nombre}`; status.style.color='#2ECC71';
        document.getElementById('global-detail').textContent=detalle||''; document.getElementById('global-detail').style.color='#2ECC71';
    }else{
        status.textContent=`❌ ${nombre}`; status.style.color='#E74C3C';
        document.getElementById('global-detail').textContent=detalle||'Error de ejecución'; document.getElementById('global-detail').style.color='#E74C3C';
    }
    document.getElementById('btn-cancelar').style.display='none';
}

// ==================== POLLING WRAPPER ====================
function ejecutarConPolling(nombre, fetchPromise, logFn, callbacks){
    globalStart(nombre, true);
    if(callbacks && callbacks.onStart) callbacks.onStart();

    fetchPromise
    .then(r => r.json())
    .then(d => {
        if(d.error){
            globalFinish(nombre, false, d.error);
            if(callbacks && callbacks.onError) callbacks.onError(d.error);
            return;
        }

        const token = d.token;
        logFn(`▶️ ${nombre} iniciado (token: ${token})`, 'log-info');

        startPolling(token, {
            interval: 800,
            onLine: (line) => {
                logFn(line, logClass(line));
                logGlobal(line);
                if(callbacks && callbacks.onLine) callbacks.onLine(line);
            },
            onProgress: (p) => {
                globalProgress(token, p.done, p.total, '', `${p.done}/${p.total} ETA: ${p.eta}`);
                if(callbacks && callbacks.onProgress) callbacks.onProgress(p);
            },
            onComplete: (state) => {
                globalFinish(nombre, true, 'Completado');
                logFn(`✅ ${nombre} completado`, 'log-success');
                if(callbacks && callbacks.onComplete) callbacks.onComplete(state);
            },
            onError: (err) => {
                globalFinish(nombre, false, err);
                logFn(`❌ ${nombre}: ${err}`, 'log-error');
                if(callbacks && callbacks.onError) callbacks.onError(err);
            },
            onCancel: () => {
                globalFinish(nombre, false, 'Cancelado');
                logFn(`🛑 ${nombre} cancelado`, 'log-warning');
            },
        });
    })
    .catch(e => {
        globalFinish(nombre, false, e.message);
        logFn(`❌ Error al iniciar: ${e.message}`, 'log-error');
        if(callbacks && callbacks.onError) callbacks.onError(e.message);
    });
}

// ==================== DB CONFIG ====================
async function cargarConfigBD(){
    try{
        const r=await fetch('/api/db/config'); const c=await r.json();
        document.getElementById('db-host').value=c.host||'localhost';
        document.getElementById('db-port').value=c.port||'5432';
        document.getElementById('db-database').value=c.database||'ivan_proceso_his';
        document.getElementById('db-schema').value=c.schema||'es_ivan';
        document.getElementById('db-user').value=c.user||'postgres';
    }catch(e){
        console.error(e);
    }
}

function showServerDown(){
    const nav=document.getElementById('nav-status-access');
    nav.textContent='⚠️ Servidor no disponible'; nav.style.color='#E74C3C';
    const pgText=document.getElementById('bd-status-pg-text');
    pgText.textContent='❌ No se puede conectar con el servidor Flask';
    const resultDiv=document.getElementById('bd-detection-result');
    resultDiv.innerHTML='<p style="color:#E74C3C;">El servidor backend no está respondiendo.</p><p style="font-size:12px;color:var(--text-muted);margin-top:8px;">Asegúrate de ejecutar: <code style="background:#2d2d2d;padding:2px 6px;border-radius:3px;">python app.py</code></p>';
    const actionsDiv=document.getElementById('bd-actions-area');
    actionsDiv.innerHTML='';
}

async function guardarConfigBD(){
    await fetch('/api/db/config',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
        host:document.getElementById('db-host').value,
        port:parseInt(document.getElementById('db-port').value)||5432,
        database:document.getElementById('db-database').value,
        schema:document.getElementById('db-schema').value,
        password:document.getElementById('db-password').value,
    })});
    toast('Configuración guardada','success');
}

async function detectarBD(){
    globalStart('Detectando PostgreSQL...');
    const pgStatus=document.getElementById('bd-status-pg');
    const pgText=document.getElementById('bd-status-pg-text');
    const resultDiv=document.getElementById('bd-detection-result');
    const actionsDiv=document.getElementById('bd-actions-area');

    pgStatus.className='status-indicator warning'; pgText.textContent='⏳ Detectando PostgreSQL...';
    resultDiv.innerHTML='Detectando...'; actionsDiv.innerHTML='';

    try{
        const r=await fetch('/api/db/detect',{method:'POST'}); const d=await r.json();
        if(d.error){ pgStatus.className='status-indicator error'; pgText.textContent='❌ Error'; resultDiv.innerHTML=`Error: ${d.error}`; globalFinish('Detectar PG',false,d.error); return; }

        let html=`<div><span class="key">Instalado:</span> <span class="value ${d.instalado?'ok':'error'}">${d.instalado?'Sí':'No'}</span></div>`;
        if(d.version) html+=`<div><span class="key">Versión:</span> <span class="value">${d.version}</span></div>`;
        html+=`<div><span class="key">Servicio activo:</span> <span class="value ${d.servicio_activo?'ok':'error'}">${d.servicio_activo?'Sí':'No'}</span></div>`;
        if(d.puerto) html+=`<div><span class="key">Puerto:</span> <span class="value">${d.puerto}</span></div>`;
        resultDiv.innerHTML=html;

        if(!d.instalado){
            pgStatus.className='status-indicator error'; pgText.textContent=`❌ PostgreSQL no encontrado en este equipo`;
            actionsDiv.innerHTML=`
                <p style="color:orange;font-size:13px;margin:8px 0;">PostgreSQL no está instalado en esta computadora.</p>
                <p style="font-size:11px;color:var(--text-muted);margin-bottom:8px;">Esta aplicación necesita PostgreSQL para funcionar con grandes volúmenes de datos. Haga clic en el botón de abajo para instalar PostgreSQL automáticamente.</p>
                <button class="sidebar-btn" style="background:#27AE60;color:#fff;font-weight:bold;height:50px;font-size:14px;" onclick="instalarPG()">🚀 INSTALAR POSTGRESQL AUTOMÁTICAMENTE</button>
            `;
            globalFinish('Detectar PG',true,'PostgreSQL no instalado');
        }else if(d.instalado && !d.servicio_activo){
            pgStatus.className='status-indicator warning';
            pgText.textContent=`⚠️ PostgreSQL ${d.version} instalado pero servicio detenido`;
            actionsDiv.innerHTML=`
                <p style="color:orange;font-size:12px;margin:8px 0;">PostgreSQL ${d.version} está instalado pero el servicio no está corriendo.</p>
                <button class="sidebar-btn" style="background:#2980B9;color:#fff;font-weight:bold;height:45px;font-size:13px;" onclick="iniciarServicioPG()">▶️ INICIAR SERVICIO DE POSTGRESQL</button>
                <button class="sidebar-btn" style="background:#424242;margin-top:4px;" onclick="detectarBD()">🔄 Volver a detectar</button>
            `;
            globalFinish('Detectar PG',true,'PostgreSQL instalado pero servicio detenido');
        }else{
            pgStatus.className='status-indicator ok';
            pgText.textContent=`✅ PostgreSQL ${d.version} detectado y activo`;
            actionsDiv.innerHTML=`
                <p style="color:#2ECC71;font-size:13px;margin:8px 0;">✅ PostgreSQL ${d.version} está activo</p>
                <p style="font-size:11px;color:var(--text-muted);margin-bottom:8px;">📦 Puerto: ${d.puerto||5432}  |  Usuario: postgres</p>
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;">
                    <button class="sidebar-btn" style="background:#27AE60;color:#fff;grid-column:span 2;" onclick="inicializarBD()">🔄 INICIALIZAR BASE DE DATOS</button>
                    <button class="sidebar-btn" style="background:#5D6D7E;color:#fff;" onclick="verificarBD()">🔍 Verificar estado</button>
                    <button class="sidebar-btn" style="background:#424242;" onclick="detectarBD()">🔄 Recargar</button>
                </div>
            `;
            globalFinish('Detectar PG',true,'PostgreSQL activo');
            await verificarBD();
        }
        logBD(`✅ PostgreSQL detectado: ${d.instalado?'Sí':'No'} | Servicio: ${d.servicio_activo?'Sí':'No'}`,'log-success');
    }catch(e){
        pgStatus.className='status-indicator error'; pgText.textContent='❌ Error de detección';
        resultDiv.innerHTML=`Error: ${e.message}`;
        globalFinish('Detectar PG',false,e.message);
    }
}

async function verificarBD(){
    globalStart('Verificando conexión BD...',true);
    try{
        const r=await fetch('/api/db/verify',{method:'POST'}); const d=await r.json();
        (d.log||[]).forEach(l=>logBD(l,'log-info'));
        const nav=document.getElementById('nav-status-access');
        if(d.exito){
            S.bdOk=true;
            nav.textContent='🔓 Sistema habilitado'; nav.style.color='#2ECC71';
            document.getElementById('btn-nav-bd').style.background='#1A5C2E';
            toast('✅ Sistema habilitado','success');
            globalFinish('Verificar BD',true,'Conexión establecida');
        }else{
            S.bdOk=false;
            nav.textContent='🔒 Acceso restringido'; nav.style.color='orange';
            document.getElementById('btn-nav-bd').style.background='transparent';
            toast('⚠️ No se pudo conectar: '+(d.mensaje||''),'warning');
            openModal('modal-pg-pass');
            globalFinish('Verificar BD',false,d.mensaje);
        }
    }catch(e){
        globalFinish('Verificar BD',false,e.message);
    }
}

async function instalarPG(){
    globalStart('Instalando PostgreSQL...',true);
    toast('Instalación de PostgreSQL iniciada...','info');
    try{
        const r=await fetch('/api/db/install',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
        const d=await r.json();
        logBD('Instalación iniciada en servidor...','log-info');
        setTimeout(()=>detectarBD(),5000);
    }catch(e){globalFinish('Instalar PG',false,e.message);toast('Error al instalar','error')}
}

async function iniciarServicioPG(){
    globalStart('Iniciando servicio PostgreSQL...',true);
    try{
        const r=await fetch('/api/db/start-service',{method:'POST'}); const d=await r.json();
        if(d.exito){toast('Servicio iniciado','success');detectarBD();globalFinish('Iniciar servicio',true,'Servicio PostgreSQL iniciado')}
        else{toast('Error: '+d.mensaje,'error');globalFinish('Iniciar servicio',false,d.mensaje)}
    }catch(e){globalFinish('Iniciar servicio',false,e.message)}
}

async function inicializarBD(){
    globalStart('Inicializando base de datos...',true);
    try{
        const r=await fetch('/api/db/init',{method:'POST'}); const d=await r.json();
        (d.log||[]).forEach(l=>logBD(l,'log-info'));
        if(d.exito){toast('BD inicializada','success');verificarBD();globalFinish('Inicializar BD',true,'Base de datos lista')}
        else{toast('Error al inicializar','error');globalFinish('Inicializar BD',false,d.mensaje)}
    }catch(e){globalFinish('Inicializar BD',false,e.message)}
}

async function recuperarPassPG(){
    closeModal('modal-pg-pass');
    globalStart('Recuperando password...',true);
    try{
        const r=await fetch('/api/db/recover-password',{method:'POST'}); const d=await r.json();
        (d.log||[]).forEach(l=>logBD(l,'log-info'));
        if(d.exito){toast('Password recuperado','success');verificarBD();globalFinish('Recuperar pass',true,'Password recuperado')}
        else{toast('No se pudo recuperar','error');globalFinish('Recuperar pass',false,'Falló recuperación')}
    }catch(e){globalFinish('Recuperar pass',false,e.message)}
}

async function conectarPG(){
    const pass=document.getElementById('pg-pass-entry').value;
    if(!pass){toast('Ingrese una contraseña','warning');return}
    await fetch('/api/db/config',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({password:pass})});
    closeModal('modal-pg-pass');
    toast('Contraseña guardada, reconectando...','info');
    await verificarBD();
}

function reinstalarPG(){
    closeModal('modal-pg-pass');
    instalarPG();
}

// ==================== INGESTA ====================
document.getElementById('btn-ing-carpeta').addEventListener('click',async()=>{
    try{
        const r=await fetch('/api/fs/select-folder',{method:'POST'});
        const d=await r.json();
        if(d.path){
            S.rutaCrudos=d.path;
            document.getElementById('ing-lbl-ruta').textContent=`📁 Atenciones: ${d.path}`;
            document.getElementById('ing-lbl-ruta').style.color='#2ECC71';
            toast('Carpeta seleccionada','info');
        }
    }catch(e){
        toast('Error al abrir selector de carpeta','error');
    }
});
document.getElementById('btn-ing-ruta-auto').addEventListener('click',()=>{
    S.rutaCrudos=null;
    document.getElementById('ing-lbl-ruta').textContent='📁 Atenciones: automática';
    document.getElementById('ing-lbl-ruta').style.color='var(--text-muted)';
    toast('Ruta automática','info');
});

function iniciarImportacion(anio, meses, modo){
    const nombre=meses.length===12?`Importar HIS ${anio}`:`Importar ${anio} (${meses.length} meses)`;
    ingProgressReset(nombre);
    document.getElementById('ing-status').className='status-indicator warning';
    document.getElementById('ing-status-text').textContent=`Ejecutando ${nombre}...`;
    ejecutarConPolling(nombre,
        fetch('/api/ingesta/import',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({anio,meses,ruta_crudos:S.rutaCrudos||'',modo})}),
        logIng,
        {
            onProgress: (p) => {
                ingProgressUpdate(p.done, p.total, '', p.eta);
            },
            onComplete: () => {
                document.getElementById('ing-status').className='status-indicator ok';
                document.getElementById('ing-status-text').textContent='✅ Importación completada';
                ingProgressFinish(true);
            },
            onError: (err) => {
                document.getElementById('ing-status').className='status-indicator error';
                document.getElementById('ing-status-text').textContent=`❌ Error: ${err}`;
                ingProgressFinish(false);
            },
        }
    );
}

document.getElementById('ing-btn-importar').addEventListener('click',async()=>{
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const anio=document.getElementById('ing-anio').value;
    const meses=S.meses;
    if(!meses.length){toast('Selecciona al menos un mes','warning');return;}

    // Verificar si ya hay datos del año
    try{
        const r=await fetch('/api/ingesta/check',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({anio})});
        const d=await r.json();
        if(d.tiene_datos){
            document.getElementById('imp-opt-anio').textContent=anio;
            S._impPendiente={anio,meses};
            openModal('modal-import-opciones');
            return;
        }
    }catch(e){/* si falla la verificacion, continuar normalmente */}

    iniciarImportacion(anio, meses, 'reemplazar');
});

document.getElementById('imp-opt-reemplazar').addEventListener('click',()=>{
    closeModal('modal-import-opciones');
    const {anio,meses}=S._impPendiente||{};
    if(anio) iniciarImportacion(anio, meses||Array.from({length:12},(_,i)=>i+1), 'reemplazar');
});

document.getElementById('imp-opt-completar').addEventListener('click',()=>{
    closeModal('modal-import-opciones');
    const {anio,meses}=S._impPendiente||{};
    if(anio) iniciarImportacion(anio, meses||Array.from({length:12},(_,i)=>i+1), 'completar');
});

document.getElementById('ing-btn-refrescar').addEventListener('click',()=>{
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const nombre='Refrescar HIS Proceso';
    logIng('♻️ Refrescando HIS Proceso...','log-info');
    ejecutarConPolling(nombre,
        fetch('/api/ingesta/refresh',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}),
        logIng
    );
});

document.getElementById('ing-btn-borrar').addEventListener('click',()=>{
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    if(!confirm('¿Está seguro de borrar los datos seleccionados?'))return;
    const anio=document.getElementById('ing-anio').value;
    const modo=S.meses.length===12?'anio':'mes';
    const nombre=`Borrar datos ${anio}`;
    logIng(`🗑️ Borrando datos: ${anio} ${modo}`,'log-warning');
    ejecutarConPolling(nombre,
        fetch('/api/ingesta/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({modo,anio,mes:S.meses.length===1?S.meses[0]:''})}),
        logIng
    );
});

document.getElementById('ing-btn-vaciar').addEventListener('click',()=>{
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    if(!confirm('¿ESTA SEGURO DE VACIAR TODA LA TABLA?\n\nEsta acción no se puede deshacer.'))return;
    if(!confirm('¿CONFIRMA QUE DESEA ELIMINAR TODOS LOS DATOS?'))return;
    const nombre='VACIAR TODA LA TABLA';
    logIng('💀 VACIANDO TODA LA TABLA...','log-error');
    ejecutarConPolling(nombre,
        fetch('/api/ingesta/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({modo:'todo'})}),
        logIng
    );
});

// ==================== MONTH SELECTOR ====================
function renderMeses(){
    const g=document.getElementById('meses-grid');g.innerHTML='';
    const tc=document.getElementById('mes-todos');tc.checked=S.meses.length===12;
    MESES.forEach((n,i)=>{
        const d=document.createElement('div');d.className='month-item';
        const c=document.createElement('input');c.type='checkbox';c.checked=S.meses.includes(i+1);c.dataset.mes=i+1;
        c.addEventListener('change',()=>{if(!c.checked)tc.checked=false});
        d.appendChild(c);const s=document.createElement('span');s.textContent=n;d.appendChild(s);g.appendChild(d);
    });
}

function toggleTodosMeses(el){
    document.querySelectorAll('#meses-grid input[type="checkbox"]').forEach(c=>c.checked=el.checked);
}

function aceptarMeses(){
    S.meses=[];
    document.querySelectorAll('#meses-grid input[type="checkbox"]').forEach(c=>{if(c.checked)S.meses.push(parseInt(c.dataset.mes))});
    actualizarBtnMeses();
    closeModal('modal-meses');
}

function cerrarMesesCancel(){
    S.meses=[...S.mesesBackup];
    actualizarBtnMeses();
    closeModal('modal-meses');
}

function actualizarBtnMeses(){
    const btn=document.getElementById('ing-btn-meses');
    if(S.meses.length===0)btn.textContent='📅 Seleccionar meses';
    else if(S.meses.length===12)btn.textContent='📅 Todos los meses';
    else if(S.meses.length===1)btn.textContent=`📅 Mes ${String(S.meses[0]).padStart(2,'0')}`;
    else btn.textContent=`📅 ${S.meses.length} meses (${S.meses.slice(0,3).map(m=>MESES[m-1].substring(0,3)).join(', ')})`;
}

document.getElementById('ing-btn-meses').addEventListener('click',()=>{
    S.mesesBackup=[...S.meses];
    renderMeses();
    openModal('modal-meses');
});

// ==================== INGESTA PROGRESS ====================
function ingProgressReset(nombre){
    S.ingTotal=0; S.ingDone=0; S.ingStart=Date.now();
    document.getElementById('ing-progress-bar').style.width='0%';
    document.getElementById('ing-progress-label').textContent=`Progreso de ingesta: ${nombre} (iniciando)`;
    document.getElementById('ing-progress-label').style.color='white';
    document.getElementById('ing-progress-eta').textContent='ETA: calculando...';
    document.getElementById('ing-progress-time').textContent='Transcurrido: 00:00';
}

function ingProgressUpdate(done, total, estado, eta){
    if(total > 0) S.ingTotal = total;
    if(done > 0) S.ingDone = done;
    const pct=Math.max(0,Math.min(done,total))/Math.max(total,1);
    document.getElementById('ing-progress-bar').style.width=(pct*100)+'%';
    const label=`Progreso de ingesta: ${done}/${total} (${estado||'OK'}) - ETA: ${eta||'...'}`;
    document.getElementById('ing-progress-label').textContent=label;
    const elapsed=Math.floor((Date.now()-S.ingStart)/1000);
    const eStr=fmtTime(elapsed);
    if(eta) document.getElementById('ing-progress-eta').textContent=`ETA: ${eta}`;
    document.getElementById('ing-progress-time').textContent=`Transcurrido: ${eStr}`;
    if(done>=total && total>0){
        const totalSec=Math.floor((Date.now()-S.ingStart)/1000);
        document.getElementById('ing-progress-eta').textContent=`ETA: 00:00 | Total: ${fmtTime(totalSec)}`;
    }
}

function ingProgressFinish(exito){
    const totalSec=Math.floor((Date.now()-S.ingStart)/1000);
    document.getElementById('ing-progress-label').textContent=`Duración total: ${fmtTime(totalSec)}`;
    document.getElementById('ing-progress-label').style.color=exito?'#2ECC71':'orange';
}

function fmtTime(s){
    if(s>=3600){const h=Math.floor(s/3600);const m=Math.floor((s%3600)/60);return `${h}:${String(m).padStart(2,'0')}:${String(s%60).padStart(2,'0')}`;}
    return `${String(Math.floor(s/60)).padStart(2,'0')}:${String(s%60).padStart(2,'0')}`;
}

// ==================== REPORTES ====================
async function cargarReportes(){
    try{const r=await fetch('/api/reportes/config');S.reportes=await r.json();renderReportes()}catch(e){console.error(e)}
}

function renderReportes(){
    const c=document.getElementById('rep-buttons');c.innerHTML='';
    const botones=S.reportes?.botones||[];
    const secs={vacunas_cred:{titulo:'💉 Vacunas y CRED',items:[]},reportes:{titulo:'📊 Reportes',items:[]}};
    botones.forEach((b,i)=>{const s=b.seccion||'reportes';if(!secs[s])secs[s]={titulo:s,items:[]};secs[s].items.push({...b,index:i})});
    Object.entries(secs).forEach(([k,sec])=>{
        if(!sec.items.length)return;
        const t=document.createElement('div');
        t.style.cssText=`font-size:${k==='vacunas_cred'?'16':'14'}px;font-weight:bold;margin:${k==='reportes'?'20':'0'}px 0 8px;`;
        t.textContent=sec.titulo;
        c.appendChild(t);
        sec.items.forEach(item=>{
            const row=document.createElement('div');row.className='report-btn-row';
            const btn=document.createElement('button');btn.className='report-btn';
            btn.style.background=item.color_bg||'#2c3e50';btn.textContent=item.nombre||item.script;
            btn.addEventListener('click',()=>ejecutarReporte(item));
            row.appendChild(btn);
            if(S.editorMode){
                const eb=document.createElement('button');eb.className='btn-sm';
                eb.style.background='#34495E';eb.style.color='#fff';eb.textContent='✏️';
                eb.addEventListener('click',()=>abrirEditor(item.script,item.nombre));
                row.appendChild(eb);
                if(item.custom){
                    const db=document.createElement('button');db.className='btn-sm';
                    db.style.background='#922B21';db.style.color='#fff';db.textContent='🗑️';
                    db.addEventListener('click',()=>eliminarReporte(item.index));
                    row.appendChild(db);
                }
            }
            c.appendChild(row);
        });
    });
}

function ejecutarReporte(item){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const anio=document.getElementById('rep-anio').value;
    const nombre=item.nombre||item.script;
    const viewer=document.getElementById('rep-resultados');
    viewer.textContent=`⏳ Ejecutando: ${nombre}...\n`;

    ejecutarConPolling(nombre,
        fetch('/api/reportes/run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({script:item.script,anio})}),
        (line, cls) => {
            // Also append to results viewer
            viewer.textContent += line + '\n';
            viewer.scrollTop = viewer.scrollHeight;
        },
        {
            onComplete: (state) => {
                viewer.textContent += '\n✅ Ejecución completada\n';
                toast(`Reporte "${nombre}" completado`,'success');
            },
            onError: (err) => {
                viewer.textContent += `\n❌ Error: ${err}\n`;
            },
        }
    );
}

async function eliminarReporte(idx){
    if(!confirm('¿Eliminar este reporte?'))return;
    await fetch('/api/reportes/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({index:idx})});
    toast('Reporte eliminado','success');
    cargarReportes();
}

async function crearNuevoSQL(){
    const nombre=document.getElementById('nuevo-sql-nombre').value.trim();
    if(!nombre){toast('Ingrese un nombre','warning');return;}
    const r=await fetch('/api/reportes/new',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({nombre,seccion:document.getElementById('nuevo-sql-seccion').value,color:document.getElementById('nuevo-sql-color').value})});
    const d=await r.json();closeModal('modal-nuevo-sql');toast(d.mensaje,'success');
    await cargarReportes();
    abrirEditor(`scripts_sql/reportes/${nombre.toLowerCase().replace(/ /g,'_').replace(/\u20e3/g,'').trim()}.sql`,nombre);
}

// ==================== MAESTROS ====================
S.maes = {
    ruta: null,
    csvChecks: {},
    csvTodos: true,
    disponiblesRapido: [],
    estadoRapido: {},
    todosRapido: true,
    delChecks: {},
};

function maesLog(msg, cls){
    const c=document.getElementById('maes-console');
    if(!c)return;
    if(c.children.length===1 && c.children[0].textContent.includes('Log de operaciones')){
        c.innerHTML='';
    }
    const d=document.createElement('div');
    if(cls)d.className=cls;
    else if(msg.startsWith('✅')||msg.startsWith('✔')) d.className='log-success';
    else if(msg.startsWith('❌')||msg.startsWith('✖')) d.className='log-error';
    d.textContent=msg;
    c.appendChild(d);
    c.scrollTop=c.scrollHeight;
}

function maesToggleCollapse(header){
    const card=header.closest('.maes-collapse');
    if(card)card.classList.toggle('open');
}

async function maesSeleccionarCarpeta(){
    const r=await fetch('/api/fs/select-folder',{method:'POST'});
    const d=await r.json();
    if(d.path){
        S.maes.ruta=d.path;
        document.getElementById('maes-ruta-text').textContent='📁 .../'+d.path.split('\\').pop().split('/').pop();
        document.getElementById('maes-ruta-text').style.color='#2ECC71';
        await maesListarCSVs(d.path);
    }
}

async function maesListarCSVs(folder){
    const r=await fetch('/api/maestros/csv-list',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({folder})});
    const d=await r.json();
    const container=document.getElementById('maes-csv-list');
    const badge=document.getElementById('maes-csv-count');
    if(d.error){container.innerHTML=`<div class="maes-empty" style="color:#E74C3C;">${d.error}</div>`;if(badge)badge.textContent='!';return;}
    container.innerHTML='';
    if(!d.csvs.length){
        container.innerHTML='<div class="maes-empty">No hay archivos CSV en esta carpeta</div>';
        if(badge)badge.textContent='0';
        return;
    }
    S.maes.csvChecks={};
    if(badge)badge.textContent=d.csvs.length;
    d.csvs.forEach(f=>{
        S.maes.csvChecks[f]=true;
        const label=document.createElement('label');
        const cb=document.createElement('input');
        cb.type='checkbox';cb.checked=true;
        cb.addEventListener('change',()=>{S.maes.csvChecks[f]=cb.checked;});
        label.appendChild(cb);
        label.appendChild(document.createTextNode(' '+f));
        container.appendChild(label);
    });
}

function maesSeleccionarTodosCSV(){
    const all=Object.keys(S.maes.csvChecks);
    if(!all.length)return;
    const someOff=all.some(f=>!S.maes.csvChecks[f]);
    const val=someOff;
    S.maes.csvChecks={};
    document.querySelectorAll('#maes-csv-list input[type="checkbox"]').forEach(cb=>{cb.checked=val;});
    all.forEach(f=>{S.maes.csvChecks[f]=val;});
}

function maesGetSelectedCSVs(){
    return Object.keys(S.maes.csvChecks).filter(f=>S.maes.csvChecks[f]);
}

async function maesCargarSeleccionados(){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    if(!S.maes.ruta){toast('Selecciona una carpeta primero','warning');return;}
    const selec=maesGetSelectedCSVs();
    if(!selec.length){toast('Ningún archivo seleccionado','warning');return;}
    maesLog(`📄 Cargando ${selec.length} archivo(s) de maestros...`);
    const r=await fetch('/api/maestros/ejecutar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
        script:'scripts_python/ingesta/cargar_maestros.py',
        args:[S.maes.ruta, '--archivos', ...selec]
    })});
    const d=await r.json();
    if(!r.ok){maesLog(`❌ Error: ${d.error||r.statusText}`);toast('Error al cargar','error');return;}
    maesLog('✅ Carga iniciada. Esperando resultados...');
    maesIniciarPolling(d.token,selec);
}

async function maesActualizarAmbos(){
    await maesActualizarListaBD();
    await maesActualizarListaDel();
}

async function maesActualizarListaBD(){
    const container=document.getElementById('maes-bd-list');
    if(!S.bdOk){container.innerHTML='<div style="text-align:center;color:var(--text-muted);padding:20px;">BD no conectada</div>';return;}
    container.innerHTML='<div style="text-align:center;color:var(--text-muted);padding:10px;">Cargando...</div>';
    try{
        const [rTablas, rDesc]=await Promise.all([
            fetch('/api/maestros/tablas'),
            fetch('/api/maestros/descriptions')
        ]);
        const tablas=await rTablas.json();
        const descs=await rDesc.json();
        if(tablas.error||!tablas.length){
            container.innerHTML='<div style="text-align:center;color:var(--text-muted);padding:20px;">No se detectaron maestros<br>en la base de datos.</div>';
            if(tablas.error)maesLog(`❌ ${tablas.error}`);
            return;
        }
        const names=tablas.map(t=>t.nombre);
        S.maes.disponiblesRapido=names;
        S.maes.estadoRapido={};names.forEach(n=>{S.maes.estadoRapido[n]=true;});
        S.maes.todosRapido=true;
        const fijo=['maestro_his_cie_cpms','maestro_paciente','maestro_personal','maestro_his_ups','maestro_his_etnia','maestro_his_colegio','eess2025','maestro_his_establecimiento'];
        const cargadosFijo=names.filter(n=>fijo.includes(n));
        const otros=names.filter(n=>!fijo.includes(n));
        const badge=document.getElementById('maes-bd-count');
        if(badge)badge.textContent=names.length;
        container.innerHTML='';
        if(cargadosFijo.length){
            const h=document.createElement('div');h.style.cssText='font-size:10px;font-weight:700;color:#2ECC71;padding:8px 14px 4px;text-transform:uppercase;letter-spacing:.4px;';
            h.textContent='✅ HIS Proceso ('+cargadosFijo.length+')';
            container.appendChild(h);
            cargadosFijo.forEach(t=>{
                const item=document.createElement('div');item.className='maes-bd-item';
                item.innerHTML=`<div class="maes-bd-item-info"><div class="maes-bd-item-name">${t}</div><div class="maes-bd-item-desc">${descs[t]||t}</div></div><div class="maes-bd-item-status">Cargado</div>`;
                container.appendChild(item);
            });
        }
        if(otros.length){
            const h=document.createElement('div');h.style.cssText='font-size:10px;font-weight:700;color:#5DADE2;padding:8px 14px 4px;text-transform:uppercase;letter-spacing:.4px;';
            h.textContent='📚 Otros ('+otros.length+')';
            container.appendChild(h);
            otros.forEach(t=>{
                const item=document.createElement('div');item.className='maes-bd-item';
                item.innerHTML=`<div class="maes-bd-item-info"><div class="maes-bd-item-name">${t}</div><div class="maes-bd-item-desc">${descs[t]||'Maestro disponible'}</div></div>`;
                container.appendChild(item);
            });
        }
        maesLog(`🔄 Maestros cargados: ${names.length}`);
        maesActualizarBtnRapido();
    }catch(e){container.innerHTML=`<div class="maes-empty" style="color:#E74C3C;">${e.message}</div>`;}
}

async function maesActualizarListaDel(){
    const container=document.getElementById('maes-del-list');
    if(!S.bdOk){container.innerHTML='<div style="text-align:center;color:var(--text-muted);padding:8px;">BD no conectada</div>';return;}
    try{
        const r=await fetch('/api/maestros/tablas');
        const tablas=await r.json();
        if(tablas.error||!tablas.length){
            container.innerHTML='<div style="text-align:center;color:var(--text-muted);padding:8px;">No hay tablas maestras</div>';
            S.maes.delChecks={};
            return;
        }
        container.innerHTML='';
        S.maes.delChecks={};
        tablas.forEach(t=>{
            S.maes.delChecks[t.nombre]=false;
            const label=document.createElement('label');
            const cb=document.createElement('input');
            cb.type='checkbox';
            cb.addEventListener('change',()=>{S.maes.delChecks[t.nombre]=cb.checked;});
            label.appendChild(cb);
            label.appendChild(document.createTextNode(' '+t.nombre));
            container.appendChild(label);
        });
    }catch(e){container.innerHTML=`<div style="color:#E74C3C;padding:8px;">${e.message}</div>`;}
}

function maesSeleccionarTodosDel(){
    const all=Object.keys(S.maes.delChecks);
    if(!all.length)return;
    const someOff=all.some(t=>!S.maes.delChecks[t]);
    const val=someOff;
    S.maes.delChecks={};
    document.querySelectorAll('#maes-del-list input[type="checkbox"]').forEach(cb=>{cb.checked=val;});
    all.forEach(t=>{S.maes.delChecks[t]=val;});
}

async function maesEliminarSeleccionados(){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const selec=Object.keys(S.maes.delChecks).filter(t=>S.maes.delChecks[t]);
    if(!selec.length){toast('Selecciona al menos una tabla','warning');return;}
    if(!confirm(`Se eliminará(n):\n${selec.join(', ')}\n\n¿Continuar?`))return;
    maesLog(`🗑️ Eliminando ${selec.length} tabla(s)...`);
    const r=await fetch('/api/maestros/eliminar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tablas:selec})});
    const d=await r.json();
    if(d.error){maesLog(`❌ ${d.error}`);toast('Error al eliminar','error');return;}
    d.resultados.forEach(r=>{maesLog(`${r.ok?'✅':'❌'} ${r.tabla}: ${r.ok?'Eliminada':r.error}`);});
    maesLog('✅ Eliminación completada.');
    document.getElementById('maes-bd-count').textContent='0';
    setTimeout(()=>{maesActualizarAmbos();},500);
}

async function maesEliminarTodos(){
    if(!confirm('⚠️ Se eliminarán TODAS las tablas maestras.\n\n¿Estás seguro?'))return;
    maesLog('🗑️ Eliminando TODOS los maestros...');
    const r=await fetch('/api/maestros/eliminar-todos',{method:'POST'});
    const d=await r.json();
    if(d.error){maesLog(`❌ ${d.error}`);toast('Error','error');return;}
    maesLog(`✅ Se eliminaron ${d.eliminadas} tablas maestras.`);
    setTimeout(()=>{maesActualizarAmbos();},500);
}

async function maesProcesarEESS(){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    maesLog('🏥 Procesando EESS principal...');
    const r=await fetch('/api/maestros/ejecutar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
        script:'scripts_python/ingesta/procesar_eess_principal.py',
        args:[]
    })});
    const d=await r.json();
    if(!r.ok){maesLog(`❌ Error: ${d.error||r.statusText}`);toast('Error','error');return;}
    maesLog('✅ Procesamiento iniciado.');
    maesIniciarPolling(d.token);
}

async function maesGenerarHISProceso(){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const anio=document.getElementById('maes-anio').value;
    const mes=document.getElementById('maes-mes').value;
    if(!anio.match(/^\d{4}$/)){toast('Año inválido','warning');return;}
    maesLog(`🚀 Generando HIS Proceso — Año: ${anio} | Mes: ${mes}`);
    const r=await fetch('/api/maestros/ejecutar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
        script:'scripts_python/ingesta/generar_his_proceso.py',
        args:[anio, mes]
    })});
    const d=await r.json();
    if(!r.ok){maesLog(`❌ Error: ${d.error||r.statusText}`);toast('Error','error');return;}
    maesLog('✅ Generación iniciada.');
    maesIniciarPolling(d.token);
}

async function maesRefrescarHISProceso(){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const anio=document.getElementById('maes-anio').value;
    const mes=document.getElementById('maes-mes').value;
    const objetivo=document.getElementById('maes-refresco-his').value;
    if(!anio.match(/^\d{4}$/)){toast('Año inválido','warning');return;}
    const mesArg=mes==='Todos'?'Todos':String(parseInt(mes));
    maesLog(`♻️ Refrescando HIS Proceso — Año: ${anio} | Mes: ${mesArg} | Objetivo: ${objetivo}`);
    const r=await fetch('/api/maestros/ejecutar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
        script:'scripts_python/ingesta/actualizar_his_proceso_maestros.py',
        args:[anio, mesArg, objetivo]
    })});
    const d=await r.json();
    if(!r.ok){maesLog(`❌ Error: ${d.error||r.statusText}`);toast('Error','error');return;}
    maesLog('✅ Refresco iniciado.');
    maesIniciarPolling(d.token);
}

async function maesActualizarRapido(){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    if(!S.maes.ruta){toast('Selecciona una carpeta primero','warning');return;}
    const selec=maesGetRapidoSeleccionados();
    if(!selec.length && S.maes.disponiblesRapido.length){toast('Selecciona al menos un maestro','warning');return;}
    const cargarTodos=S.maes.todosRapido||!S.maes.disponiblesRapido.length;
    const tablasSinEess=selec.filter(t=>t!=='eess2025');
    const requiereEess=selec.includes('eess2025');
    if(requiereEess && !tablasSinEess.length){
        maesLog('ℹ️ eess2025 se reconstruye desde maestros base (no desde CSV directo).');
    }else{
        maesLog(`🔄 Actualizando ${cargarTodos?'todos los maestros':tablasSinEess.join(', ')} desde CSV crudo...`);
        const args=[S.maes.ruta];
        if(!cargarTodos && tablasSinEess.length) args.push('--tablas', ...tablasSinEess);
        const r=await fetch('/api/maestros/ejecutar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
            script:'scripts_python/ingesta/cargar_maestros.py',
            args
        })});
        const d=await r.json();
        if(!r.ok){maesLog(`❌ Error: ${d.error||r.statusText}`);toast('Error','error');return;}
        maesLog('✅ Actualización rápida iniciada.');
        maesIniciarPolling(d.token,selec,requiereEess);
    }
}

let maesPollTimer=null;

function maesIniciarPolling(token,selec,requiereEess){
    if(maesPollTimer)clearInterval(maesPollTimer);
    S.pollLastLine[token]=0;
    const label=document.getElementById('maes-progress-label');
    const bar=document.getElementById('maes-progress-bar');
    const etaLabel=document.getElementById('maes-eta-label');
    maesPollTimer=setInterval(async()=>{
        try{
            const r=await fetch(`/api/ejecucion/status/${token}`);
            const s=await r.json();
            if(s.status==='starting'||s.status==='running'){
                label.textContent=s.status==='starting'?'Iniciando...':`Ejecutando: ${s.progress.done}/${s.progress.total||'?'}`;
                const pct=(s.progress.total>0)?(s.progress.done/s.progress.total)*100:0;
                bar.style.width=Math.min(pct,100)+'%';
                etaLabel.textContent=s.progress.eta?'ETA: '+s.progress.eta:'';
                const newLines=s.lines.slice(S.pollLastLine[token]||0);
                newLines.forEach(l=>maesLog(l));
                S.pollLastLine[token]=s.line_count;
            }else if(s.status==='completed'||s.status==='error'||s.status==='cancelled'){
                clearInterval(maesPollTimer);maesPollTimer=null;
                const newLines=s.lines.slice(S.pollLastLine[token]||0);
                newLines.forEach(l=>maesLog(l));
                S.pollLastLine[token]=s.line_count;
                if(s.status==='completed'){
                    label.textContent='✅ Completado';
                    bar.style.width='100%';
                    maesLog('✅ Proceso completado.');
                    if(requiereEess){
                        maesLog('ℹ️ Reconstruyendo eess2025 desde maestros base...');
                        const r2=await fetch('/api/maestros/ejecutar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
                            script:'scripts_python/ingesta/procesar_eess_principal.py',
                            args:[]
                        })});
                        const d2=await r2.json();
                        if(r2.ok)maesIniciarPolling(d2.token);
                        else maesLog('❌ Error al procesar EESS.');
                    }else if(selec && selec.length){
                        const lc=selec.map(s=>s.toLowerCase());
                        if(lc.some(s=>s.includes('maestro_his_establecimiento')||s.includes('susalud'))){
                            maesLog('ℹ️ Sugerencia: ejecuta "Procesar EESS principal" para reconstruir eess2025.');
                        }
                    }
                    setTimeout(()=>{maesActualizarAmbos();},1000);
                }else{
                    label.textContent='❌ Error';
                    maesLog(`❌ Proceso terminó con estado: ${s.status}`);
                }
                setTimeout(()=>{label.textContent='Progreso: en espera';bar.style.width='0%';etaLabel.textContent='ETA: --:--';},5000);
                delete S.pollLastLine[token];
            }
        }catch(e){/* ignore polling errors */}
    },800);
}

function maesGetRapidoSeleccionados(){
    if(S.maes.todosRapido) return [...S.maes.disponiblesRapido];
    return Object.keys(S.maes.estadoRapido).filter(t=>S.maes.estadoRapido[t]);
}

function maesEditarScript(titulo,ruta){
    // Opens the editor modal for a maestro script
    const btn=document.getElementById('btn-editor');
    if(btn)btn.click();
    // After login, navigate to the file
    setTimeout(()=>{abrirEditor(ruta,titulo);},1000);
}

// Watch S.editorMode for maestro edit buttons
setInterval(()=>{
    const e=document.getElementById('btn-maes-editar-eess');
    const e2=document.getElementById('btn-maes-editar-his2');
    if(e)e.style.display=S.editorMode?'':'none';
    if(e2)e2.style.display=S.editorMode?'':'none';
},2000);

function maesMostrarMenuRapido(){
    const names=S.maes.disponiblesRapido;
    if(!names||!names.length){
        toast('No hay maestros cargados en BD. Actualiza la lista primero.','warning');
        return;
    }
    openModal('modal-maes-menu');
    document.getElementById('maes-menu-title').textContent='Seleccionar maestros para actualización rápida';
    const container=document.getElementById('maes-menu-body');
    container.innerHTML='';
    const cbAll=document.createElement('label');
    cbAll.style.cssText='display:flex;align-items:center;gap:6px;padding:6px 4px;font-weight:bold;';
    const chkAll=document.createElement('input');
    chkAll.type='checkbox';
    chkAll.checked=S.maes.todosRapido;
    chkAll.addEventListener('change',()=>{
        const val=chkAll.checked;
        S.maes.todosRapido=val;
        container.querySelectorAll('.maes-menu-item input').forEach(cb=>{cb.checked=val;});
        names.forEach(n=>{S.maes.estadoRapido[n]=val;});
        maesActualizarBtnRapido();
    });
    cbAll.appendChild(chkAll);
    cbAll.appendChild(document.createTextNode('Todos los maestros'));
    container.appendChild(cbAll);
    names.forEach(n=>{
        const label=document.createElement('label');
        label.className='maes-menu-item';
        label.style.cssText='display:flex;align-items:center;gap:6px;padding:3px 8px;cursor:pointer;';
        const cb=document.createElement('input');
        cb.type='checkbox';
        cb.checked=S.maes.estadoRapido[n]!==false;
        cb.addEventListener('change',()=>{
            S.maes.estadoRapido[n]=cb.checked;
            S.maes.todosRapido=names.every(t=>S.maes.estadoRapido[t]);
            chkAll.checked=S.maes.todosRapido;
            maesActualizarBtnRapido();
        });
        label.appendChild(cb);
        label.appendChild(document.createTextNode(' '+n));
        container.appendChild(label);
    });
}

function maesActualizarBtnRapido(){
    const btn=document.getElementById('btn-maes-rapido-select');
    if(!btn)return;
    const selec=maesGetRapidoSeleccionados();
    if(!S.maes.disponiblesRapido.length)btn.textContent='Todos los maestros';
    else if(S.maes.todosRapido)btn.textContent='Todos los maestros';
    else if(selec.length===1)btn.textContent=selec[0];
    else btn.textContent=`${selec.length} maestros (${selec.slice(0,2).join(', ')}${selec.length>2?'...':''})`;
}

// ==================== EDITOR ====================
document.getElementById('btn-editor').addEventListener('click',()=>{
    if(S.editorMode){desactivarEditor();return;}
    openModal('modal-login');document.getElementById('editor-user').focus();
});

async function editorLogin(){
    const r=await fetch('/api/editor/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({usuario:document.getElementById('editor-user').value,password:document.getElementById('editor-pass').value})});
    const d=await r.json();
    if(d.exito){
        closeModal('modal-login');
        S.editorMode=true;
        document.getElementById('btn-editor').textContent='🛠️ Editor ACTIVO';
        document.getElementById('btn-editor').className='btn-editor active';
        document.getElementById('rep-editor-panel').style.display='block';
        toast('Modo Editor activado','success');
        renderReportes();
        abrirGestorScripts();
    }else{
        document.getElementById('editor-login-error').textContent='Credenciales inválidas';
        document.getElementById('editor-login-error').style.display='block';
    }
}

function desactivarEditor(){
    S.editorMode=false;
    document.getElementById('btn-editor').textContent='🛠️ Modo Editor';
    document.getElementById('btn-editor').className='btn-editor';
    document.getElementById('rep-editor-panel').style.display='none';
    fetch('/api/editor/logout',{method:'POST'});
    toast('Editor desactivado','info');
    renderReportes();
}

function abrirGestorScripts(){
    openModal('modal-gestor');
    cargarGestor();
}

async function cargarGestor(){
    try{
        const r=await fetch('/api/editor/scripts');const d=await r.json();
        const rdiv=document.getElementById('gestor-reportes');rdiv.innerHTML='';
        (d.reportes||[]).forEach((item,i)=>{
            const div=document.createElement('div');div.className='script-item';
            div.innerHTML=`<span class="script-name">${item.nombre||item.script}</span>
                <div class="script-actions">
                    <button class="btn-sm" style="background:#34495E;color:#fff;" onclick="abrirEditor('${item.script.replace(/'/g,"\\'")}','${(item.nombre||item.script).replace(/'/g,"\\'")}')">✏️</button>
                    ${item.custom?`<button class="btn-sm" style="background:#922B21;color:#fff;" onclick="eliminarReporte(${i})">🗑️</button>`:''}
                </div>`;
            rdiv.appendChild(div);
        });
        const mdiv=document.getElementById('gestor-maestros');mdiv.innerHTML='';
        (d.maestros||[]).forEach(item=>{
            const div=document.createElement('div');div.className='script-item';
            div.innerHTML=`<span class="script-name">${item.nombre}</span>
                <div class="script-actions">
                    <button class="btn-sm" style="background:#34495E;color:#fff;" onclick="abrirEditor('${(item.sql_editor||item.script).replace(/'/g,"\\'")}','${item.nombre.replace(/'/g,"\\'")}')">✏️</button>
                </div>`;
            mdiv.appendChild(div);
        });
    }catch(e){console.error(e)}
}

let editingPath='';

async function abrirEditor(ruta,nombre){
    editingPath=ruta;
    document.getElementById('modal-editor-title').textContent=`📝 Editor - ${nombre||ruta}`;
    document.getElementById('editor-script-path').textContent=ruta;
    try{
        const r=await fetch('/api/editor/script-content',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({ruta})});
        const d=await r.json();
        document.getElementById('editor-code').value=d.contenido||'';
    }catch(e){document.getElementById('editor-code').value='-- Error al cargar';}
    openModal('modal-editor');
}

async function guardarScript(){
    await fetch('/api/editor/script-save',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({ruta:editingPath,contenido:document.getElementById('editor-code').value})});
    toast('Guardado','success');
    closeModal('modal-editor');
}

async function restaurarOriginales(){
    if(!confirm('¿Restaurar scripts originales? Se perderán las modificaciones.'))return;
    await fetch('/api/editor/restore',{method:'POST'});
    toast('Scripts restaurados','success');
    cargarGestor();cargarReportes();
}

// ==================== CANCEL ====================
document.getElementById('btn-cancelar').addEventListener('click',()=>{
    toast('Cancelando proceso...','warning');
    logAll('🛑 Cancelando proceso por solicitud del usuario...');
    fetch('/api/ejecucion/cancel',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:S.activeToken})});
    stopPolling();
    S.ejecutando=false;
    document.getElementById('btn-cancelar').style.display='none';
    document.getElementById('global-status').textContent='⛔ Cancelado';
    document.getElementById('global-status').style.color='#E74C3C';
});

function logAll(line){
    const cls=logClass(line);
    logBD(line,cls);
    logIng(line,cls);
    logMaes(line,cls);
    logGlobal(line);
}

// ==================== TUNNEL ====================
async function checkTunnelStatus(){
    try{
        const r=await fetch('/api/tunnel/status'); const d=await r.json();
        const status=document.getElementById('tunnel-status');
        const urlBox=document.getElementById('tunnel-url-box');
        const btn=document.getElementById('btn-tunnel-toggle');
        if(d.activo){
            status.innerHTML='🟢 <strong>Activo</strong>';
            status.style.color='#2ECC71';
            urlBox.style.display='block';
            urlBox.innerHTML=`🔗 <a href="${d.url}" target="_blank" style="color:#2ECC71;">${d.url}</a><br><small style="color:var(--text-muted)">Comparte este enlace para que accedan desde cualquier lugar</small>`;
            btn.textContent='⏹ DETENER TUNNEL';
            btn.style.background='#E74C3C';
        }else{
            status.innerHTML='🔴 <strong>Inactivo</strong>';
            status.style.color='var(--text-muted)';
            urlBox.style.display='none';
            btn.textContent='🌐 INICIAR TUNNEL';
            btn.style.background='#1a73e8';
        }
    }catch(e){}
}

async function toggleTunnel(){
    const btn=document.getElementById('btn-tunnel-toggle');
    const status=document.getElementById('tunnel-status');
    try{
        const r=await fetch('/api/tunnel/status'); const cur=await r.json();
        if(cur.activo){
            btn.disabled=true; btn.textContent='⏳ Deteniendo...';
            await fetch('/api/tunnel/stop',{method:'POST'});
            checkTunnelStatus();
            toast('Tunnel detenido','info');
        }else{
            btn.disabled=true; btn.textContent='⏳ Iniciando...';
            status.innerHTML='⏳ <strong>Iniciando tunnel...</strong>'; status.style.color='orange';
            const r2=await fetch('/api/tunnel/start',{method:'POST'}); const d=await r2.json();
            if(!d.exito){
                status.innerHTML='❌ <strong>Error: '+d.mensaje+'</strong>'; status.style.color='#E74C3C';
                toast('Error: '+d.mensaje,'error');
                btn.disabled=false; return;
            }
            // Poll for URL
            for(let i=0;i<30;i++){
                await new Promise(r=>setTimeout(r,1000));
                const r3=await fetch('/api/tunnel/url'); const u=await r3.json();
                if(u.listo){
                    checkTunnelStatus();
                    toast('✅ Sistema publicado en: '+u.url,'success');
                    navigator.clipboard?.writeText(u.url);
                    btn.disabled=false;
                    return;
                }
                if(i%5===0) status.innerHTML='⏳ <strong>Generando URL ('+(i+1)+'s)...</strong>';
            }
            status.innerHTML='❌ <strong>Timeout - revisa tunnel/tunnel.log</strong>'; status.style.color='#E74C3C';
            toast('Timeout esperando URL','error');
        }
    }catch(e){toast('Error: '+e.message,'error')}
    btn.disabled=false;
}

// ==================== INIT ====================
async function init(){
    await cargarConfigBD();
    await detectarBD();
    await cargarReportes();
    checkTunnelStatus();
}

init();

// Tunnel nav button
document.getElementById('btn-tunnel')?.addEventListener('click',()=>{
    document.querySelectorAll('.nav-btn').forEach(b=>b.classList.remove('active'));
    document.getElementById('btn-nav-bd').classList.add('active');
    document.querySelectorAll('.module').forEach(m=>m.classList.remove('active'));
    document.getElementById('module-bd').classList.add('active');
    checkTunnelStatus();
});
