# Construir.ps1 v4 - Here-strings comilla simple, sin emojis en fuente PS1
# Emojis van como entidades HTML: &#127916; etc.

$ErrorActionPreference = 'Stop'
$REPO = 'https://github.com/ojairnp/GeneradorVideo.git'
$ENC  = [System.Text.UTF8Encoding]::new($false)

function W {
    param([string]$ruta, [string]$contenido)
    $dir = Split-Path (Join-Path $PWD.Path $ruta)
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    [System.IO.File]::WriteAllText(
        (Join-Path $PWD.Path $ruta),
        $contenido,
        $ENC
    )
    Write-Host "  OK: $ruta" -ForegroundColor Green
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  GENERADOR VIDEO v4 - Agnes AI"             -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# --- GIT ---
Write-Host "[1/7] Verificando Git..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: Instala Git en https://git-scm.com" -ForegroundColor Red
    Read-Host "Enter"; exit 1
}
Write-Host "  OK: $(git --version)" -ForegroundColor Green

# --- CARPETAS ---
Write-Host "[2/7] Carpetas..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path ".github\workflows" | Out-Null
Write-Host "  OK: .github/workflows/" -ForegroundColor Green

# ─────────────────────────────────────────────────────────
# INDEX.HTML
# ─────────────────────────────────────────────────────────
Write-Host "[3/7] index.html..." -ForegroundColor Yellow

W "index.html" @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GeneradorVideo - Agnes AI</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
<div class="app">

  <header>
    <div class="logo">
      <span class="logo-icon">&#127916;</span>
      <span class="logo-text">GeneradorVideo</span>
      <span class="logo-badge">Agnes AI</span>
    </div>
    <button class="btn-cfg" id="btnConfig">&#9881; API Key</button>
  </header>

  <main>

    <section class="upload-zone" id="uploadZone">
      <div class="upload-inner" id="uploadInner">
        <div class="upload-icon">&#128248;</div>
        <p class="up-title">Arrastra tu foto aqui</p>
        <p class="up-sub">o haz clic para seleccionar</p>
        <p class="up-hint">JPG o PNG - Horizontal 16:9 recomendado</p>
      </div>
      <img id="imgPreview" class="img-preview hidden" alt="preview">
      <button class="btn-cambiar hidden" id="btnCambiar">&#128260; Cambiar foto</button>
      <input type="file" id="fileInput" accept="image/*" hidden>
    </section>

    <section class="card">
      <label class="lbl">&#127919; Describe el video</label>
      <textarea id="promptInput" rows="3"
        placeholder="Ej: Modelo corriendo con ropa deportiva azul, movimiento cinematico, luz natural..."></textarea>
      <p class="hint">Puedes dejarlo vacio para usar el prompt automatico.</p>
    </section>

    <section class="card">
      <details>
        <summary>&#9881; Ajustes del video</summary>
        <div class="settings">

          <div class="setting-row">
            <div>
              <label>Duracion</label>
              <span class="setting-desc">Cantidad de frames</span>
            </div>
            <select id="numFrames">
              <option value="49">Corto - 49 frames (~4s)</option>
              <option value="81" selected>Medio - 81 frames (~6s)</option>
              <option value="121">Largo - 121 frames (~8s)</option>
            </select>
          </div>

          <div class="setting-row">
            <div>
              <label>Frames por segundo</label>
              <span class="setting-desc">Velocidad de reproduccion</span>
            </div>
            <div class="range-wrap">
              <input type="range" id="fps" min="8" max="24" value="16">
              <span id="fpsVal">16</span>
            </div>
          </div>

          <div class="setting-row">
            <div>
              <label>Resolucion</label>
              <span class="setting-desc">Tamano del video</span>
            </div>
            <select id="resolucion">
              <option value="480">480p - Rapido</option>
              <option value="720" selected>720p - Recomendado</option>
              <option value="1080">1080p - Lento pero HD</option>
            </select>
          </div>

        </div>
      </details>
    </section>

    <button class="btn-generar" id="btnGenerar" disabled>
      &#10024; Generar Video con Agnes AI
    </button>

    <section class="card card-progress hidden" id="secProgress">
      <div class="spinner"></div>
      <p class="progress-txt" id="progressTxt">Iniciando...</p>
      <div class="bar-wrap"><div class="bar" id="bar"></div></div>
      <p class="progress-hint">Agnes AI genera en la nube - tarda entre 1 y 4 minutos</p>
    </section>

    <section class="card card-result hidden" id="secResult">
      <p class="result-tag">&#127881; Video listo con Agnes AI</p>
      <video id="videoPlayer" controls autoplay loop playsinline></video>
      <div class="result-btns">
        <button class="btn-dl" id="btnDescargar">&#11015; Descargar MP4</button>
        <button class="btn-nuevo" id="btnNuevo">&#128260; Nuevo video</button>
      </div>
    </section>

  </main>
</div>

<!-- MODAL API KEY -->
<div class="overlay hidden" id="modalOverlay">
  <div class="modal">
    <div class="modal-hdr">
      <h3>&#128273; API Key de Agnes AI</h3>
      <button class="btn-close" id="btnClose">X</button>
    </div>

    <div class="steps">
      <div class="step">
        <span class="n">1</span>
        <p>Crea cuenta gratis en
          <a href="https://platform.agnes-ai.com" target="_blank">platform.agnes-ai.com</a>
          - sin tarjeta
        </p>
      </div>
      <div class="step">
        <span class="n">2</span>
        <p>Ve a
          <a href="https://platform.agnes-ai.com/settings/apiKeys" target="_blank">
            Settings - API Keys - Create Key
          </a>
        </p>
      </div>
      <div class="step">
        <span class="n">3</span>
        <p>Pega tu token (empieza con <strong>sk-</strong>):</p>
      </div>
    </div>

    <input type="password" id="keyInput" placeholder="sk-xxxxxxxxxxxxxxxxxxxxxxxx">

    <div class="badges">
      <span class="badge green">&#9989; 100% Gratis</span>
      <span class="badge green">&#127916; Sin limite</span>
      <span class="badge green">&#128683; Sin marca de agua</span>
    </div>

    <button class="btn-guardar" id="btnGuardar">&#128190; Guardar key</button>
    <p class="security">&#128274; Tu key se guarda solo en tu navegador.</p>
  </div>
</div>

<script src="app.js"></script>
</body>
</html>
'@

# ─────────────────────────────────────────────────────────
# STYLE.CSS
# ─────────────────────────────────────────────────────────
Write-Host "[4/7] style.css..." -ForegroundColor Yellow

W "style.css" @'
:root {
  --bg:     #07070f;
  --card:   #111120;
  --card2:  #1a1a2e;
  --accent: #ff4d00;
  --green:  #22c55e;
  --purple: #a855f7;
  --text:   #f0f0f0;
  --text2:  #777;
  --border: #252535;
  --r:      14px;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: "Segoe UI", system-ui, sans-serif;
  min-height: 100vh;
  line-height: 1.55;
}

.app { max-width: 680px; margin: 0 auto; padding: 0 16px 80px; }

/* HEADER */
header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 22px 0 24px;
  border-bottom: 1px solid var(--border);
  margin-bottom: 26px;
}
.logo { display: flex; align-items: center; gap: 10px; }
.logo-icon { font-size: 1.5rem; }
.logo-text {
  font-size: 1.25rem;
  font-weight: 800;
  background: linear-gradient(135deg, var(--accent), #ff9d4d, var(--purple));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.logo-badge {
  background: rgba(34,197,94,.15);
  border: 1px solid rgba(34,197,94,.3);
  color: var(--green);
  border-radius: 20px;
  padding: 3px 10px;
  font-size: 0.7rem;
  font-weight: 700;
}
.btn-cfg {
  background: var(--card2);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text2);
  padding: 7px 14px;
  font-size: .85rem;
  cursor: pointer;
  transition: all .2s;
}
.btn-cfg:hover { border-color: var(--accent); color: var(--accent); }

/* CARD */
.card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 20px;
  margin-bottom: 14px;
}

/* UPLOAD */
.upload-zone {
  background: var(--card);
  border: 2px dashed var(--border);
  border-radius: var(--r);
  min-height: 210px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: border-color .2s, background .2s;
  overflow: hidden;
  position: relative;
  margin-bottom: 14px;
}
.upload-zone:hover,
.upload-zone.active { border-color: var(--accent); background: rgba(255,77,0,.04); }
.upload-inner { text-align: center; padding: 28px 20px; pointer-events: none; }
.upload-icon { font-size: 3rem; margin-bottom: 12px; }
.up-title { font-size: 1.05rem; font-weight: 600; margin-bottom: 6px; }
.up-sub { color: var(--accent); font-size: .88rem; margin-bottom: 10px; }
.up-hint { color: var(--text2); font-size: .75rem; }
.img-preview {
  width: 100%;
  max-height: 360px;
  object-fit: contain;
  border-radius: calc(var(--r) - 2px);
}
.btn-cambiar {
  position: absolute;
  bottom: 10px; right: 10px;
  background: rgba(0,0,0,.75);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text);
  padding: 6px 12px;
  font-size: .78rem;
  cursor: pointer;
}
.btn-cambiar:hover { background: var(--card2); }

/* TEXTAREA */
.lbl { display: block; font-size: .85rem; color: var(--text2); font-weight: 500; margin-bottom: 9px; }
.hint { font-size: .73rem; color: var(--text2); margin-top: 7px; }
textarea {
  width: 100%;
  background: var(--card2);
  border: 1px solid var(--border);
  border-radius: 10px;
  color: var(--text);
  padding: 12px 14px;
  font-size: .9rem;
  resize: vertical;
  font-family: inherit;
  transition: border-color .2s;
  min-height: 78px;
}
textarea:focus { outline: none; border-color: var(--accent); }
textarea::placeholder { color: var(--text2); }

/* SETTINGS */
details > summary {
  font-size: .88rem;
  color: var(--text2);
  cursor: pointer;
  list-style: none;
  user-select: none;
}
details > summary::-webkit-details-marker { display: none; }
details[open] > summary { color: var(--text); margin-bottom: 18px; }
.settings { display: flex; flex-direction: column; gap: 16px; }
.setting-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.setting-row > div { flex: 1; }
.setting-row label { font-size: .86rem; display: block; margin-bottom: 2px; }
.setting-desc { font-size: .73rem; color: var(--text2); }
.range-wrap { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.range-wrap span {
  min-width: 28px;
  text-align: right;
  font-size: .82rem;
  color: var(--accent);
  font-weight: 700;
}
input[type=range] {
  -webkit-appearance: none;
  width: 110px;
  height: 4px;
  background: var(--border);
  border-radius: 2px;
  cursor: pointer;
}
input[type=range]::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 15px; height: 15px;
  background: var(--accent);
  border-radius: 50%;
  cursor: pointer;
}
select {
  background: var(--card2);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text);
  padding: 7px 11px;
  font-size: .82rem;
  cursor: pointer;
  outline: none;
}

/* BOTON GENERAR */
.btn-generar {
  width: 100%;
  background: linear-gradient(135deg, var(--accent), #ff7a3d);
  border: none;
  border-radius: var(--r);
  color: #fff;
  font-size: 1.08rem;
  font-weight: 700;
  padding: 16px;
  cursor: pointer;
  transition: opacity .2s, transform .15s, box-shadow .2s;
  margin-bottom: 14px;
  box-shadow: 0 4px 22px rgba(255,77,0,.28);
}
.btn-generar:hover:not(:disabled) {
  opacity: .9;
  transform: translateY(-2px);
  box-shadow: 0 6px 26px rgba(255,77,0,.38);
}
.btn-generar:disabled { opacity: .3; cursor: not-allowed; transform: none; box-shadow: none; }

/* PROGRESO */
.card-progress { text-align: center; }
.spinner {
  width: 42px; height: 42px;
  border: 3px solid var(--border);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin .85s linear infinite;
  margin: 0 auto 14px;
}
@keyframes spin { to { transform: rotate(360deg); } }
.progress-txt { font-size: .92rem; margin-bottom: 13px; }
.bar-wrap {
  background: var(--border);
  border-radius: 4px;
  height: 4px;
  overflow: hidden;
  margin-bottom: 10px;
}
.bar {
  height: 100%;
  width: 0%;
  background: linear-gradient(90deg, var(--accent), var(--purple));
  transition: width 1.2s ease;
  border-radius: 4px;
}
.progress-hint { color: var(--text2); font-size: .75rem; }

/* RESULTADO */
.result-tag {
  font-size: .78rem;
  color: var(--green);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin-bottom: 13px;
}
video {
  width: 100%;
  border-radius: 10px;
  background: #000;
  display: block;
  margin-bottom: 14px;
}
.result-btns { display: flex; gap: 10px; }
.btn-dl {
  flex: 1;
  background: var(--green);
  border: none;
  border-radius: 10px;
  color: #000;
  font-weight: 700;
  padding: 13px;
  cursor: pointer;
  font-size: .92rem;
  transition: opacity .2s;
}
.btn-dl:hover { opacity: .88; }
.btn-nuevo {
  background: var(--card2);
  border: 1px solid var(--border);
  border-radius: 10px;
  color: var(--text2);
  padding: 13px 18px;
  cursor: pointer;
  font-size: .88rem;
  transition: all .2s;
}
.btn-nuevo:hover { border-color: var(--text2); color: var(--text); }

/* MODAL */
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,.88);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
  padding: 20px;
}
.modal {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 26px;
  max-width: 440px;
  width: 100%;
}
.modal-hdr {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}
.modal-hdr h3 { font-size: 1.05rem; }
.btn-close {
  background: var(--card2);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text2);
  width: 28px; height: 28px;
  cursor: pointer;
  font-size: .82rem;
}
.steps { display: flex; flex-direction: column; gap: 10px; margin-bottom: 18px; }
.step { display: flex; align-items: flex-start; gap: 11px; }
.n {
  background: var(--accent);
  color: #fff;
  width: 21px; height: 21px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: .72rem;
  font-weight: 700;
  flex-shrink: 0;
  margin-top: 1px;
}
.step p { font-size: .85rem; color: var(--text2); }
.step a { color: var(--accent); text-decoration: none; }
.step a:hover { text-decoration: underline; }
#keyInput {
  width: 100%;
  background: var(--card2);
  border: 1px solid var(--border);
  border-radius: 10px;
  color: var(--text);
  padding: 11px 13px;
  font-size: .88rem;
  font-family: monospace;
  margin-bottom: 13px;
  transition: border-color .2s;
}
#keyInput:focus { outline: none; border-color: var(--accent); }
#keyInput::placeholder { color: var(--text2); font-family: inherit; }
.badges { display: flex; flex-wrap: wrap; gap: 7px; margin-bottom: 16px; }
.badge {
  border-radius: 20px;
  padding: 4px 11px;
  font-size: .74rem;
  font-weight: 500;
}
.badge.green {
  background: rgba(34,197,94,.1);
  border: 1px solid rgba(34,197,94,.25);
  color: var(--green);
}
.btn-guardar {
  width: 100%;
  background: linear-gradient(135deg, var(--accent), #ff7a3d);
  border: none;
  border-radius: 10px;
  color: #fff;
  font-weight: 700;
  padding: 12px;
  cursor: pointer;
  font-size: .92rem;
  margin-bottom: 13px;
  transition: opacity .2s;
}
.btn-guardar:hover { opacity: .9; }
.security { font-size: .72rem; color: var(--text2); text-align: center; }

/* UTILS */
.hidden { display: none !important; }

@media (max-width: 480px) {
  .setting-row { flex-direction: column; align-items: flex-start; }
  input[type=range] { width: 100%; }
  .result-btns { flex-direction: column; }
}
'@

# ─────────────────────────────────────────────────────────
# APP.JS
# ─────────────────────────────────────────────────────────
Write-Host "[5/7] app.js..." -ForegroundColor Yellow

W "app.js" @'
// ============================================================
// GeneradorVideo - app.js
// API: Agnes AI (apihub.agnes-ai.com) - GRATIS SIN LIMITE
// Imagen -> URL publica (tmpfiles.org) -> Agnes Video
// ============================================================

// GitHub Actions reemplaza AGNES_KEY_PLACEHOLDER con el secret
// Si no hubo deploy de Actions, el usuario ingresa la key manual
const AGNES_INJECTED = "AGNES_KEY_PLACEHOLDER";
const AGNES_VIDEO    = "https://apihub.agnes-ai.com/v1/videos";
const TMPFILES_UP    = "https://tmpfiles.org/api/v1/upload";

let imageDataUrl   = null;
let imagePublicUrl = null;
let currentVideo   = null;

// ─── DOM ───────────────────────────────────────────────
const $ = id => document.getElementById(id);

const uploadZone  = $("uploadZone");
const uploadInner = $("uploadInner");
const fileInput   = $("fileInput");
const imgPreview  = $("imgPreview");
const btnCambiar  = $("btnCambiar");
const promptInput = $("promptInput");
const numFramesSel= $("numFrames");
const fpsSlider   = $("fps");
const fpsVal      = $("fpsVal");
const resolucion  = $("resolucion");
const btnGenerar  = $("btnGenerar");
const secProgress = $("secProgress");
const progressTxt = $("progressTxt");
const bar         = $("bar");
const secResult   = $("secResult");
const videoPlayer = $("videoPlayer");
const btnDescargar= $("btnDescargar");
const btnNuevo    = $("btnNuevo");
const modalOverlay= $("modalOverlay");
const btnConfig   = $("btnConfig");
const btnClose    = $("btnClose");
const keyInput    = $("keyInput");
const btnGuardar  = $("btnGuardar");

// ─── API KEY ───────────────────────────────────────────
function getKey() {
    const local     = localStorage.getItem("agnesKey");
    const inyectada = AGNES_INJECTED !== "AGNES_KEY_PLACEHOLDER"
                      ? AGNES_INJECTED : null;
    return local || inyectada || null;
}

// ─── UPLOAD ────────────────────────────────────────────
uploadZone.addEventListener("click", () => {
    if (!imageDataUrl) fileInput.click();
});
fileInput.addEventListener("change", e => {
    if (e.target.files[0]) procesarArchivo(e.target.files[0]);
});
uploadZone.addEventListener("dragover", e => {
    e.preventDefault();
    uploadZone.classList.add("active");
});
uploadZone.addEventListener("dragleave", () => {
    uploadZone.classList.remove("active");
});
uploadZone.addEventListener("drop", e => {
    e.preventDefault();
    uploadZone.classList.remove("active");
    const f = e.dataTransfer.files[0];
    if (f && f.type.startsWith("image/")) procesarArchivo(f);
});
btnCambiar.addEventListener("click", e => {
    e.stopPropagation();
    fileInput.click();
});

function procesarArchivo(file) {
    if (file.size > 15 * 1024 * 1024) {
        alert("Imagen muy grande. Maximo 15MB.");
        return;
    }
    const reader = new FileReader();
    reader.onload = async e => {
        imageDataUrl   = await redimensionar(e.target.result);
        imagePublicUrl = null;
        imgPreview.src = imageDataUrl;
        imgPreview.classList.remove("hidden");
        uploadInner.classList.add("hidden");
        btnCambiar.classList.remove("hidden");
        btnGenerar.disabled = false;
    };
    reader.readAsDataURL(file);
}

function redimensionar(dataUrl) {
    return new Promise(resolve => {
        const img = new Image();
        img.onload = () => {
            let w = img.width;
            let h = img.height;
            const MAX = 1280;
            if (w > MAX || h > MAX) {
                const s = Math.min(MAX / w, MAX / h);
                w = Math.round(w * s);
                h = Math.round(h * s);
            }
            w = Math.floor(w / 8) * 8 || 64;
            h = Math.floor(h / 8) * 8 || 64;
            const c = document.createElement("canvas");
            c.width = w;
            c.height = h;
            c.getContext("2d").drawImage(img, 0, 0, w, h);
            resolve(c.toDataURL("image/jpeg", 0.92));
        };
        img.src = dataUrl;
    });
}

// ─── SLIDER FPS ────────────────────────────────────────
fpsSlider.addEventListener("input", () => {
    fpsVal.textContent = fpsSlider.value;
});

// ─── MODAL KEY ─────────────────────────────────────────
btnConfig.addEventListener("click",  abrirModal);
btnClose.addEventListener("click",   cerrarModal);
modalOverlay.addEventListener("click", e => {
    if (e.target === modalOverlay) cerrarModal();
});

function abrirModal() {
    const saved = localStorage.getItem("agnesKey");
    if (saved) keyInput.value = saved;
    modalOverlay.classList.remove("hidden");
    setTimeout(() => keyInput.focus(), 100);
}
function cerrarModal() {
    modalOverlay.classList.add("hidden");
}

btnGuardar.addEventListener("click", () => {
    const k = keyInput.value.trim();
    if (!k) { alert("Pega tu API Key de Agnes."); return; }
    if (!k.startsWith("sk-")) {
        alert("El token de Agnes debe comenzar con sk-\n\nObtenlo gratis en:\nplatform.agnes-ai.com/settings/apiKeys");
        return;
    }
    localStorage.setItem("agnesKey", k);
    cerrarModal();
    alert("Key guardada. Ya puedes generar videos gratis con Agnes AI.");
});

// ─── SUBIR IMAGEN A HOST PUBLICO ───────────────────────
// Agnes necesita URL publica, no base64
// tmpfiles.org - gratis, sin key, expira en 1 hora
async function subirImagen(dataUrl) {
    mostrarProgreso("Subiendo imagen al servidor temporal...", 12);

    const partes = dataUrl.split(",");
    const mime   = partes[0].match(/:(.*?);/)[1];
    const bytes  = atob(partes[1]);
    const arr    = new Uint8Array(bytes.length);
    for (let i = 0; i < bytes.length; i++) arr[i] = bytes.charCodeAt(i);
    const blob = new Blob([arr], { type: mime });

    const fd = new FormData();
    fd.append("file", blob, "foto.jpg");

    let res;
    try {
        res = await fetch(TMPFILES_UP, { method: "POST", body: fd });
    } catch (err) {
        throw new Error("No se pudo subir la imagen. Verifica tu internet. " + err.message);
    }

    if (!res.ok) throw new Error("Error subiendo imagen: HTTP " + res.status);

    const json = await res.json();
    if (!json.data || !json.data.url) {
        throw new Error("tmpfiles no devolvio URL. Respuesta: " + JSON.stringify(json));
    }

    // tmpfiles.org devuelve /XXXX/archivo.jpg
    // La URL directa de descarga es /dl/XXXX/archivo.jpg
    const url = json.data.url.replace("tmpfiles.org/", "tmpfiles.org/dl/");
    console.log("[Upload] URL publica:", url);
    return url;
}

// ─── GENERAR VIDEO ─────────────────────────────────────
btnGenerar.addEventListener("click", handleGenerar);

async function handleGenerar() {
    const key = getKey();
    if (!key)          { abrirModal(); return; }
    if (!imageDataUrl) { alert("Sube una foto primero."); return; }

    setUI(true);
    mostrarProgreso("Preparando...", 5);

    try {
        // Paso 1: URL publica de la imagen
        if (!imagePublicUrl) {
            imagePublicUrl = await subirImagen(imageDataUrl);
        }
        mostrarProgreso("Imagen lista. Enviando a Agnes AI...", 25);

        // Paso 2: Parametros
        const prompt  = promptInput.value.trim() ||
            "Smooth cinematic motion, sportswear model, dynamic elegant movement, professional quality";

        const frames  = parseInt(numFramesSel.value);
        const fps     = parseInt(fpsSlider.value);
        const res_p   = parseInt(resolucion.value);

        const dims = {
            480:  { w: 854,  h: 480  },
            720:  { w: 1280, h: 720  },
            1080: { w: 1920, h: 1080 }
        };
        const { w, h } = dims[res_p] || dims[720];

        console.log("[Agnes] Creando video...");
        console.log("[Agnes] Imagen:", imagePublicUrl);
        console.log("[Agnes] Config:", frames, "frames |", fps, "fps |", w + "x" + h);

        // Paso 3: Crear tarea en Agnes
        const res = await fetch(AGNES_VIDEO, {
            method: "POST",
            headers: {
                "Authorization": "Bearer " + key,
                "Content-Type":  "application/json"
            },
            body: JSON.stringify({
                model:      "agnes-video-v2.0",
                prompt:     prompt,
                image:      imagePublicUrl,
                width:      w,
                height:     h,
                num_frames: frames,
                frame_rate: fps
            })
        });

        const data = await res.json();
        console.log("[Agnes] Respuesta:", res.status, JSON.stringify(data).slice(0, 300));

        if (!res.ok) {
            throw new Error(data.error || data.detail || data.message || "HTTP " + res.status);
        }

        const vid = data.video_id || data.task_id || data.id;
        if (!vid) throw new Error("Sin ID de tarea. Data: " + JSON.stringify(data));

        console.log("[Agnes] Video ID:", vid);
        mostrarProgreso("Generando: " + vid.slice(0, 12) + "...", 35);

        // Paso 4: Esperar resultado
        const videoUrl = await polling(vid, key);
        mostrarResultado(videoUrl);

    } catch (err) {
        ocultarProgreso();
        console.error("[Agnes] Error:", err.message);

        let msg = "Error: " + err.message;
        if (err.message.includes("401") || err.message.includes("Unauthorized"))
            msg = "API Key invalida.\nObtén una gratis en:\nplatform.agnes-ai.com/settings/apiKeys";
        else if (err.message.includes("429"))
            msg = "Demasiadas peticiones. Espera 30 segundos e intenta de nuevo.";
        else if (err.message.includes("422"))
            msg = "Parametros no validos. Prueba con otra imagen JPG horizontal.";
        else if (err.message.includes("internet"))
            msg = "Sin conexion. Verifica tu internet e intenta de nuevo.";

        alert(msg);
        imagePublicUrl = null;
    } finally {
        setUI(false);
    }
}

// ─── POLLING ───────────────────────────────────────────
async function polling(videoId, key) {
    let progreso = 35;

    for (let i = 0; i < 150; i++) {
        await sleep(4000);
        progreso = Math.min(90, 35 + i * 0.38);
        mostrarProgreso(
            "Agnes AI generando... " + (i + 1) * 4 + "s",
            progreso
        );

        try {
            const res  = await fetch("https://apihub.agnes-ai.com/v1/videos/" + videoId, {
                headers: { "Authorization": "Bearer " + key }
            });
            const data = await res.json();
            const st   = (data.status || data.state || "").toLowerCase();

            console.log("[Polling] Intento", i + 1, "| Estado:", st);

            if (st === "completed" || st === "succeeded" || st === "success") {
                mostrarProgreso("Video listo!", 100);
                const url = data.video_url || data.url ||
                            (data.result && (data.result.video_url || data.result.url));
                if (!url) throw new Error("Completado pero sin URL. Data: " + JSON.stringify(data));
                return url;
            }

            if (st === "failed" || st === "error") {
                throw new Error(data.error || data.message || "Fallo en Agnes AI");
            }

        } catch (err) {
            if (err.message.includes("Fallo") || err.message.includes("sin URL")) throw err;
            console.warn("[Polling] Reintentando...", err.message);
        }
    }

    throw new Error("Tiempo agotado (10 minutos). Intenta de nuevo.");
}

// ─── DESCARGA ──────────────────────────────────────────
btnDescargar.addEventListener("click", async () => {
    if (!currentVideo) return;
    btnDescargar.textContent = "Descargando...";
    btnDescargar.disabled    = true;
    try {
        const res  = await fetch(currentVideo);
        const blob = await res.blob();
        const url  = URL.createObjectURL(blob);
        const a    = document.createElement("a");
        a.href = url;
        a.download = "video_sport_" + Date.now() + ".mp4";
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        btnDescargar.textContent = "Descargado!";
        setTimeout(() => {
            btnDescargar.textContent = "Descargar MP4";
            btnDescargar.disabled    = false;
        }, 3000);
    } catch {
        window.open(currentVideo, "_blank");
        btnDescargar.textContent = "Descargar MP4";
        btnDescargar.disabled    = false;
    }
});

// ─── NUEVO VIDEO ───────────────────────────────────────
btnNuevo.addEventListener("click", () => {
    imageDataUrl   = null;
    imagePublicUrl = null;
    currentVideo   = null;
    imgPreview.classList.add("hidden");
    imgPreview.src = "";
    uploadInner.classList.remove("hidden");
    btnCambiar.classList.add("hidden");
    secResult.classList.add("hidden");
    secProgress.classList.add("hidden");
    btnGenerar.disabled   = true;
    fileInput.value       = "";
    promptInput.value     = "";
    fpsSlider.value       = 16;
    fpsVal.textContent    = "16";
});

// ─── UI ────────────────────────────────────────────────
function setUI(v) {
    btnGenerar.disabled    = v;
    btnGenerar.textContent = v ? "Generando..." : "Generar Video con Agnes AI";
}
function mostrarProgreso(txt, pct) {
    secProgress.classList.remove("hidden");
    secResult.classList.add("hidden");
    progressTxt.textContent = txt;
    bar.style.width = pct + "%";
}
function ocultarProgreso() { secProgress.classList.add("hidden"); }
function mostrarResultado(url) {
    currentVideo    = url;
    ocultarProgreso();
    videoPlayer.src = url;
    secResult.classList.remove("hidden");
    secResult.scrollIntoView({ behavior: "smooth", block: "center" });
}
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ─── INICIO ────────────────────────────────────────────
window.addEventListener("load", () => {
    console.log("[GeneradorVideo] Agnes AI Edition");
    console.log("[GeneradorVideo] Key inyectada por Actions:", AGNES_INJECTED !== "AGNES_KEY_PLACEHOLDER");
    console.log("[GeneradorVideo] Key en localStorage:", !!localStorage.getItem("agnesKey"));
    if (!getKey()) setTimeout(abrirModal, 700);
});
'@

# ─────────────────────────────────────────────────────────
# DEPLOY.YML
# ─────────────────────────────────────────────────────────
Write-Host "[6/7] deploy.yml..." -ForegroundColor Yellow

W ".github\workflows\deploy.yml" @'
name: Deploy GeneradorVideo

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Inyectar Agnes API Key
        env:
          AGNES_KEY: ${{ secrets.AGNES_API_KEY }}
        run: |
          if [ -n "$AGNES_KEY" ]; then
            sed -i "s|AGNES_KEY_PLACEHOLDER|${AGNES_KEY}|g" app.js
            echo "OK: Key inyectada en app.js"
          else
            echo "AVISO: Secret AGNES_API_KEY no configurado"
            echo "El usuario debera ingresar la key manualmente en la web"
          fi

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
'@

# ─────────────────────────────────────────────────────────
# README
# ─────────────────────────────────────────────────────────
W "README.md" @'
# GeneradorVideo

Genera videos con Agnes AI desde una foto. 100% gratis, sin limite.

## Web
https://ojairnp.github.io/GeneradorVideo

## Setup (una sola vez)

### 1. Agregar secret AGNES_API_KEY
https://github.com/ojairnp/GeneradorVideo/settings/secrets/actions
- New repository secret
- Name:  AGNES_API_KEY
- Value: sk-xxxx (de platform.agnes-ai.com/settings/apiKeys)

### 2. Activar GitHub Pages
https://github.com/ojairnp/GeneradorVideo/settings/pages
- Source: GitHub Actions
- Save

### 3. Ver el deploy
https://github.com/ojairnp/GeneradorVideo/actions

Espera 2-3 minutos y abre la URL de arriba.

## API
Agnes AI - https://agnes-ai.com
Modelo: agnes-video-v2.0
Gratis sin limite ni marca de agua.
'@

# ─────────────────────────────────────────────────────────
# GIT + PUSH
# ─────────────────────────────────────────────────────────
Write-Host "[7/7] Git + Push..." -ForegroundColor Yellow

if (-not (Test-Path ".git")) {
    git init -b main
}

$rem = git remote 2>&1
if ($rem -contains "origin") {
    git remote set-url origin $REPO
} else {
    git remote add origin $REPO
}

git add .

$cambios = git status --porcelain 2>&1
if ($cambios) {
    git commit -m "feat: GeneradorVideo Agnes AI v4 desde cero"
} else {
    Write-Host "  INFO: Sin cambios nuevos" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  Subiendo a GitHub..." -ForegroundColor Cyan
Write-Host "  (puede pedir usuario + Personal Access Token)" -ForegroundColor Yellow
Write-Host ""

git push -u origin main --force

# ─────────────────────────────────────────────────────────
# RESULTADO
# ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  LISTO! Codigo subido a GitHub."            -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  REPO  : https://github.com/ojairnp/GeneradorVideo"  -ForegroundColor Cyan
Write-Host "  WEB   : https://ojairnp.github.io/GeneradorVideo"   -ForegroundColor Cyan
Write-Host ""
Write-Host "  PASO 1 - Secret de Agnes (obligatorio):"   -ForegroundColor Yellow
Write-Host "  https://github.com/ojairnp/GeneradorVideo/settings/secrets/actions"
Write-Host "  Name:  AGNES_API_KEY"
Write-Host "  Value: sk-xxxx"
Write-Host ""
Write-Host "  PASO 2 - Activar GitHub Pages:"            -ForegroundColor Yellow
Write-Host "  https://github.com/ojairnp/GeneradorVideo/settings/pages"
Write-Host "  Source: GitHub Actions  ->  Save"
Write-Host ""
Write-Host "  PASO 3 - Ver deploy:"                      -ForegroundColor Yellow
Write-Host "  https://github.com/ojairnp/GeneradorVideo/actions"
Write-Host ""
Read-Host "Presiona Enter para cerrar"