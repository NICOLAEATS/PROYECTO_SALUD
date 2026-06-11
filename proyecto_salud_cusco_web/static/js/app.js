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
function toast(m,t='info'){const c=document.getElementById('toast-container'),e=document.createElement('div');e.className=`toast ${t}`;e.textContent=m;c.appendChild(e);setTimeout(()=>{e.style.opacity='0';e.style.transition='opacity .3s';setTimeout(()=>e.remove(),300)},4000)}

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
}

// ==================== THEME ====================
document.getElementById('theme-toggle').addEventListener('click',()=>{
    const h=document.documentElement;
    const n=h.getAttribute('data-theme')==='dark'?'light':'dark';
    h.setAttribute('data-theme',n);
    document.getElementById('theme-toggle').textContent=n==='dark'?'🌙':'☀️';
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
    S.activeToken = 0;
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
document.getElementById('btn-ing-carpeta').addEventListener('click',()=>{
    const inp=document.createElement('input');inp.type='file';inp.webkitdirectory=true;
    inp.onchange=e=>{
        if(e.target.files.length>0){
            const path=e.target.files[0].webkitRelativePath.split('/')[0];
            document.getElementById('ing-lbl-ruta').textContent=`📁 Atenciones: .../${path}`;
            document.getElementById('ing-lbl-ruta').style.color='#2ECC71';
            toast('Carpeta seleccionada','info');
        }
    };
    inp.click();
});
document.getElementById('btn-ing-ruta-auto').addEventListener('click',()=>{
    document.getElementById('ing-lbl-ruta').textContent='📁 Atenciones: automática';
    document.getElementById('ing-lbl-ruta').style.color='var(--text-muted)';
    toast('Ruta automática','info');
});

document.getElementById('ing-btn-importar').addEventListener('click',()=>{
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const anio=document.getElementById('ing-anio').value;
    const meses=S.meses;
    const nombre=meses.length===12?`Importar HIS ${anio}`:`Importar ${anio} (${meses.length} meses)`;

    ingProgressReset(nombre);
    document.getElementById('ing-status').className='status-indicator warning';
    document.getElementById('ing-status-text').textContent=`Ejecutando ${nombre}...`;

    ejecutarConPolling(nombre,
        fetch('/api/ingesta/import',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({anio,meses,ruta_crudos:S.rutaCrudos||''})}),
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
async function cargarMaestros(){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const tbody=document.getElementById('maes-tbody');tbody.innerHTML='<tr><td colspan="3" style="text-align:center;">Cargando...</td></tr>';
    try{
        const r=await fetch('/api/maestros/tablas');const tablas=await r.json();
        tbody.innerHTML='';
        if(tablas.error){tbody.innerHTML=`<tr><td colspan="3" style="color:#E74C3C;">${tablas.error}</td></tr>`;return;}
        if(!tablas.length){tbody.innerHTML='<tr><td colspan="3" style="text-align:center;color:var(--text-muted);">No hay tablas en el esquema</td></tr>';return;}
        tablas.forEach(t=>{const tr=document.createElement('tr');tr.innerHTML=`<td>${t.nombre}</td><td>${t.esquema}</td><td class="status-active">✅ Activo</td>`;tbody.appendChild(tr)});
    }catch(e){tbody.innerHTML=`<tr><td colspan="3" style="color:#E74C3C;">${e.message}</td></tr>`}
}

document.getElementById('maes-filtro').addEventListener('input',function(){
    const q=this.value.toLowerCase();
    document.querySelectorAll('#maes-tbody tr').forEach(tr=>{tr.style.display=tr.textContent.toLowerCase().includes(q)?'':'none'});
});

function ejecutarScript(ruta){
    if(!S.bdOk){toast('BD no conectada','warning');return;}
    const nombre=ruta.split('/').pop().replace('.py','');
    logMaes(`▶️ Ejecutando ${nombre}...`,'log-info');

    ejecutarConPolling(nombre,
        fetch('/api/maestros/ejecutar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({script:ruta})}),
        logMaes
    );
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

// ==================== INIT ====================
async function init(){
    await cargarConfigBD();
    await detectarBD();
    await cargarReportes();
}

init();
