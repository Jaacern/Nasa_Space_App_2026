/* ARES FORGE: tráiler de 29,9 s (1920x1080, 60 fps) para NASA Space Apps 2026. Versión 4.
   Lenguaje de edición de tráileres de roguelites de acción (Risk of Rain 2, Hades): cortes secos al golpe de la
   música (onsets medidos en mix.wav), planos de duración variable, montaje rápido y tarjeta en negro para el gancho.
   Los rótulos usan el lenguaje visual del HUD del juego (paneles navy con borde cian, esquinas, etiquetas en mono),
   no tipografía genérica centrada.
   Fuentes de la identidad del juego (Ui.luau): Michroma (logo), Sarpanch (titulares), Jura (texto), Roboto Mono (datos).

   Criterios de encuadre que manda esta versión:
   - Los clips de gameplay (1536x864) comparten exactamente la relación de aspecto del lienzo (1920x1080), así que a
     escala 1 encajan sin recortar un solo píxel. Los 9 planos que muestran HUD del juego (`loop`, `cards`, `boss`,
     `m1`..`m4`, `parts`, `data`) van con `safe` = escala 1 y sin shake: los paneles de vida, SHIP·PARTS y NASA
     ARCHIVE quedan enteros. El zoom de empuje queda solo para los planos de IA que no tienen interfaz.
   - `phone.mp4` es 1736x864 (2,009:1), más ancho que el lienzo: no puede ir con `safe` sin dejar bandas, así que va
     dentro de una pantalla vertical de 452x918 con recorte central deliberado y escala hacia arriba.
   - Los rótulos se colocan en la franja inferior-izquierda, la única zona de los planos de gameplay sin UI del juego.
   - La rejilla de cortes `CUT` es la fuente única de verdad temporal: cada corte cae en un golpe de mix.wav. Las
     transiciones son capas propias (barrido + destello) que se dibujan sobre la rejilla exacta, sin solapar planos,
     para que la duración neta siga siendo 1794 cuadros. */
import React from "react";
import {
  AbsoluteFill, Audio, Easing, OffthreadVideo, Sequence, continueRender, delayRender,
  interpolate, random, staticFile, useCurrentFrame,
} from "remotion";

export const FPS = 60;
const C = { bg: "#070B14", panel: "11,19,43", cyan: "#00D2FF", orange: "#FF6B35", gold: "#FFC828", text: "#F8FAFC", dim: "#9FB0CC" };
const F = { logo: "AresMichroma", head: "AresSarpanch", body: "AresJura", mono: "AresMono", punch: "AresBangers", hand: "AresMarker" };
const ease = Easing.bezier(0.16, 1, 0.3, 1);
const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

// ---------- Fuentes ----------
const fontHandle = typeof window !== "undefined" ? delayRender("fuentes ARES") : 0;
if (typeof window !== "undefined") {
  const list: [string, string][] = [
    [F.logo, "Michroma-Regular.ttf"], [F.head, "Sarpanch-Bold.ttf"], [F.body, "Jura-Regular.ttf"], [F.mono, "RobotoMono-Regular.ttf"], [F.punch, "Bangers-Regular.ttf"], [F.hand, "PermanentMarker-Regular.ttf"],
  ];
  Promise.all(list.map(([fam, file]) => new FontFace(fam, `url(${staticFile(`ares/fonts/${file}`)})`).load()
    .then((f) => { document.fonts.add(f); })))
    .then(() => continueRender(fontHandle)).catch((e) => { console.error(e); continueRender(fontHandle); });
}

// ---------- Acabado ----------
const Vignette: React.FC<{ k?: number }> = ({ k = 0.5 }) => (
  <AbsoluteFill style={{ background: `radial-gradient(ellipse 82% 76% at 50% 48%, rgba(0,0,0,0) 62%, rgba(4,6,12,${k}) 100%)` }} />
);
const Grain: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ opacity: 0.05, mixBlendMode: "overlay" }}>
      <svg width="100%" height="100%">
        <filter id="g"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed={f % 12} /></filter>
        <rect width="100%" height="100%" filter="url(#g)" />
      </svg>
    </AbsoluteFill>
  );
};
// Destello de entrada. `soft` = halo radial (no quema el cuadro); `hard` solo en el impacto mayor.
const Flash: React.FC<{ n?: number; color?: string; k?: number; soft?: boolean }> = ({ n = 5, color = "#FFFFFF", k = 0.32, soft = true }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, n], [k, 0], { ...clamp, easing: Easing.out(Easing.quad) });
  return (
    <AbsoluteFill style={{
      opacity: o,
      background: soft ? `radial-gradient(ellipse 62% 58% at 50% 46%, ${color} 0%, rgba(255,255,255,0) 76%)` : color,
    }} />
  );
};
// Micro-barrido de corte: una franja de luz cruza el cuadro justo en el golpe. Sustituye a las transiciones
// con shader (blurSlide/filmBurn), que son experimentales, por una capa CSS determinista.
const Streak: React.FC<{ dir?: 1 | -1; color?: string; n?: number; k?: number }> = ({ dir = 1, color = "rgba(0,210,255,0.9)", n = 8, k = 0.5 }) => {
  const f = useCurrentFrame();
  const p = interpolate(f, [0, n - 1], [0, 1], { ...clamp, easing: Easing.inOut(Easing.quad) });
  const x = dir === 1 ? -640 + p * 2700 : 2560 - p * 2700;
  const o = interpolate(f, [0, 1, n - 2, n - 1], [0, k, k * 0.8, 0], clamp);
  return (
    <AbsoluteFill style={{ overflow: "hidden" }}>
      <div style={{
        position: "absolute", top: -120, left: x, width: 520, height: 1320, transform: "skewX(-16deg)", opacity: o,
        background: `linear-gradient(90deg, rgba(0,0,0,0) 0%, ${color} 42%, rgba(255,255,255,0.95) 50%, ${color} 58%, rgba(0,0,0,0) 100%)`,
        filter: "blur(2px)", mixBlendMode: "screen",
      }} />
    </AbsoluteFill>
  );
};
// Refuerzo de contraste bajo los rótulos superiores (sin recortar nada de la imagen).
const TopScrim: React.FC<{ h?: number; o?: number }> = ({ h = 300, o = 0.62 }) => (
  <AbsoluteFill style={{ height: h, background: `linear-gradient(180deg, rgba(4,7,14,${o}) 0%, rgba(4,7,14,0) 100%)` }} />
);

const Footage: React.FC<{
  src: string; dur: number; push?: number; punch?: number; shake?: number; grade?: string; trimBefore?: number;
  playbackRate?: number; safe?: boolean;
}> = ({ src, dur, push = 1.04, punch = 1.06, shake = 0, grade = "contrast(1.07) saturate(1.12)", trimBefore = 0, playbackRate = 1, safe = false }) => {
  const f = useCurrentFrame();
  // `safe`: escala exacta, sin empuje ni golpe de zoom. Los clips de gameplay son 16:9 igual que el lienzo, así que
  // a escala 1 no se pierde ni el borde izquierdo de SUIT POWER ni el derecho de SHIP·PARTS.
  const z = safe ? 1 : interpolate(f, [0, dur], [1, push], clamp) * interpolate(f, [0, 12], [punch, 1], { ...clamp, easing: ease });
  const amp = shake * interpolate(f, [0, 18], [1, 0], clamp);
  const dx = (random(`x${f}`) - 0.5) * amp, dy = (random(`y${f}`) - 0.5) * amp;
  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <AbsoluteFill style={{ transform: `translate(${dx}px,${dy}px) scale(${z})`, filter: grade }}>
        <OffthreadVideo
          src={staticFile(`ares/${src}`)} trimBefore={trimBefore || undefined} playbackRate={playbackRate}
          muted style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ---------- Rótulos con el lenguaje del HUD del juego ----------
const typed = (s: string, f: number, speed: number) => s.slice(0, Math.max(0, Math.floor(f * speed)));
const Corners: React.FC<{ c?: string }> = ({ c = C.cyan }) => {
  const s = { position: "absolute" as const, width: 14, height: 14, borderColor: c, borderStyle: "solid" };
  return (<>
    <div style={{ ...s, left: -1, top: -1, borderWidth: "2px 0 0 2px" }} /><div style={{ ...s, right: -1, top: -1, borderWidth: "2px 2px 0 0" }} />
    <div style={{ ...s, left: -1, bottom: -1, borderWidth: "0 0 2px 2px" }} /><div style={{ ...s, right: -1, bottom: -1, borderWidth: "0 2px 2px 0" }} />
  </>);
};
// Panel del HUD: se despliega en 60 fps reales (sin animación "en dos"), etiqueta tecleada en 12 cuadros y cerrada
// con cursor parpadeante solo mientras escribe, de modo que nunca queda una etiqueta cortada por el corte.
const HudPanel: React.FC<{
  label: string; lines: string[]; dur: number; x?: number; y?: number; size?: number; accent?: string;
  align?: "top" | "bottom"; delay?: number;
}> = ({ label, lines, dur, x = 90, y = 80, size = 50, accent = C.cyan, align = "top", delay = 0 }) => {
  const f = useCurrentFrame() - delay;
  if (f < 0) return null;
  const open = interpolate(f, [0, 10], [0, 100], { ...clamp, easing: ease });
  const exitStart = dur - delay - 7;
  const exit = interpolate(f, [exitStart, exitStart + 7], [1, 0], { ...clamp, easing: Easing.in(Easing.quad) });
  const lab = typed(label, f - 2, label.length / 12);
  const typing = lab.length < label.length;
  const cursorOn = typing && Math.floor(f / 4) % 2 === 0;
  return (
    <div style={{
      position: "absolute", left: x, [align]: y, opacity: exit,
      clipPath: `inset(-24px ${100 - open}% -24px -24px)`,
    }}>
      <div style={{
        position: "relative", background: "rgba(7,11,20,0.88)", backdropFilter: "blur(8px)",
        border: "1px solid rgba(0,210,255,0.30)", borderLeft: `3px solid ${accent}`,
        boxShadow: "0 20px 60px rgba(0,0,0,0.55)", padding: "14px 30px 20px 22px",
      }}>
        <Corners c={accent} />
        <div style={{ fontFamily: F.mono, fontSize: 18, letterSpacing: 4, color: accent, height: 24, lineHeight: "24px", opacity: 0.95 }}>
          {"// " + lab}{typing ? <span style={{ color: C.text, opacity: cursorOn ? 1 : 0 }}>▌</span> : null}
        </div>
        {lines.map((ln, i) => {
          const t = interpolate(f, [7 + i * 4, 17 + i * 4], [0, 1], { ...clamp, easing: ease });
          return (
            <div key={i} style={{ overflow: "hidden", marginTop: i === 0 ? 2 : 4 }}>
              <div style={{
                fontFamily: F.head, fontWeight: 700, fontSize: size, lineHeight: 1.1, letterSpacing: 1,
                color: C.text, transform: `translateX(${(1 - t) * -28}px)`, opacity: t, whiteSpace: "nowrap",
                textShadow: "0 2px 18px rgba(0,0,0,0.55)",
              }}>{ln}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
// Etiqueta de esquina (equipo, fuente de datos). Sobre scrim para que el subtítulo cyan no se pierda en el fondo.
const Tag: React.FC<{ text: string; sub?: string; dur: number; x?: number; y?: number; delay?: number }> = ({ text, sub, dur, x = 80, y = 58, delay = 0 }) => {
  const f = useCurrentFrame() - delay;
  if (f < 0) return null;
  const out = interpolate(f, [dur - delay - 8, dur - delay], [1, 0], clamp);
  return (
    <>
      <TopScrim h={y + 240} />
      <div style={{ position: "absolute", left: x, top: y, opacity: out }}>
        <div style={{
          fontFamily: F.head, fontWeight: 700, fontSize: 32, letterSpacing: 7, color: C.text,
          textShadow: "0 2px 14px rgba(0,0,0,0.85)", display: "inline-block",
          borderLeft: `3px solid ${C.cyan}`, paddingLeft: 16,
        }}>{typed(text, f, text.length / 12)}</div>
        {sub ? (
          <div style={{
            fontFamily: F.mono, fontSize: 19, letterSpacing: 4, color: "#7FE3FF", marginTop: 6, paddingLeft: 16,
            textShadow: "0 2px 12px rgba(0,0,0,0.9), 0 0 18px rgba(0,0,0,0.6)",
          }}>{typed(sub, f - 8, sub.length / 14)}</div>
        ) : null}
      </div>
    </>
  );
};
// Nota a mano: texto de rotulador + trazo que se dibuja (flecha o círculo). Tiembla como dibujo animado a mano.
const Note: React.FC<{ text: string; x: number; y: number; path: string; head?: string; rot?: number; size?: number; delay?: number; dur: number; color?: string }> = ({
  text, x, y, path, head, rot = -4, size = 40, delay = 0, dur, color = "#FFE14D",
}) => {
  const f = useCurrentFrame() - delay;
  if (f < 0) return null;
  const k = Math.floor(f / 4);
  const jx = (random(`nx${k}`) - 0.5) * 1.6, jy = (random(`ny${k}`) - 0.5) * 1.6, jr = (random(`nr${k}`) - 0.5) * 0.7;
  const draw = interpolate(f, [0, 14], [1, 0], { ...clamp, easing: Easing.out(Easing.quad) });
  const txt = interpolate(f, [10, 16], [0, 1], clamp);
  const out = interpolate(f, [dur - delay - 6, dur - delay], [1, 0], clamp);
  return (
    <AbsoluteFill style={{ opacity: out, transform: `translate(${jx}px,${jy}px)` }}>
      <svg width="1920" height="1080" style={{ position: "absolute" }}>
        <path d={path} fill="none" stroke={color} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray="1" strokeDashoffset={draw} style={{ filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.6))" }} />
        {head ? <path d={head} fill="none" stroke={color} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" opacity={draw < 0.05 ? 1 : 0} /> : null}
      </svg>
      <div style={{ position: "absolute", left: x, top: y, transform: `rotate(${rot + jr}deg)`, fontFamily: F.hand, fontSize: size, color, opacity: txt, textShadow: "0 3px 10px rgba(0,0,0,0.8)", whiteSpace: "nowrap" }}>{text}</div>
    </AbsoluteFill>
  );
};

// ---------- Planos especiales ----------
// Tarjeta negra del gancho: cuatro palabras que golpean y un pie de misión que se lee completo antes del corte.
const BlackCard: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const words = ["YOUR", "SHIP", "WENT", "DOWN."];
  const sub = interpolate(f, [10, 20], [0, 1], { ...clamp, easing: ease });
  const rule = interpolate(f, [10, 26], [0, 1], { ...clamp, easing: ease });
  return (
    <AbsoluteFill style={{ background: "#020308", justifyContent: "center", alignItems: "center" }}>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 60% 40% at 50% 50%, rgba(255,107,53,0.07), rgba(0,0,0,0) 72%)" }} />
      <div style={{ display: "flex", gap: 24, marginTop: -30 }}>
        {words.map((w, i) => {
          const s = i * 3;
          const t = interpolate(f, [s, s + 5], [0, 1], { ...clamp, easing: ease });
          return (
            <span key={i} style={{
              fontFamily: F.punch, fontSize: 148, letterSpacing: 3, color: i === 3 ? C.orange : C.text,
              display: "inline-block", opacity: t,
              transform: `rotate(${[-3, 2, -1, 4][i]}deg) translateY(${[0, -8, 6, -4][i] + (1 - t) * 16}px) scale(${1 + (1 - t) * 0.14})`,
              textShadow: "0 6px 40px rgba(0,0,0,0.8)",
            }}>{w}</span>
          );
        })}
      </div>
      <div style={{ width: 620 * rule, height: 1, marginTop: 26, background: `linear-gradient(90deg, transparent, rgba(159,176,204,0.75), transparent)` }} />
      <div style={{ marginTop: 30, fontFamily: F.mono, fontSize: 22, letterSpacing: 8, color: "#CBD8EE", opacity: sub, transform: `translateY(${(1 - sub) * 8}px)` }}>
        SOL 01 · JEZERO CRATER · MARS
      </div>
      <AbsoluteFill style={{ background: "#000", opacity: interpolate(f, [dur - 4, dur], [0, 1], clamp) }} />
    </AbsoluteFill>
  );
};

// Título: entra cuando `title.mp4` ya está en la órbita limpia (trimBefore 62) y con un scrim radial que separa
// el logotipo del cielo de Marte sin manchar la imagen.
const Title: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const letters = "ARES FORGE".split("");
  const line = interpolate(f, [8, 34], [0, 1], { ...clamp, easing: ease });
  const tag = interpolate(f, [26, 42], [0, 1], { ...clamp, easing: ease });
  const ca = interpolate(f, [0, 10], [8, 0], clamp);
  return (
    <AbsoluteFill>
      <Footage src="title.mp4" dur={dur} trimBefore={62} push={1.03} punch={1.03} grade="contrast(1.08) saturate(1.08) brightness(0.82)" />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 68% 42% at 50% 46%, rgba(3,5,10,0.90) 0%, rgba(3,5,10,0.72) 44%, rgba(3,5,10,0) 76%)" }} />
      <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(3,5,10,0) 26%, rgba(3,5,10,0.55) 42%, rgba(3,5,10,0.55) 60%, rgba(3,5,10,0) 76%)" }} />
      <Vignette k={0.7} />
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <div style={{ position: "relative", transform: `scale(${interpolate(f, [0, 26], [1.1, 1], { ...clamp, easing: ease })})` }}>
          {[["rgba(255,60,60,0.65)", -ca], ["rgba(0,210,255,0.65)", ca], [C.text, 0]].map(([col, dx], k) => (
            <div key={k} style={{ position: k < 2 ? "absolute" : "relative", left: 0, top: 0, display: "flex", transform: `translateX(${dx}px)`, mixBlendMode: k < 2 ? "screen" : "normal", opacity: k < 2 ? (ca > 0 ? 1 : 0) : 1 }}>
              {letters.map((ch, i) => {
                const t = interpolate(f, [i * 1.2, 8 + i * 1.2], [0, 1], { ...clamp, easing: ease });
                return <span key={i} style={{ fontFamily: F.logo, fontSize: 132, color: col as string, letterSpacing: 18, opacity: t, whiteSpace: "pre", textShadow: k === 2 ? "0 0 6px rgba(0,0,0,0.95), 0 0 44px rgba(0,210,255,0.40), 0 8px 34px rgba(0,0,0,0.85)" : "none" }}>{ch}</span>;
              })}
            </div>
          ))}
        </div>
        <div style={{ width: 720 * line, height: 3, marginTop: 14, background: `linear-gradient(90deg, transparent, ${C.orange}, transparent)` }} />
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 26, letterSpacing: 7, color: C.gold, marginTop: 20, opacity: tag, textShadow: "0 3px 20px rgba(0,0,0,0.9)" }}>
          SURVIVE MARS · RECOVER REAL SPACECRAFT SYSTEMS · GO HOME
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{ background: "#000", opacity: interpolate(f, [dur - 4, dur], [0, 0.55], clamp) }} />
    </AbsoluteFill>
  );
};

// Plano del teléfono: móvil en horizontal con la proporción exacta de `phone.mp4` (1736×864) para que el HUD del
// juego entre completo, bisel real y pantalla a sangre sin recorte lateral.
const Phone: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const SW = 1160, SH = Math.round(SW * 864 / 1736), B = 18;
  const ry = interpolate(f, [0, dur], [-8, -3], { ...clamp, easing: Easing.out(Easing.quad) });
  const s = interpolate(f, [0, 22], [0.94, 1], { ...clamp, easing: ease });
  return (
    <AbsoluteFill style={{ background: C.bg }}>
      <AbsoluteFill style={{ filter: "blur(40px) brightness(0.4) saturate(1.15)", transform: "scale(1.18)" }}>
        <OffthreadVideo src={staticFile("ares/loop.mp4")} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </AbsoluteFill>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 55% 60% at 76% 46%, rgba(0,210,255,0.10), rgba(0,0,0,0) 70%)" }} />
      <AbsoluteFill style={{ alignItems: "flex-end", justifyContent: "flex-start", paddingTop: 88, paddingRight: 72, perspective: 2800 }}>
        <div style={{
          position: "relative", width: SW + B * 2, height: SH + B * 2, borderRadius: 46,
          background: "linear-gradient(155deg,#3A4150 0%,#0C0F15 34%,#0C0F15 66%,#2C3340 100%)",
          padding: B, boxShadow: "0 46px 110px rgba(0,0,0,0.72), inset 0 0 0 2px rgba(255,255,255,0.14)",
          transform: `rotateY(${ry}deg) rotateX(2deg) scale(${s})`,
        }}>
          {/* botones laterales: volumen en el canto superior, bloqueo en el canto derecho */}
          <div style={{ position: "absolute", top: -3, left: 196, width: 104, height: 4, borderRadius: 3, background: "linear-gradient(180deg,#2A3140,#0A0D13)" }} />
          <div style={{ position: "absolute", top: -3, left: 318, width: 104, height: 4, borderRadius: 3, background: "linear-gradient(180deg,#2A3140,#0A0D13)" }} />
          <div style={{ position: "absolute", right: -3, top: 224, width: 4, height: 92, borderRadius: 3, background: "linear-gradient(180deg,#2A3140,#0A0D13)" }} />
          <div style={{ width: SW, height: SH, borderRadius: 30, overflow: "hidden", position: "relative", background: "#000" }}>
            <OffthreadVideo
              src={staticFile("ares/phone.mp4")} trimBefore={24} muted
              style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "50% 50%", filter: "contrast(1.06) saturate(1.1)" }}
            />
            {/* isla dinámica en el canto izquierdo del bisel, fuera de la zona de juego */}
            <div style={{ position: "absolute", left: 8, top: "50%", marginTop: -46, width: 22, height: 92, borderRadius: 11, background: "#04060B", boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.08)" }}>
              <div style={{ position: "absolute", left: 6, bottom: 12, width: 10, height: 10, borderRadius: 5, background: "#0B1424", boxShadow: "inset 0 0 2px rgba(80,150,255,0.8)" }} />
            </div>
            <div style={{ position: "absolute", inset: 0, background: `linear-gradient(118deg, rgba(255,255,255,0) ${interpolate(f, [0, dur], [22, 58])}%, rgba(255,255,255,0.08) ${interpolate(f, [0, dur], [30, 66])}%, rgba(255,255,255,0) ${interpolate(f, [0, dur], [42, 78])}%)` }} />
          </div>
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 60% 46% at 22% 46%, rgba(0,210,255,0.10), rgba(0,0,0,0) 70%)" }} />
      <HudPanel label="COMING TO ROBLOX" lines={["PC · MOBILE", "TABLET · CONSOLE"]} dur={dur} x={84} y={72} size={48} accent={C.gold} align="bottom" delay={8} />
      <Note dur={dur} delay={30} text="same game, in your pocket" x={72} y={210} rot={-5} size={36}
        path="M 528 296 C 590 318, 600 340, 628 356" head="M 598 336 L 630 358 L 596 378" />
      <Flash n={6} k={0.3} color="rgba(180,225,255,0.9)" />
    </AbsoluteFill>
  );
};

// ---------- Tarjeta final: espacio profundo con el limbo de Marte ----------
const Stars: React.FC = () => {
  const f = useCurrentFrame();
  const stars = React.useMemo(() => new Array(420).fill(0).map((_, i) => ({
    x: random(`sx${i}`) * 1920, y: random(`sy${i}`) * 1080, r: random(`sr${i}`) ** 3 * 2.2 + 0.4, p: random(`sp${i}`) * 6.28, d: random(`sd${i}`),
  })), []);
  return (
    <svg width="1920" height="1080" style={{ position: "absolute" }}>
      {stars.map((s, i) => (
        <circle key={i} cx={(s.x - f * (0.08 + s.d * 0.25) + 1920) % 1920} cy={s.y} r={s.r} fill="#fff"
          opacity={0.35 + 0.55 * s.d * (0.75 + 0.25 * Math.sin(f / 9 + s.p))} />
      ))}
    </svg>
  );
};
const SpaceBg: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const rise = interpolate(f, [0, dur], [40, 0], { easing: Easing.out(Easing.quad) });
  return (
    <AbsoluteFill style={{ background: "#03040A" }}>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 50% 40% at 22% 30%, rgba(90,60,200,0.22), rgba(0,0,0,0) 70%), radial-gradient(ellipse 45% 35% at 80% 22%, rgba(0,140,220,0.16), rgba(0,0,0,0) 70%)" }} />
      <Stars />
      {/* Marte: limbo iluminado con atmósfera tenue */}
      <div style={{
        position: "absolute", left: 960 - 1500, top: 830 + rise, width: 3000, height: 3000, borderRadius: "50%",
        background: "radial-gradient(circle at 50% 0%, #E0703A 0%, #C4562A 2.2%, #7A2C14 6%, #2E100A 14%, #07030A 26%)",
        boxShadow: "0 -4px 30px rgba(255,150,90,0.60), 0 -18px 90px rgba(255,110,50,0.32), 0 -60px 220px rgba(255,90,40,0.14)",
      }} />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 62% 26% at 50% 100%, rgba(255,107,53,0.20), rgba(0,0,0,0) 72%)" }} />
    </AbsoluteFill>
  );
};
const Icon: React.FC<{ k: string }> = ({ k }) => {
  const st = { fill: "none", stroke: C.text, strokeWidth: 2.4, strokeLinecap: "round" as const, strokeLinejoin: "round" as const };
  return (
    <svg width="52" height="52" viewBox="0 0 48 48">
      {k === "pc" && (<><rect x="6" y="9" width="36" height="23" rx="2" {...st} /><path d="M18 40h12M24 32v8" {...st} /></>)}
      {k === "mobile" && (<><rect x="15" y="5" width="18" height="38" rx="4" {...st} /><path d="M22 38h4" {...st} /></>)}
      {k === "tablet" && (<><rect x="9" y="6" width="30" height="36" rx="4" {...st} /><path d="M22 37h4" {...st} /></>)}
      {k === "console" && (<><path d="M14 16h20a8 8 0 0 1 8 8l1 9a5 5 0 0 1-9 3l-3-4H17l-3 4a5 5 0 0 1-9-3l1-9a8 8 0 0 1 8-8z" {...st} /><path d="M15 22v6M12 25h6" {...st} /><circle cx="33" cy="23" r="1.4" fill={C.text} /><circle cx="36" cy="27" r="1.4" fill={C.text} /></>)}
    </svg>
  );
};
const End: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const a = (s: number, e = s + 16) => interpolate(f, [s, e], [0, 1], { ...clamp, easing: ease });
  return (
    <AbsoluteFill>
      <SpaceBg dur={dur} />
      <AbsoluteFill style={{ alignItems: "center", paddingTop: 128 }}>
        <div style={{ fontFamily: F.logo, fontSize: 112, letterSpacing: interpolate(f, [0, 40], [34, 20], { ...clamp, easing: ease }), color: C.text, opacity: a(0, 18), textShadow: "0 0 36px rgba(0,210,255,0.35), 0 10px 40px rgba(0,0,0,0.6)" }}>ARES FORGE</div>
        <div style={{ width: 600 * a(8, 36), height: 3, marginTop: 12, background: `linear-gradient(90deg, transparent, ${C.orange}, transparent)` }} />
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 25, letterSpacing: 6, color: C.gold, marginTop: 16, opacity: a(14) }}>LEARN SPACE ENGINEERING BY PLAYING</div>
        <div style={{ fontFamily: F.head, fontWeight: 700, fontSize: 42, letterSpacing: 10, color: C.text, marginTop: 46, opacity: a(26) }}>COMING TO ROBLOX</div>
        <div style={{ display: "flex", gap: 56, marginTop: 20 }}>
          {[["pc", "PC"], ["mobile", "MOBILE"], ["tablet", "TABLET"], ["console", "CONSOLE"]].map(([k, n], i) => (
            <div key={k} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8, opacity: a(32 + i * 4) }}>
              <Icon k={k} />
              <div style={{ fontFamily: F.mono, fontSize: 16, letterSpacing: 4, color: C.dim }}>{n}</div>
            </div>
          ))}
        </div>
        <div style={{ fontFamily: F.head, fontWeight: 700, fontSize: 30, letterSpacing: 6, color: C.cyan, marginTop: 40, opacity: a(50) }}>TEAM CODE OR DIE · CONCEPCIÓN, CHILE</div>
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 22, letterSpacing: 3, color: C.text, marginTop: 8, opacity: a(54) }}>GONZALO MALDONADO · JAVIER CERNA · CRISTÓBAL PALMA</div>
        <div style={{ fontFamily: F.mono, fontSize: 17, letterSpacing: 4, color: C.dim, marginTop: 8, opacity: a(60) }}>NASA SPACE APPS CHALLENGE 2026 · SPACE MISSION DESIGN GAME</div>
      </AbsoluteFill>
      <div style={{
        position: "absolute", width: "100%", bottom: 32, textAlign: "center", fontFamily: F.body, fontSize: 18,
        maxWidth: 1560, left: 0, right: 0, margin: "0 auto",
        lineHeight: 1.6, color: "rgba(222,232,246,0.94)", opacity: a(62), textShadow: "0 2px 12px rgba(0,0,0,0.85)",
      }}>
        Gameplay captured in Roblox Studio · Built with Roblox Studio and Blender · Additional tools: Google Flow (AI-generated opening and closing shots, AI music)<br />
        Uses public NASA data (CCMC DONKI, NTRS, InSight, Chandra). Not sponsored or endorsed by NASA.
      </div>
      <AbsoluteFill style={{ background: "#000", opacity: interpolate(f, [0, 14], [1, 0], clamp) }} />
    </AbsoluteFill>
  );
};

// ---------- Montaje (cortes en cuadros a 60 fps, alineados a los golpes de mix.wav) ----------
// golpes medidos: 5.49 · 9.83 · 12.42 · 13.73 · 15.97 · 19.01 · 20.92 · 25.49 s
const CUT = [0, 144, 198, 329, 462, 590, 745, 824, 858, 894, 958, 1092, 1141, 1255, 1392, 1530, 1794];
export const TOTAL = CUT[CUT.length - 1]; // 1794 = 29,9 s
const seg = (i: number) => ({ from: CUT[i], durationInFrames: CUT[i + 1] - CUT[i] });
const len = (i: number) => CUT[i + 1] - CUT[i];
const span = (a: number, b: number) => ({ from: CUT[a], durationInFrames: CUT[b] - CUT[a] });

// Los planos cortos se ralentizan lo justo para cubrir su hueco completo: sin `playbackRate` el último tramo de
// `m1`, `m2` y `m3` quedaba congelado o en negro (el clip se acababa antes que el corte).
const RATE = { m1: 0.66, m2: 0.81, m3: 0.61, cards: 0.54 };
// Barridos de corte: solo en los cuatro golpes de energía, alternando sentido; el resto son cortes secos.
const STREAKS: { at: number; dir: 1 | -1; color: string }[] = [
  { at: CUT[6], dir: 1, color: "rgba(0,210,255,0.9)" },
  { at: CUT[9], dir: -1, color: "rgba(255,107,53,0.85)" },
  { at: CUT[11], dir: 1, color: "rgba(0,210,255,0.9)" },
  { at: CUT[14], dir: -1, color: "rgba(255,200,40,0.8)" },
];
// SFX propios del proyecto: acompañan el corte sin tapar la mezcla.
const SFX: { at: number; src: string; vol: number }[] = [
  { at: CUT[3], src: "ares/whoosh.mp3", vol: 0.30 },
  { at: CUT[6], src: "ares/swoosh.mp3", vol: 0.22 },
  { at: CUT[9], src: "ares/whoosh.mp3", vol: 0.22 },
  { at: CUT[11], src: "ares/swoosh.mp3", vol: 0.20 },
  { at: CUT[13], src: "ares/swoosh.mp3", vol: 0.22 },
  { at: CUT[14], src: "ares/whoosh.mp3", vol: 0.26 },
];

export const AresTrailer: React.FC = () => (
  <AbsoluteFill style={{ background: "#000" }}>
    {/* 0 · caída (IA) */}
    <Sequence {...seg(0)}><Footage src="crash.mp4" dur={len(0)} push={1.05} punch={1} grade="contrast(1.05) saturate(1.06)" /><Vignette k={0.6} /></Sequence>
    {/* 1 · tarjeta negra */}
    <Sequence {...seg(1)}><BlackCard dur={len(1)} /></Sequence>
    {/* 2 · impacto (IA) */}
    <Sequence {...seg(2)}><Footage src="crash.mp4" trimBefore={168} dur={len(2)} push={1.08} punch={1.1} shake={16} grade="contrast(1.06) saturate(1.08)" /><Vignette k={0.6} /><Flash n={5} color="rgba(255,226,200,0.9)" k={0.45} /></Sequence>
    {/* 3 · título (golpe 5.49 s) */}
    <Sequence {...seg(3)}><Title dur={len(3)} /><Flash n={10} k={0.88} soft={false} /></Sequence>
    {/* 4 · bucle (HUD del juego, escala 1) */}
    <Sequence {...seg(4)}><Footage src="loop.mp4" dur={len(4)} safe grade="contrast(1.06) saturate(1.12)" /><Vignette k={0.3} /></Sequence>
    {/* 5 · cartas: solo la pantalla de 3 cartas, de la 28 a la 117 del clip */}
    <Sequence {...seg(5)}><Footage src="cards.mp4" trimBefore={28} playbackRate={RATE.cards} dur={len(5)} safe grade="contrast(1.05) saturate(1.1)" /><Vignette k={0.3} /><Flash n={4} k={0.22} /></Sequence>
    {/* 6-9 · jefe + montaje rápido */}
    <Sequence {...seg(6)}><Footage src="boss.mp4" dur={len(6)} safe shake={10} grade="contrast(1.07) saturate(1.12)" /><Vignette k={0.3} /><Flash n={4} k={0.26} /></Sequence>
    <Sequence {...seg(7)}><Footage src="m1.mp4" playbackRate={RATE.m1} dur={len(7)} safe grade="contrast(1.07) saturate(1.12)" /><Flash n={3} k={0.24} /></Sequence>
    <Sequence {...seg(8)}><Footage src="m2.mp4" playbackRate={RATE.m2} dur={len(8)} safe grade="contrast(1.07) saturate(1.12)" /><Flash n={3} k={0.24} /></Sequence>
    <Sequence {...seg(9)}><Footage src="m3.mp4" playbackRate={RATE.m3} dur={len(9)} safe grade="contrast(1.07) saturate(1.12)" /><Vignette k={0.3} /><Flash n={3} k={0.26} /></Sequence>
    {/* 10 · pieza MMRTG (el clip es un diálogo del juego: escala 1 para no cortar el marco) */}
    <Sequence {...seg(10)}><Footage src="parts.mp4" dur={len(10)} safe grade="contrast(1.05) saturate(1.06)" /><Vignette k={0.28} /></Sequence>
    {/* 11-12 · horda + bólido */}
    <Sequence {...seg(11)}><Footage src="m4.mp4" dur={len(11)} safe grade="contrast(1.07) saturate(1.1)" /><Flash n={3} k={0.2} /></Sequence>
    <Sequence {...seg(12)}><Footage src="data.mp4" dur={len(12)} safe grade="contrast(1.05) saturate(1.08)" /><Vignette k={0.28} /><Flash n={4} color="rgba(255,210,176,0.9)" k={0.28} /></Sequence>
    {/* 13 · celular */}
    <Sequence {...seg(13)}><Phone dur={len(13)} /></Sequence>
    {/* 14 · despegue (IA) */}
    <Sequence {...seg(14)}><Footage src="liftoff.mp4" dur={len(14) + 14} push={1.07} punch={1.06} grade="contrast(1.06) saturate(1.08)" /><Vignette k={0.6} /></Sequence>
    {/* 15 · tarjeta final */}
    <Sequence {...seg(15)}><End dur={len(15)} /></Sequence>

    {/* Rótulos: todos en la franja inferior-izquierda de los planos de gameplay (única zona sin UI del juego). */}
    <Sequence {...seg(0)}><Tag text="TEAM CODE OR DIE" sub="CONCEPCIÓN, CHILE" dur={len(0)} /></Sequence>
    <Sequence {...seg(2)}><HudPanel label="NASA SPACE APPS CHALLENGE 2026" lines={["SPACE MISSION", "DESIGN GAME"]} dur={len(2)} x={90} y={84} size={50} accent={C.orange} delay={8} /></Sequence>
    <Sequence {...seg(4)}><HudPanel label="IMPLICIT LEARNING" lines={["PLAY FIRST.", "THE SCIENCE SNEAKS IN."]} dur={len(4)} x={70} y={252} size={48} align="bottom" delay={4} /></Sequence>
    <Sequence {...seg(5)}><Note dur={len(5)} delay={16} text="every card = a real NASA fact" x={700} y={932} rot={-2.5} size={42}
      path="M 742 716 C 742 648, 850 638, 962 638 C 1074 638, 1182 648, 1182 716 C 1182 786, 1072 792, 962 792 C 852 792, 742 786, 742 716" /></Sequence>
    <Sequence {...span(6, 10)}><HudPanel label="MISSION DESIGN" lines={["4 BOSSES.", "EACH ONE STOLE A PIECE OF YOUR SHIP."]} dur={CUT[10] - CUT[6]} x={70} y={252} size={44} accent={C.orange} align="bottom" delay={6} /></Sequence>
    <Sequence {...seg(10)}><Tag text="NASA TECHNICAL REPORTS SERVER" sub="MMRTG · HIGH-GAIN ANTENNA · MOXIE · ORION ENGINE" dur={len(10)} x={90} y={54} delay={6} /></Sequence>
    <Sequence {...span(11, 13)}><HudPanel label="NASA DONKI · INSIGHT · CHANDRA" lines={["REAL SPACE WEATHER.", "VERY REAL PROBLEMS."]} dur={CUT[13] - CUT[11]} x={70} y={252} size={48} accent={C.orange} align="bottom" delay={6} /></Sequence>
    <Sequence {...seg(14)}><HudPanel label="THE FUTURE" lines={["FIX THE SHIP.", "TAKE THE SCIENCE HOME."]} dur={len(14)} x={84} y={76} size={50} align="bottom" delay={8} /></Sequence>

    {/* Transiciones: capas propias sobre la rejilla exacta de cortes. */}
    {STREAKS.map((s) => (
      <Sequence key={`s${s.at}`} from={s.at - 3} durationInFrames={8}><Streak dir={s.dir} color={s.color} /></Sequence>
    ))}

    <Grain />
    <Audio src={staticFile("ares/mix.wav")} />
    {SFX.map((s) => (
      <Sequence key={s.src + s.at} from={Math.max(0, s.at - 2)} durationInFrames={70}>
        <Audio src={staticFile(s.src)} volume={s.vol} />
      </Sequence>
    ))}
  </AbsoluteFill>
);
