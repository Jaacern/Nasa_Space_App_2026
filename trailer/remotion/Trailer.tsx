/* ARES FORGE: tráiler de 29,9 s (1920x1080, 60 fps) para NASA Space Apps 2026. Versión 3 (montaje humano).
   Lenguaje de edición tomado de tráileres de roguelites de acción (Risk of Rain 2, Hades): cortes secos al golpe de la
   música (onsets medidos en mix.wav), planos de duración variable, montaje rápido, tarjeta en negro para el gancho,
   y texto que cruza varios cortes. Los rótulos usan el lenguaje visual del HUD del juego (paneles navy con borde cian,
   esquinas, etiquetas en mono que se teclean), no tipografía genérica centrada.
   Fuentes de la identidad del juego (Ui.luau): Michroma (logo), Sarpanch (titulares), Jura (texto), Roboto Mono (datos). */
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
  <AbsoluteFill style={{ background: `radial-gradient(ellipse 78% 72% at 50% 48%, rgba(0,0,0,0) 58%, rgba(4,6,12,${k}) 100%)` }} />
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
// Destello de impacto al entrar un plano (pocos cuadros, blanco o cálido).
const Hit: React.FC<{ n?: number; color?: string; k?: number }> = ({ n = 4, color = "#fff", k = 0.85 }) => {
  const f = useCurrentFrame();
  return <AbsoluteFill style={{ background: color, opacity: interpolate(f, [0, n], [k, 0], clamp) }} />;
};

const Footage: React.FC<{ src: string; dur: number; push?: number; punch?: number; shake?: number; grade?: string; from?: number }> = ({
  src, dur, push = 1.04, punch = 1.06, shake = 0, grade = "contrast(1.07) saturate(1.12)", from = 0,
}) => {
  const f = useCurrentFrame();
  const z = interpolate(f, [0, dur], [1, push], clamp) * interpolate(f, [0, 12], [punch, 1], { ...clamp, easing: ease });
  const amp = shake * interpolate(f, [0, 18], [1, 0], clamp);
  const dx = (random(`x${f}`) - 0.5) * amp, dy = (random(`y${f}`) - 0.5) * amp;
  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <AbsoluteFill style={{ transform: `translate(${dx}px,${dy}px) scale(${z})`, filter: grade }}>
        <OffthreadVideo src={staticFile(`ares/${src}`)} startFrom={from} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ---------- Rótulos con el lenguaje del HUD del juego ----------
const typed = (s: string, f: number, speed = 1.6) => s.slice(0, Math.max(0, Math.floor(f * speed)));
const Corners: React.FC<{ c?: string }> = ({ c = C.cyan }) => {
  const s = { position: "absolute" as const, width: 14, height: 14, borderColor: c, borderStyle: "solid" };
  return (<>
    <div style={{ ...s, left: -1, top: -1, borderWidth: "2px 0 0 2px" }} /><div style={{ ...s, right: -1, top: -1, borderWidth: "2px 2px 0 0" }} />
    <div style={{ ...s, left: -1, bottom: -1, borderWidth: "0 0 2px 2px" }} /><div style={{ ...s, right: -1, bottom: -1, borderWidth: "0 2px 2px 0" }} />
  </>);
};
// Panel: se despliega como los paneles del juego (barrido horizontal), teclea su etiqueta y sale con parpadeo.
const HudPanel: React.FC<{
  label: string; lines: string[]; dur: number; x: number; y: number; size?: number; accent?: string; align?: "top" | "bottom"; delay?: number; tilt?: number;
}> = ({ label, lines, dur, x, y, size = 54, accent = C.cyan, align = "bottom", delay = 0, tilt = -1 }) => {
  const f = Math.floor((useCurrentFrame() - delay) / 2) * 2; // animación "en dos", menos perfecta
  if (f < 0) return null;
  const open = interpolate(f, [0, 9], [0, 100], { ...clamp, easing: ease });
  const end = dur - delay;
  const flick = f > end - 8 ? ([1, 0.2, 0.9, 0, 0.6, 0, 0, 0][f - (end - 8)] ?? 0) : 1;
  const cursorOn = Math.floor(f / 8) % 2 === 0;
  const lab = typed(label, f - 4, 1.8);
  return (
    <div style={{ position: "absolute", left: x, [align]: y, opacity: flick, clipPath: `inset(-20px ${100 - open}% -20px -20px)`, transform: `rotate(${tilt}deg)` }}>
      <div style={{ position: "relative", background: `rgba(${C.panel},0.78)`, border: "1px solid rgba(0,210,255,0.35)", padding: "16px 30px 20px 26px", borderLeft: `4px solid ${accent}` }}>
        <Corners c={accent} />
        <div style={{ fontFamily: F.mono, fontSize: 19, letterSpacing: 4, color: accent, height: 26 }}>
          {"// " + lab}{lab.length < label.length || cursorOn ? <span style={{ color: C.text }}>▌</span> : null}
        </div>
        {lines.map((ln, i) => {
          const t = interpolate(f, [8 + i * 5, 16 + i * 5], [0, 1], { ...clamp, easing: ease });
          return (
            <div key={i} style={{ overflow: "hidden" }}>
              <div style={{ fontFamily: F.head, fontWeight: 700, fontSize: size, lineHeight: 1.05, letterSpacing: 2, color: C.text, transform: `translateX(${(1 - t) * -40}px)`, opacity: t, whiteSpace: "nowrap" }}>{ln}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
// Etiqueta mínima de esquina (equipo, fuente de datos).
const Tag: React.FC<{ text: string; sub?: string; dur: number; x?: number; y?: number; delay?: number }> = ({ text, sub, dur, x = 80, y = 66, delay = 0 }) => {
  const f = useCurrentFrame() - delay;
  if (f < 0) return null;
  const out = interpolate(f, [dur - delay - 8, dur - delay], [1, 0], clamp);
  return (
    <div style={{ position: "absolute", left: x, top: y, opacity: out }}>
      <div style={{ fontFamily: F.head, fontWeight: 700, fontSize: 30, letterSpacing: 7, color: C.text, textShadow: "0 2px 14px rgba(0,0,0,0.7)" }}>{typed(text, f, 1.4)}</div>
      {sub ? <div style={{ fontFamily: F.mono, fontSize: 17, letterSpacing: 5, color: C.cyan, marginTop: 4, textShadow: "0 2px 10px rgba(0,0,0,0.8)" }}>{typed(sub, f - 10, 1.6)}</div> : null}
    </div>
  );
};

// Nota a mano: texto de rotulador + trazo que se dibuja (flecha o círculo). Tiembla un poco, como dibujo animado a mano.
const Note: React.FC<{ text: string; x: number; y: number; path: string; head?: string; rot?: number; size?: number; delay?: number; dur: number; color?: string }> = ({
  text, x, y, path, head, rot = -4, size = 40, delay = 0, dur, color = "#FFE14D",
}) => {
  const f = useCurrentFrame() - delay;
  if (f < 0) return null;
  const k = Math.floor(f / 4);
  const jx = (random(`nx${k}`) - 0.5) * 2, jy = (random(`ny${k}`) - 0.5) * 2, jr = (random(`nr${k}`) - 0.5) * 0.8;
  const draw = interpolate(f, [0, 14], [1, 0], { ...clamp, easing: Easing.out(Easing.quad) });
  const txt = interpolate(f, [8, 12], [0, 1], clamp);
  const out = interpolate(f, [dur - delay - 6, dur - delay], [1, 0], clamp);
  return (
    <AbsoluteFill style={{ opacity: out, transform: `translate(${jx}px,${jy}px)` }}>
      <svg width="1920" height="1080" style={{ position: "absolute" }}>
        <path d={path} fill="none" stroke={color} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray="1" strokeDashoffset={draw} style={{ filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.6))" }} />
        {head ? <path d={head} fill="none" stroke={color} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" opacity={draw < 0.05 ? 1 : 0} /> : null}
      </svg>
      <div style={{ position: "absolute", left: x, top: y, transform: `rotate(${rot + jr}deg)`, fontFamily: F.hand, fontSize: size, color, opacity: txt, textShadow: "0 3px 8px rgba(0,0,0,0.7)", whiteSpace: "nowrap" }}>{text}</div>
    </AbsoluteFill>
  );
};

// ---------- Planos especiales ----------
const BlackCard: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const words = ["YOUR", "SHIP", "WENT", "DOWN."];
  return (
    <AbsoluteFill style={{ background: "#020308", justifyContent: "center", alignItems: "center" }}>
      <div style={{ display: "flex", gap: 26 }}>
        {words.map((w, i) => (
          <span key={i} style={{ fontFamily: F.punch, fontSize: 150, letterSpacing: 3, color: i === 3 ? C.orange : C.text, opacity: f >= i * 6 ? 1 : 0, display: "inline-block", transform: `rotate(${[-3, 2, -1, 4][i]}deg) translateY(${[0, -8, 6, -4][i]}px) scale(${f >= i * 6 && f < i * 6 + 3 ? 1.15 : 1})` }}>{w}</span>
        ))}
      </div>
      <div style={{ position: "absolute", bottom: 300, fontFamily: F.mono, fontSize: 20, letterSpacing: 6, color: C.dim, opacity: f > 26 ? 1 : 0 }}>{typed("SOL 01 · JEZERO CRATER · MARS", f - 26, 2.2)}</div>
      <AbsoluteFill style={{ background: "#000", opacity: interpolate(f, [dur - 3, dur], [0, 1], clamp) }} />
    </AbsoluteFill>
  );
};

const Title: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const letters = "ARES FORGE".split("");
  const line = interpolate(f, [8, 34], [0, 1], { ...clamp, easing: ease });
  const tag = interpolate(f, [30, 46], [0, 1], clamp);
  const ca = interpolate(f, [0, 10], [10, 0], clamp); // separación cromática al golpe
  return (
    <AbsoluteFill>
      <Footage src="title.mp4" dur={dur} push={1.07} punch={1.12} grade="contrast(1.08) saturate(1.1) brightness(0.8)" />
      <Vignette k={0.75} />
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <div style={{ position: "relative", transform: `scale(${interpolate(f, [0, 24], [1.12, 1], { ...clamp, easing: ease })})` }}>
          {[["rgba(255,60,60,0.7)", -ca], ["rgba(0,210,255,0.7)", ca], [C.text, 0]].map(([col, dx], k) => (
            <div key={k} style={{ position: k < 2 ? "absolute" : "relative", left: 0, top: 0, display: "flex", transform: `translateX(${dx}px)`, mixBlendMode: k < 2 ? "screen" : "normal", opacity: k < 2 ? (ca > 0 ? 1 : 0) : 1 }}>
              {letters.map((ch, i) => {
                const t = interpolate(f, [i * 1.2, 8 + i * 1.2], [0, 1], { ...clamp, easing: ease });
                return <span key={i} style={{ fontFamily: F.logo, fontSize: 150, color: col as string, letterSpacing: 22, opacity: t, whiteSpace: "pre", textShadow: k === 2 ? "0 0 40px rgba(0,210,255,0.35), 0 6px 30px rgba(0,0,0,0.6)" : "none" }}>{ch}</span>;
              })}
            </div>
          ))}
        </div>
        <div style={{ width: 760 * line, height: 3, marginTop: 18, background: `linear-gradient(90deg, transparent, ${C.orange}, transparent)` }} />
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 27, letterSpacing: 7, color: C.gold, marginTop: 22, opacity: tag }}>SURVIVE MARS · RECOVER REAL SPACECRAFT SYSTEMS · GO HOME</div>
      </AbsoluteFill>
      <AbsoluteFill style={{ background: "#000", opacity: interpolate(f, [dur - 4, dur], [0, 0.6], clamp) }} />
    </AbsoluteFill>
  );
};

const Phone: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const W = 1300, H = Math.round(W * 864 / 1736), B = 22;
  const ry = interpolate(f, [0, dur], [-9, -2], clamp);
  const s = interpolate(f, [0, 20], [0.88, 1], { ...clamp, easing: ease });
  return (
    <AbsoluteFill style={{ background: C.bg }}>
      <AbsoluteFill style={{ filter: "blur(36px) brightness(0.45) saturate(1.1)", transform: "scale(1.15)" }}>
        <OffthreadVideo src={staticFile("ares/loop.mp4")} muted style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </AbsoluteFill>
      <AbsoluteFill style={{ alignItems: "flex-end", justifyContent: "center", paddingRight: 90, perspective: 2400 }}>
        <div style={{
          width: W + B * 2, height: H + B * 2, borderRadius: 86, background: "linear-gradient(145deg,#2a2f3a,#0b0d12 40%,#1c2029)", padding: B,
          boxShadow: "0 40px 90px rgba(0,0,0,0.65), inset 0 0 0 2px rgba(255,255,255,0.10)", transform: `rotateY(${ry}deg) rotateX(3deg) scale(${s})`, marginTop: -60,
        }}>
          <div style={{ width: W, height: H, borderRadius: 66, overflow: "hidden", position: "relative", background: "#000" }}>
            <OffthreadVideo src={staticFile("ares/phone.mp4")} muted style={{ width: "100%", height: "100%", objectFit: "cover", filter: "contrast(1.05) saturate(1.1)" }} />
            <div style={{ position: "absolute", left: 18, top: "50%", width: 32, height: 116, marginTop: -58, borderRadius: 20, background: "#000" }} />
            <div style={{ position: "absolute", inset: 0, background: `linear-gradient(115deg, rgba(255,255,255,0) ${interpolate(f, [0, dur], [20, 60])}%, rgba(255,255,255,0.09) ${interpolate(f, [0, dur], [28, 68])}%, rgba(255,255,255,0) ${interpolate(f, [0, dur], [40, 80])}%)` }} />
          </div>
        </div>
      </AbsoluteFill>
      <HudPanel label="COMING TO ROBLOX" lines={["PC · MOBILE", "TABLET · CONSOLE"]} dur={dur} x={90} y={70} size={46} accent={C.gold} delay={10} />
      <Note dur={dur} delay={30} text="same game, in your pocket" x={70} y={128} rot={-5} size={42}
        path="M 330 205 C 430 220, 480 270, 515 345" head="M 486 330 L 516 348 L 520 312" />
      <Hit n={5} k={0.5} />
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
        position: "absolute", left: 960 - 1500, top: 820 + rise, width: 3000, height: 3000, borderRadius: "50%",
        background: "radial-gradient(circle at 50% 0%, #D2602E 0%, #7A2C14 5%, #2A0E08 13%, #07030A 24%)",
        boxShadow: "0 -6px 40px rgba(255,120,60,0.55), 0 -30px 120px rgba(255,90,40,0.25)",
      }} />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse 60% 25% at 50% 100%, rgba(255,107,53,0.18), rgba(0,0,0,0) 70%)" }} />
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
      <AbsoluteFill style={{ alignItems: "center", paddingTop: 150 }}>
        <div style={{ fontFamily: F.logo, fontSize: 112, letterSpacing: interpolate(f, [0, 40], [34, 20], { ...clamp, easing: ease }), color: C.text, opacity: a(0, 18), textShadow: "0 0 36px rgba(0,210,255,0.35)" }}>ARES FORGE</div>
        <div style={{ width: 600 * a(8, 36), height: 3, marginTop: 12, background: `linear-gradient(90deg, transparent, ${C.orange}, transparent)` }} />
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 25, letterSpacing: 6, color: C.gold, marginTop: 18, opacity: a(14) }}>LEARN SPACE ENGINEERING BY PLAYING</div>
        <div style={{ fontFamily: F.head, fontWeight: 700, fontSize: 42, letterSpacing: 10, color: C.text, marginTop: 50, opacity: a(26) }}>COMING TO ROBLOX</div>
        <div style={{ display: "flex", gap: 56, marginTop: 22 }}>
          {[["pc", "PC"], ["mobile", "MOBILE"], ["tablet", "TABLET"], ["console", "CONSOLE"]].map(([k, n], i) => (
            <div key={k} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8, opacity: a(32 + i * 4) }}>
              <Icon k={k} />
              <div style={{ fontFamily: F.mono, fontSize: 16, letterSpacing: 4, color: C.dim }}>{n}</div>
            </div>
          ))}
        </div>
        <div style={{ fontFamily: F.head, fontWeight: 700, fontSize: 30, letterSpacing: 6, color: C.cyan, marginTop: 44, opacity: a(50) }}>TEAM CODE OR DIE · CONCEPCIÓN, CHILE</div>
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 22, letterSpacing: 3, color: C.text, marginTop: 10, opacity: a(54) }}>GONZALO MALDONADO · JAVIER CERNA · CRISTÓBAL PALMA</div>
        <div style={{ fontFamily: F.mono, fontSize: 17, letterSpacing: 4, color: C.dim, marginTop: 10, opacity: a(60) }}>NASA SPACE APPS CHALLENGE 2026 · SPACE MISSION DESIGN GAME</div>
      </AbsoluteFill>
      <div style={{ position: "absolute", width: "100%", bottom: 30, textAlign: "center", fontFamily: F.body, fontSize: 16, lineHeight: 1.55, color: "rgba(200,210,228,0.85)", opacity: a(64) }}>
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

export const AresTrailer: React.FC = () => (
  <AbsoluteFill style={{ background: "#000" }}>
    {/* 0 · caída (IA) */}
    <Sequence {...seg(0)}><Footage src="crash.mp4" dur={len(0)} push={1.05} punch={1} grade="contrast(1.05) saturate(1.06)" /><Vignette k={0.6} /></Sequence>
    {/* 1 · tarjeta negra */}
    <Sequence {...seg(1)}><BlackCard dur={len(1)} /></Sequence>
    {/* 2 · impacto (IA) */}
    <Sequence {...seg(2)}><Footage src="crash.mp4" from={168} dur={len(2)} push={1.08} punch={1.1} shake={18} grade="contrast(1.06) saturate(1.08)" /><Vignette k={0.6} /><Hit n={5} color="#FFE2C8" /></Sequence>
    {/* 3 · título (golpe 5.49 s) */}
    <Sequence {...seg(3)}><Title dur={len(3)} /><Hit n={10} /></Sequence>
    {/* 4 · bucle */}
    <Sequence {...seg(4)}><Footage src="loop.mp4" dur={len(4)} /><Vignette /></Sequence>
    {/* 5 · cartas */}
    <Sequence {...seg(5)}><Footage src="cards.mp4" dur={len(5)} push={1.0} punch={1.0} /><Vignette /><Hit n={3} k={0.4} /></Sequence>
    {/* 6-9 · jefe + montaje rápido */}
    <Sequence {...seg(6)}><Footage src="boss.mp4" dur={len(6)} shake={16} punch={1.1} /><Vignette /><Hit n={3} /></Sequence>
    <Sequence {...seg(7)}><Footage src="m1.mp4" dur={len(7)} punch={1.12} shake={10} /><Hit n={2} k={0.6} /></Sequence>
    <Sequence {...seg(8)}><Footage src="m2.mp4" dur={len(8)} punch={1.12} shake={10} /><Hit n={2} k={0.6} /></Sequence>
    <Sequence {...seg(9)}><Footage src="m3.mp4" dur={len(9)} push={1.08} punch={1.1} /><Vignette /><Hit n={2} k={0.6} /></Sequence>
    {/* 10 · pieza MMRTG */}
    <Sequence {...seg(10)}><Footage src="parts.mp4" dur={len(10)} push={1.08} punch={1.04} /><Vignette k={0.4} /></Sequence>
    {/* 11-12 · horda + bólido */}
    <Sequence {...seg(11)}><Footage src="m4.mp4" dur={len(11)} punch={1.1} shake={8} /><Hit n={2} k={0.5} /></Sequence>
    <Sequence {...seg(12)}><Footage src="data.mp4" dur={len(12)} shake={12} punch={1.1} /><Vignette /><Hit n={3} color="#FFD2B0" /></Sequence>
    {/* 13 · celular */}
    <Sequence {...seg(13)}><Phone dur={len(13)} /></Sequence>
    {/* 14 · despegue (IA) */}
    <Sequence {...seg(14)}><Footage src="liftoff.mp4" dur={len(14) + 14} push={1.07} punch={1.06} grade="contrast(1.06) saturate(1.08)" /><Vignette k={0.6} /></Sequence>
    {/* 15 · tarjeta final */}
    <Sequence {...seg(15)}><End dur={len(15)} /></Sequence>

    {/* Rótulos (algunos cruzan varios cortes) */}
    <Sequence {...seg(0)}><Tag text="TEAM CODE OR DIE" sub="CONCEPCIÓN, CHILE" dur={len(0)} /></Sequence>
    <Sequence {...seg(2)}><HudPanel label="NASA SPACE APPS CHALLENGE 2026" lines={["SPACE MISSION", "DESIGN GAME"]} dur={len(2)} x={90} y={80} size={50} accent={C.orange} delay={8} /></Sequence>
    <Sequence {...seg(4)}><HudPanel label="IMPLICIT LEARNING" lines={["PLAY FIRST.", "THE SCIENCE SNEAKS IN."]} dur={len(4)} x={90} y={250} size={50} delay={4} /></Sequence>
    <Sequence {...seg(5)}><Note dur={len(5)} delay={14} text="every card = a real NASA fact" x={1180} y={958} rot={-3} size={44}
      path="M 712 640 C 760 600, 1180 598, 1214 650 C 1240 700, 1190 806, 958 812 C 760 818, 700 760, 704 690 C 706 664, 730 646, 760 642" /></Sequence>
    <Sequence {...span(6, 10)}><HudPanel label="MISSION DESIGN" lines={["4 BOSSES.", "EACH ONE STOLE A PIECE OF YOUR SHIP."]} dur={CUT[10] - CUT[6]} x={90} y={90} size={46} accent={C.orange} delay={6} /></Sequence>
    <Sequence {...seg(10)}><Tag text="SOURCE · NASA TECHNICAL REPORTS SERVER" sub="MMRTG · HIGH-GAIN ANTENNA · MOXIE · ORION ENGINE" dur={len(10)} x={90} y={60} delay={6} /></Sequence>
    <Sequence {...span(11, 13)}><HudPanel label="NASA DONKI · INSIGHT · CHANDRA" lines={["REAL SPACE WEATHER.", "VERY REAL PROBLEMS."]} dur={CUT[13] - CUT[11]} x={90} y={250} size={50} accent={C.orange} delay={6} /></Sequence>
    <Sequence {...seg(14)}><HudPanel label="THE FUTURE" lines={["FIX THE SHIP.", "TAKE THE SCIENCE HOME."]} dur={len(14)} x={90} y={90} size={52} delay={8} /></Sequence>

    <Grain />
    <Audio src={staticFile("ares/mix.wav")} />
    {[CUT[4], CUT[10], CUT[13]].map((c, i) => (
      <Sequence key={c} from={c - 8} durationInFrames={50}><Audio src={staticFile(i % 2 ? "ares/swoosh.mp3" : "ares/whoosh.mp3")} volume={0.3} /></Sequence>
    ))}
  </AbsoluteFill>
);
