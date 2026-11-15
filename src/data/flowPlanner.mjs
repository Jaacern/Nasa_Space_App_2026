/**
 * Planificador y optimizador Precio/Calidad para Google Flow (Veo 3.1)
 * conectado a los snapshots reales de NASA del proyecto (rover_photos, mars_weather,
 * space_weather, radiation, mars_layers).
 *
 * Diseñado para alimentar la futura Landing Page 3D interactiva (5 entornos x 5 videos = 25 assets)
 * sin superar el presupuesto de créditos del usuario (por defecto: 1050 puntos).
 */

export const FLOW_TIERS = {
  veo_3_1_lite: { id: "veo_3_1_lite", label: "Veo 3.1 Lite", credits: 10, resolution: "720p" },
  veo_3_1_fast: { id: "veo_3_1_fast", label: "Veo 3.1 Fast", credits: 20, resolution: "1080p" },
  veo_3_1_quality: { id: "veo_3_1_quality", label: "Veo 3.1 Quality", credits: 100, resolution: "1080p HQ" },
};

/**
 * Optimiza la asignación de modelo (Lite / Fast / Quality) para los 25 videos
 * según los créditos disponibles (ej. 1050 puntos), reservando un margen de seguridad
 * (por defecto 15% o al menos 150 créditos si el presupuesto lo permite) para reintentos.
 */
export function optimizeFlowBudget(plan, { credits = 1050, reserveRatio = 0.18 } = {}) {
  const budget = Math.max(0, Math.floor(Number(credits) || 1050));
  const targetReserve = budget >= 400 ? Math.floor(budget * reserveRatio) : 0;
  const maxSpend = Math.max(0, budget - targetReserve);

  const environments = structuredClone(plan.journeyFlow ?? []);
  const allVideos = environments.flatMap((env) =>
    env.videos.map((v, idx) => ({ envId: env.environmentId, isHero: idx === 0, video: v })),
  );

  // 1. Asignación inicial según el plan recomendado
  const costOf = (tierId) => FLOW_TIERS[tierId]?.credits ?? 20;
  const totalCost = () => allVideos.reduce((sum, item) => sum + costOf(item.video.tier), 0);

  // 2. Si el presupuesto máximo es menor que el plan base (820 cr), degradar progresivamente:
  //    Primero degradar Hero de Quality (100) -> Fast (20) en entornos secundarios,
  //    luego Fast (20) -> Lite (10) en videos no-Hero.
  const heroPriorityOrder = ["universo", "luna", "tierra", "marte", "despegue"];
  for (const envId of heroPriorityOrder) {
    if (totalCost() <= maxSpend) break;
    const hero = allVideos.find((x) => x.envId === envId && x.isHero && x.video.tier === "veo_3_1_quality");
    if (hero) {
      hero.video.tier = "veo_3_1_fast";
      hero.video.credits = FLOW_TIERS.veo_3_1_fast.credits;
    }
  }

  for (let i = allVideos.length - 1; i >= 0; i--) {
    if (totalCost() <= maxSpend) break;
    const item = allVideos[i];
    if (!item.isHero && item.video.tier === "veo_3_1_fast") {
      item.video.tier = "veo_3_1_lite";
      item.video.credits = FLOW_TIERS.veo_3_1_lite.credits;
    }
  }

  // 3. Si aún supera el presupuesto total bruto, degradar los últimos Lite o marcar cuáles entran
  for (const item of allVideos) {
    item.video.credits = costOf(item.video.tier);
    item.video.tierLabel = FLOW_TIERS[item.video.tier]?.label ?? item.video.tier;
  }

  const spent = totalCost();
  const counts = {
    veo_3_1_quality: allVideos.filter((x) => x.video.tier === "veo_3_1_quality").length,
    veo_3_1_fast: allVideos.filter((x) => x.video.tier === "veo_3_1_fast").length,
    veo_3_1_lite: allVideos.filter((x) => x.video.tier === "veo_3_1_lite").length,
  };

  return {
    budget: {
      availableCredits: budget,
      plannedSpendCredits: spent,
      remainingReserveCredits: budget - spent,
      withinLimit: spent <= budget,
      totalVideos: allVideos.length,
      tierBreakdown: {
        quality_100cr: { count: counts.veo_3_1_quality, credits: counts.veo_3_1_quality * 100 },
        fast_20cr: { count: counts.veo_3_1_fast, credits: counts.veo_3_1_fast * 20 },
        lite_10cr: { count: counts.veo_3_1_lite, credits: counts.veo_3_1_lite * 10 },
      },
      retryCapacity: {
        extraFastRetries: Math.floor(Math.max(0, budget - spent) / 20),
        extraLiteRetries: Math.floor(Math.max(0, budget - spent) / 10),
        extraQualityRetries: Math.floor(Math.max(0, budget - spent) / 100),
      },
    },
    environments,
  };
}

/**
 * Enriquecimiento en vivo de los prompts con los snapshots reales de data/curated/
 * (fotos de Perseverance/Curiosity, clima de InSight, tormentas de DONKI y dosis de RadLab).
 */
export function enrichPlanWithSnapshots(plan, snapshots = {}) {
  const copy = structuredClone(plan);
  const photos = snapshots.roverPhotos?.photos ?? [];
  const sols = snapshots.marsWeather?.sols ?? [];
  const latestSol = sols.at(-1) ?? null;
  const maxThreat = snapshots.spaceWeather?.summary?.maxThreat ?? 0.9;
  const ratios = snapshots.radiation?.ratiosToLeoIss ?? {};

  // Sincronizar las URLs de rover_photos.json reales en los videos de Marte si existen
  const mczLeft = photos.find((p) => p.camera === "MCZ_LEFT") ?? photos[0];
  const navLeft = photos.find((p) => p.camera === "NAV_LEFT_B") ?? photos[2];
  const mczRight = photos.find((p) => p.camera === "MCZ_RIGHT") ?? photos[1];

  for (const env of copy.journeyFlow ?? []) {
    for (const v of env.videos ?? []) {
      if (v.id === "mars-02" && mczLeft?.imageUrl) {
        v.referenceImageUrl = mczLeft.imageUrl;
        v.liveDataContext = `${mczLeft.rover} Sol ${mczLeft.sol} (${mczLeft.earthDate}) · Cámara ${mczLeft.camera}`;
      }
      if (v.id === "mars-03" && navLeft?.imageUrl) {
        v.referenceImageUrl = navLeft.imageUrl;
        const wind = latestSol?.windMs?.avg != null ? `, viento medio InSight ${latestSol.windMs.avg} m/s` : "";
        const temp = latestSol?.tempC?.avg != null ? `, temp media ${latestSol.tempC.avg} °C` : "";
        v.liveDataContext = `${navLeft.rover} Sol ${navLeft.sol} (${navLeft.earthDate})${wind}${temp}`;
      }
      if (v.id === "mars-04" && mczRight?.imageUrl) {
        v.referenceImageUrl = mczRight.imageUrl;
        v.liveDataContext = `${mczRight.rover} Sol ${mczRight.sol} · Múltiplo radiación órbita marciana vs ISS: ${ratios["mars-orbit-liulin"] ?? 3.62}x`;
      }
      if (v.id === "universe-01") {
        v.liveDataContext = `Amenaza máxima reciente en DONKI: ${maxThreat} · Ratio radiación Orion vs ISS: ${ratios["moon-orion-artemis1"] ?? 4.1}x`;
      }
    }
  }
  return copy;
}
