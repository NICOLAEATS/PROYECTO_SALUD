# Tunnel Cloudflare - Acceso Publico

## Que hace?
Crea un tunel desde tu PC hacia Internet. Cualquier persona con la URL puede usar tu sistema en su navegador.

## Requisitos
- Windows 10/11
- Servidor Flask corriendo (http://localhost:5000)
- Internet

## Como usar

### Opcion 1: Script PowerShell (recomendado)
Haz doble clic en `start_tunnel.ps1` o ejecuta:
```powershell
powershell -ExecutionPolicy Bypass -File tunnel\start_tunnel.ps1
```

### Opcion 2: Batch
```cmd
tunnel\start_tunnel.bat
```

### Opcion 3: Manual (mas control)
```cmd
tunnel\cloudflared.exe tunnel --url http://127.0.0.1:5000
```

## Que pasa despues?
- Se abre una terminal con la URL publica (ej: `https://palabras-random.trycloudflare.com`)
- Copias esa URL y se la mandas a quien necesite acceder
- Mientras la ventana este abierta, el sistema es accesible desde internet
- Cuando cierras la ventana, el tunel se cierra

## Notas
- La URL cambia cada vez que inicias el tunel (es temporal y gratis)
- Para URL fija (ej: `tusistema.com`) necesitas cuenta Cloudflare + dominio
- El tunel gratis no tiene garantia de uptime
- cloudflared se descarga automaticamente la primera vez
