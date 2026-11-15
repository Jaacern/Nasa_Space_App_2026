/**
 * Motor de simulación de partida de 30 soles para Outpost Run (Junior Astronaut Mission Trainer).
 * Funciona en navegador y en Node (ESM sin dependencias externas).
 * Conecta los datos reales de worldState.mjs con las reglas de content/balance.json y content/cards.json.
 */
import {
  commDelaySec,
  EFFECT_TO_TOPIC,
  getScenario,
  makeRng,
  pickFact,
  scheduleEvents,
  siteProfile,
} from "../data/worldState.mjs";

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

export function createMission({
  world,
  balance,
  cardsData,
  siteId = "mars",
  scenarioId = "gannon-2024-05",
  seed = 2026,
}) {
  const rng = makeRng(seed);
  const profile = siteProfile(world, siteId);
  const scenario = getScenario(world, scenarioId);
  const totalSols = balance.run.sols ?? 30;
  const scheduled = scheduleEvents(scenario, siteId, { sols: totalSols, minThreat: 0.1 });
  const deck = (cardsData.cards ?? []).filter((c) => c.sites.includes(siteId));

  const state = {
    siteId,
    scenarioId,
    seed,
    sol: 0,
    totalSols,
    ended: false,
    outcome: null, // "victory" | "air_depleted" | "radiation_limit"
    stars: 0,
    power: balance.start.power,
    air: balance.start.air,
    shield: balance.start.shield,
    dose: balance.start.dose,
    science: 0,
    powerMode: "normal",
    shelterUnlocked: false,
    commsReliable: false,
    installed: [], // [{ id, installedSol }]
    scheduled,
    profile,
    scenario,
    offeredCards: [],
    history: [],
    factsUnlocked: [],
  };

  state.offeredCards = drawCards(state, deck, rng, balance.run.cardsOffered ?? 3);
  return { state, balance, deck, world, rng };
}

function countInstalled(state, cardId) {
  return state.installed.filter((c) => c.id === cardId).length;
}

function drawCards(state, deck, rng, count = 3) {
  const eligible = deck.filter((c) => countInstalled(state, c.id) < (c.stackLimit ?? 1));
  const pool = [...eligible];
  const picked = [];
  while (picked.length < count && pool.length > 0) {
    const idx = Math.floor(rng() * pool.length);
    picked.push(pool.splice(idx, 1)[0]);
  }
  return picked;
}

export function getSolContext(mission) {
  const { state, balance } = mission;
  const sol = state.sol;
  const activeEvents = state.scheduled.filter(
    (e) => e.hitsSite && ((e.arrivalSol != null && e.arrivalSol === sol) || (e.arrivalSol == null && e.sol === sol)),
  );
  const warnings = state.scheduled.filter(
    (e) => e.hitsSite && e.warningSols != null && e.warningSols > 0 && e.sol <= sol && e.arrivalSol > sol,
  );
  const isLunarNight =
    state.siteId === "moon" &&
    sol % (balance.sites.moon.lightCycle.lightSols + balance.sites.moon.lightCycle.darkSols) >=
      balance.sites.moon.lightCycle.lightSols;

  return {
    solNumber: sol + 1,
    totalSols: state.totalSols,
    commDelaySec: Math.round(commDelaySec(state.siteId, sol)),
    isLunarNight,
    activeEvents,
    warnings,
  };
}

export function stepSol(mission, { cardId = null, powerMode = "normal", useShelter = false } = {}) {
  const { state, balance, deck, world, rng } = mission;
  if (state.ended) return state;

  const sol = state.sol;
  const notes = [];
  state.powerMode = balance.powerModes[powerMode] ? powerMode : "normal";

  // 1. Instalar carta elegida (si hay energía suficiente)
  let installedCard = null;
  if (cardId) {
    const card = deck.find((c) => c.id === cardId);
    const costPower = card?.immediateCost?.power ?? 0;
    if (card && countInstalled(state, card.id) < card.stackLimit && state.power >= costPower) {
      state.power -= costPower;
      state.installed.push({ id: card.id, installedSol: sol });
      installedCard = card;
      if (card.benefit?.shield) {
        state.shield = clamp(state.shield + card.benefit.shield, 0, balance.caps.shield);
      }
      if (card.benefit?.unlocksShelter) state.shelterUnlocked = true;
      if (card.benefit?.commsReliable) state.commsReliable = true;
      notes.push(`Construido: ${card.name.es} (-${costPower} energía)`);
      if (card.dataTopic) {
        const f = pickFact(world, card.dataTopic, rng);
        if (f && !state.factsUnlocked.some((x) => x.accession === f.accession)) {
          state.factsUnlocked.push(f);
        }
      }
    }
  }

  // 2. Generación solar del sitio (día/noche lunar o tormenta de polvo marciana)
  const ctx = getSolContext(mission);
  let solarGen = balance.sites[state.siteId]?.solarGeneration ?? 14;
  let dustStorm = false;
  if (state.siteId === "moon" && ctx.isLunarNight) {
    solarGen = 2; // Reserva mínima en noche lunar
    notes.push("Noche lunar activa: generación solar reducida al mínimo.");
  } else if (state.siteId === "mars") {
    if (rng() < (balance.sites.mars.dustStormChancePerSol ?? 0.03)) {
      dustStorm = true;
      solarGen = Math.round(solarGen * (balance.sites.mars.dustStormPowerFactor ?? 0.4));
      notes.push("Tormenta de polvo en Marte: los paneles solares rinden al 40%.");
    }
  }

  // 3. Beneficios y costos diferidos de cartas instaladas
  let cardPowerDelta = 0;
  let cardAirDelta = 0;
  for (const inst of state.installed) {
    const card = deck.find((c) => c.id === inst.id);
    if (!card) continue;
    cardPowerDelta += card.benefit?.perSol?.power ?? 0;
    cardAirDelta += card.benefit?.perSol?.air ?? 0;

    const age = sol - inst.installedSol;
    const def = card.deferredCost;
    if (def && age >= (def.afterSols ?? 1)) {
      if (!def.marsOnly || state.siteId === "mars") {
        cardPowerDelta += def.effect?.perSol?.power ?? 0;
        cardAirDelta += def.effect?.perSol?.air ?? 0;
      }
    }
  }

  // 4. Modo de energía y soporte vital
  const modeCfg = balance.powerModes[state.powerMode];
  const shelterActive = Boolean(useShelter && state.shelterUnlocked);
  const shelterPowerCost = shelterActive ? (balance.dose.shelterPowerCost ?? 15) : 0;

  const netPower =
    solarGen +
    cardPowerDelta +
    (modeCfg?.extraPower ?? 0) -
    balance.perSol.lifeSupportPower -
    state.shield * balance.perSol.shieldUpkeepPerLevel -
    shelterPowerCost;

  state.power = clamp(state.power + netPower, 0, balance.caps.power);

  let netAir = cardAirDelta - balance.perSol.crewAirUse;
  if (state.power === 0) {
    netAir -= balance.perSol.airLossIfNoPower;
    notes.push("¡Sin energía! El soporte vital pierde presión de aire.");
  }
  state.air = clamp(state.air + netAir, 0, balance.caps.air);

  if (!shelterActive) {
    state.science += modeCfg?.science ?? 1;
  } else {
    notes.push("Tripulación en el Refugio de tormenta (-15 energía, tareas científicas pausadas).");
  }

  // 5. Dosis de radiación (base RadLab + eventos solares DONKI)
  const baseDose = (balance.dose.baselinePerSolAtIss ?? 0.4) * (state.profile.doseMultiplierVsIss ?? 3);
  let eventDose = 0;
  for (const ev of ctx.activeEvents) {
    const hasWarn = ev.warningSols != null && ev.warningSols > 0;
    const shelterMult = shelterActive
      ? hasWarn
        ? balance.dose.shelterMultiplierWithWarning
        : balance.dose.shelterMultiplierNoWarning
      : 1;
    const raw =
      (ev.threat * balance.dose.eventFactor) /
      (1 + balance.dose.attenuationPerShieldLevel * state.shield);
    const d = raw * shelterMult;
    eventDose += d;
    notes.push(`Evento DONKI ${ev.type} (${ev.label}): +${d.toFixed(1)} dosis`);
    const topic = EFFECT_TO_TOPIC[ev.gameEffect?.kind] ?? "radiation";
    const f = pickFact(world, topic, rng);
    if (f && !state.factsUnlocked.some((x) => x.accession === f.accession)) {
      state.factsUnlocked.push(f);
    }
  }

  const totalSolDose = Number((baseDose + eventDose).toFixed(2));
  state.dose = clamp(Number((state.dose + totalSolDose).toFixed(2)), 0, balance.caps.dose);

  state.history.push({
    sol: sol + 1,
    power: state.power,
    air: state.air,
    shield: state.shield,
    dose: state.dose,
    science: state.science,
    solarGen,
    dustStorm,
    isLunarNight: ctx.isLunarNight,
    installedCard: installedCard?.id ?? null,
    events: ctx.activeEvents.map((e) => ({ id: e.id, type: e.type, label: e.label, threat: e.threat })),
    notes,
  });

  state.sol += 1;

  // 6. Condiciones de fin de partida
  if (state.air <= 0) {
    state.ended = true;
    state.outcome = "air_depleted";
    state.stars = 0;
  } else if (state.dose >= balance.caps.dose) {
    state.ended = true;
    state.outcome = "radiation_limit";
    state.stars = 0;
  } else if (state.sol >= state.totalSols) {
    state.ended = true;
    state.outcome = "victory";
    let stars = 1;
    for (const threshold of balance.scoring.starsByDoseUnder) {
      if (state.dose < threshold) stars++;
    }
    if (state.science >= balance.scoring.scienceForExtraStar) {
      stars = Math.min(4, stars + 1);
    }
    state.stars = stars;
  } else {
    state.offeredCards = drawCards(state, deck, rng, balance.run.cardsOffered ?? 3);
  }

  return state;
}
