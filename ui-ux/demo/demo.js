/* Maqueta ORBITAL UI · interacciones mínimas, sin dependencias. */
(() => {
  "use strict";

  /* Reloj UTC de cabina */
  const clock = document.getElementById("utc-clock");
  const tick = () => {
    if (!clock) return;
    const d = new Date();
    const hh = String(d.getUTCHours()).padStart(2, "0");
    const mm = String(d.getUTCMinutes()).padStart(2, "0");
    const ss = String(d.getUTCSeconds()).padStart(2, "0");
    clock.textContent = `${hh}:${mm}:${ss} UTC`;
  };
  tick();
  setInterval(tick, 1000);

  /* Pestañas accesibles */
  document.querySelectorAll('[role="tablist"]').forEach((list) => {
    const tabs = [...list.querySelectorAll('[role="tab"]')];
    const select = (tab) => {
      tabs.forEach((t) => {
        const active = t === tab;
        t.setAttribute("aria-selected", String(active));
        t.tabIndex = active ? 0 : -1;
        const panel = document.getElementById(t.getAttribute("aria-controls"));
        if (panel) panel.hidden = !active;
      });
    };
    tabs.forEach((tab, i) => {
      tab.addEventListener("click", () => select(tab));
      tab.addEventListener("keydown", (e) => {
        if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(e.key)) return;
        e.preventDefault();
        let next = i;
        if (e.key === "ArrowLeft") next = (i - 1 + tabs.length) % tabs.length;
        if (e.key === "ArrowRight") next = (i + 1) % tabs.length;
        if (e.key === "Home") next = 0;
        if (e.key === "End") next = tabs.length - 1;
        tabs[next].focus();
        select(tabs[next]);
      });
    });
  });

  /* Copiar hex de las muestras */
  const toast = document.getElementById("toast");
  let toastTimer;
  const showToast = (text) => {
    if (!toast) return;
    toast.textContent = text;
    toast.classList.add("is-visible");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 1600);
  };

  const copy = async (text) => {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch {
      const area = document.createElement("textarea");
      area.value = text;
      area.style.position = "fixed";
      area.style.opacity = "0";
      document.body.appendChild(area);
      area.select();
      const ok = document.execCommand("copy");
      area.remove();
      return ok;
    }
  };

  document.querySelectorAll("[data-copy]").forEach((el) => {
    el.addEventListener("click", async () => {
      const value = el.getAttribute("data-copy");
      const ok = await copy(value);
      showToast(ok ? `${value} copiado al portapapeles` : `No se pudo copiar ${value}`);
    });
  });

  /* Slider de energía */
  const range = document.getElementById("energia");
  const rangeValue = document.getElementById("energia-val");
  const syncRange = () => {
    if (!range) return;
    const value = Number(range.value);
    range.style.setProperty("--ux-range-value", `${value}%`);
    if (rangeValue) rangeValue.textContent = `${value}%`;
  };
  range?.addEventListener("input", syncRange);
  syncRange();

  /* Medidores: animan al entrar en pantalla */
  const fills = [...document.querySelectorAll(".ux-meter__fill")];
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const el = entry.target;
          const target = el.style.getPropertyValue("--ux-value") || "50%";
          el.style.setProperty("--ux-value", "0%");
          requestAnimationFrame(() => {
            requestAnimationFrame(() => el.style.setProperty("--ux-value", target));
          });
          io.unobserve(el);
        });
      },
      { threshold: 0.35 }
    );
    fills.forEach((f) => io.observe(f));
  }

  /* Año del footer, si se añade un nodo con data-year */
  document.querySelectorAll("[data-year]").forEach((el) => {
    el.textContent = String(new Date().getFullYear());
  });
})();
