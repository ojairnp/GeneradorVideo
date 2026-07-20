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

// â”€â”€â”€ DOM â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ API KEY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function getKey() {
    const local     = localStorage.getItem("agnesKey");
    const inyectada = AGNES_INJECTED !== "AGNES_KEY_PLACEHOLDER"
                      ? AGNES_INJECTED : null;
    return local || inyectada || null;
}

// â”€â”€â”€ UPLOAD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ SLIDER FPS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
fpsSlider.addEventListener("input", () => {
    fpsVal.textContent = fpsSlider.value;
});

// â”€â”€â”€ MODAL KEY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ SUBIR IMAGEN A HOST PUBLICO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Agnes necesita URL publica, no base64
// tmpfiles.org - gratis, sin key, expira en 1 hora// ─── SUBIR IMAGEN A IGBB (agentes AI acepta) ──────────
async function subirImagen(dataUrl) {
    mostrarProgreso("Subiendo imagen a servidor público...", 12);

    // Convertir dataURL a Blob
    const blob = await fetch(dataUrl).then(r => r.blob());

    const formData = new FormData();
    formData.append("image", blob, "foto.jpg");
    // Clave pública de ImgBB (funciona para todos, sin registro)
    formData.append("key", "6d207e02198a847aa8d0a2c9013a2d7e");

    try {
        const res = await fetch("https://api.imgbb.com/1/upload", {
            method: "POST",
            body: formData
        });

        if (!res.ok) {
            throw new Error("Error subiendo a ImgBB: " + res.status);
        }

        const json = await res.json();
        if (!json.success) {
            throw new Error("ImgBB error: " + (json.error?.message || "desconocido"));
        }

        const url = json.data.url; // URL pública directa
        console.log("[Upload] URL pública:", url);
        return url;
    } catch (err) {
        throw new Error("No se pudo subir la imagen: " + err.message);
    }
}

// â”€â”€â”€ GENERAR VIDEO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
            msg = "API Key invalida.\nObtÃ©n una gratis en:\nplatform.agnes-ai.com/settings/apiKeys";
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

// â”€â”€â”€ POLLING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ DESCARGA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ NUEVO VIDEO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€â”€ INICIO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
window.addEventListener("load", () => {
    console.log("[GeneradorVideo] Agnes AI Edition");
    console.log("[GeneradorVideo] Key inyectada por Actions:", AGNES_INJECTED !== "AGNES_KEY_PLACEHOLDER");
    console.log("[GeneradorVideo] Key en localStorage:", !!localStorage.getItem("agnesKey"));
    if (!getKey()) setTimeout(abrirModal, 700);
});
