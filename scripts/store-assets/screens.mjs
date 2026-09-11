/**
 * The eight app screens, rebuilt in HTML so the browser does the layout, the
 * bidi and the shaping. Geometry, colours and wording follow the real
 * components — `components/title-bar.tsx`, `components/portfolio/*`,
 * `components/invest-bottom-nav.tsx`, `app/(tabs)/_layout.tsx`,
 * `app/invest/{zakat,converter,consultation}.tsx` and `app/invest/trips/*` —
 * so what the listing shows is what the app draws.
 *
 * All sizes below are logical (dp) app units; `frames.mjs` scales the finished
 * screen up to store resolution.
 */
import { T } from "./theme.mjs";
import { icon } from "./icons.mjs";
import { dataUri, IMG } from "./assets.mjs";
import { ui, isRTL } from "./copy.mjs";
import * as D from "./data.mjs";

const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
/**
 * Isolates a token whose direction differs from the paragraph's. Without it an
 * Arabic line containing "21K" or "2.5%" gets reordered by the bidi algorithm
 * and the separators land in the wrong place.
 */
const bdi = (s) => `<bdi>${esc(s)}</bdi>`;
/**
 * A signed number or percentage. Forcing LTR inside the isolate keeps the sign
 * on the left of the digits in both languages, which is how React Native lays
 * these out in the app.
 */
const signed = (s) => `<bdi dir="ltr">${esc(s)}</bdi>`;
/** Karat as the app labels it: "21K" in both languages, but bidi-isolated. */
const karatLabel = (l, k) => bdi(`${D.nf(l, k)}K`);
/**
 * Joins parts with " · " inside a single isolate. A mixed run split across
 * several isolates lets the bidi algorithm reorder the separators — this keeps
 * the whole phrase in one direction context.
 */
const phrase = (parts) => `<bdi>${parts.map(esc).join(" · ")}</bdi>`;
/** "03 / 2024" — the month a holding was bought, in the page's numerals. */
const monthYear = (l, iso) => {
  const d = new Date(iso);
  const mm = D.nf(l, d.getUTCMonth() + 1).padStart(l === "ar" ? 1 : 2, "0");
  return `${mm} / ${D.nf(l, d.getUTCFullYear()).replace(/[,٬]/g, "")}`;
};

// --------------------------------------------------------------------------
// Primitives
// --------------------------------------------------------------------------

const card = (inner, style = "") =>
  `<div class="card" style="${style}">${inner}</div>`;

const pill = (text, { bg, color, size = 10 }) =>
  `<span class="pill" style="background:${bg};color:${color};font-size:${size}px">${esc(text)}</span>`;

const money = (l, n, digits = 0) => esc(D.sar(l, n, digits));
const num = (l, n, digits = 0) => esc(D.nf(l, n, digits));

/** Top app bar from `components/title-bar.tsx` (dark green, logo centred). */
const titleBar = (l) => `
  <header class="titlebar">
    <div class="tb-side">
      ${icon("magnifyingglass", { size: 20, color: T.gold })}
      <span class="tb-search">${esc(ui[l].search)}</span>
    </div>
    <img class="tb-logo" src="${dataUri(IMG.appLogo)}" alt="">
    <div class="tb-side tb-end">
      <span class="tb-badge-wrap">${icon("heart", { size: 21, color: T.gold })}<i class="tb-badge">2</i></span>
      <span class="tb-badge-wrap">${icon("cart", { size: 21, color: T.gold })}<i class="tb-badge">1</i></span>
    </div>
  </header>`;

/** Plain screen header used by every `app/invest/*` route. */
const stackHeader = (l, title, subtitle) => `
  <header class="stack-header">
    <span class="back">${icon("chevron.left", { size: 20, color: T.foreground })}</span>
    <div>
      <div class="stack-title">${esc(title)}</div>
      ${subtitle ? `<div class="stack-sub">${esc(subtitle)}</div>` : ""}
    </div>
  </header>`;

/** Invest tab header: title + the quick-jump icons of `invest-top-nav.tsx`. */
const investHeader = (l) => `
  <header class="stack-header invest-header">
    <div class="stack-title" style="flex:1">${esc(ui[l].investTitle)}</div>
    <div class="top-nav">
      ${icon("arrow.left.arrow.right", { size: 18, color: T.gold })}
      ${icon("scale", { size: 18, color: "#D97706" })}
      ${icon("plus.circle.fill", { size: 18, color: T.darkGreen })}
    </div>
  </header>`;

/** Bottom tab bar — order and labels from `app/(tabs)/_layout.tsx`. */
const TABS = [
  { key: "tabHome", sym: "house.fill" },
  { key: "tabWishlist", sym: "heart" },
  { key: "tabCart", sym: "cart" },
  { key: "tabProfile", sym: "person" },
  { key: "tabInvest", sym: "chart.line.uptrend.xyaxis" },
];

const tabBar = (l, active) => `
  <nav class="tabbar">
    ${TABS.map((t, i) => {
      const c = i === active ? T.gold : "#8A8A8E";
      return `<div class="tab"${i === active ? ' data-active="1"' : ""}>
        ${icon(t.sym, { size: 22, color: c })}
        <span style="color:${c}">${esc(ui[l][t.key])}</span>
      </div>`;
    }).join("")}
  </nav>`;

/** Invest tool bar — items and colours from `components/invest-bottom-nav.tsx`. */
const INVEST_NAV = [
  { key: "converter", sym: "arrow.left.arrow.right", color: "#D4AF37" },
  { key: "zakat", sym: "scale", color: "#D97706" },
  { key: "consultationTitle", sym: "person.fill.questionmark", color: "#059669" },
  { key: "tripsCardLabel", sym: "bag", color: "#A4313F" },
  { key: "addAsset", sym: "plus.circle.fill", color: "#07352b" },
];

const investNav = (l) => `
  <nav class="tabbar invest-nav">
    ${INVEST_NAV.map(
      (n) => `<div class="tab">
        ${icon(n.sym, { size: 21, color: n.color })}
        <span>${esc(ui[l][n.key])}</span>
      </div>`,
    ).join("")}
  </nav>`;

const screen = (header, body, footer, flush = false) =>
  `<div class="screen">${header}<div class="scroll${flush ? " flush" : ""}">${body}</div>${footer}</div>`;

// --------------------------------------------------------------------------
// Shared blocks
// --------------------------------------------------------------------------

/** `components/portfolio/spot-price-ticker.tsx` */
const spotTicker = (l) => {
  const chips = ["XAU", "XAG", "XPT", "XPD"]
    .map((sym) => {
      const m = D.metals[sym];
      const perGram = sym === "XAU" ? D.spot.XAU : D.spot[sym];
      return `<div class="metal" style="background:${m.bg};border-color:${m.border};color:${m.text}">
        <div class="metal-top"><span class="emoji">${m.emoji}</span><span>${esc(ui[l][m.key])}</span></div>
        <div class="metal-val">${num(l, perGram, 2)}</div>
        <div class="metal-unit">${esc(ui[l].sar)}${esc(ui[l].perGram)}</div>
      </div>`;
    })
    .join("");
  return card(
    `<div class="ticker-head">
       <span>${esc(ui[l].lastUpdated)}: ${l === "ar" ? "٢م" : "2m"}</span>
       ${icon("arrow.clockwise", { size: 14, color: T.gold })}
     </div>
     <div class="metals">${chips}</div>`,
    "padding:16px",
  );
};

/** `components/portfolio/nisab-alert-banner.tsx` */
const nisabBanner = (l) => `
  <div class="nisab">
    ${icon("scale", { size: 16, color: "#B45309" })}
    <span>${esc(ui[l].nisabAlert)}</span>
    ${icon(isRTL(l) ? "chevron.left" : "chevron.right", { size: 14, color: "#B45309" })}
  </div>`;

/** `components/portfolio/portfolio-summary-card.tsx` */
const summaryCard = (l) => {
  const p = D.portfolio;
  return `<div class="summary">
    <div class="summary-label">${esc(ui[l].totalValue)}</div>
    <div class="summary-value">${money(l, p.totalValue)}</div>
    <div class="summary-row">
      <div>
        <div class="summary-sub">${esc(ui[l].gainLoss)}</div>
        <div class="gain">${icon("arrow.up.right", { size: 13, color: T.gainGreen })}
          <span>${signed(`+${D.nf(l, p.gainLoss)}`)}</span></div>
        <div class="gain-pct">${signed(`+${D.nf(l, p.gainLossPercent, 1)}%`)}</div>
      </div>
      <div style="text-align:${isRTL(l) ? "left" : "right"}">
        <div class="summary-sub">${esc(ui[l].assets)}</div>
        <div class="summary-count">${num(l, p.assetCount)}</div>
      </div>
    </div>
  </div>`;
};

/** `components/portfolio/pie-chart.tsx` — allocation by metal. */
const allocationCard = (l) => {
  const total = D.portfolio.totalValue;
  const segs = D.portfolio.byMetal.map((m) => ({
    ...m, pct: (m.value / total) * 100, style: D.metals[m.metal],
  }));
  let a = 0;
  const stops = segs.map((s) => {
    const from = a; a += s.pct;
    return `${s.style.border} ${from.toFixed(2)}% ${a.toFixed(2)}%`;
  });
  return card(
    `<div class="card-title">${esc(ui[l].allocation)}</div>
     <div class="alloc">
       <div class="donut" style="background:conic-gradient(${stops.join(",")})">
         <div class="donut-hole">
           <div class="donut-pct">${signed(`${D.nf(l, segs[0].pct, 0)}%`)}</div>
           <div class="donut-cap">${esc(ui[l].gold)}</div>
         </div>
       </div>
       <div class="legend">${segs
         .map(
           (s) => `<div class="legend-row">
             <i style="background:${s.style.border}"></i>
             <span class="legend-name">${esc(ui[l][s.style.key])}</span>
             <span class="legend-pct">${signed(`${D.nf(l, s.pct, 1)}%`)}</span>
           </div>`,
         )
         .join("")}</div>
     </div>`,
  );
};

// --------------------------------------------------------------------------
// 01 — Invest tab, top: live spot prices
// --------------------------------------------------------------------------
const livePrices = (l) =>
  screen(
    investHeader(l),
    `${spotTicker(l)}${nisabBanner(l)}${summaryCard(l)}
     <div class="trips-entry">
       <div class="trips-icon">${icon("bag", { size: 18, color: "#A4313F" })}</div>
       <div style="flex:1">
         <div class="trips-title">${esc(ui[l].tripsCardLabel)}</div>
         <div class="trips-sub">${esc(ui[l].tripsSubtitle)}</div>
       </div>
       ${icon(isRTL(l) ? "chevron.left" : "chevron.right", { size: 16, color: T.muted })}
     </div>
     ${allocationCard(l)}
     <div class="section-title">${esc(ui[l].assets)}</div>
     <div class="asset-list">${assetRows(l, 3)}</div>`,
    tabBar(l, 4),
  );

// --------------------------------------------------------------------------
// 02 — Invest tab, scrolled: allocation + holdings
// --------------------------------------------------------------------------
/** Holding rows from `components/portfolio/asset-card.tsx`. */
const assetRows = (l, limit) =>
  D.assets
    .slice(0, limit)
    .map((a) => {
      const up = a.gain >= 0;
      return `<div class="asset">
        <div class="asset-bar" style="background:${D.metals[a.metal].border}"></div>
        <div style="flex:1;min-width:0">
          <div class="asset-name">${esc(D.assetNames[l][a.key])}</div>
          <div class="asset-sub">${num(l, a.grams, a.grams % 1 ? 1 : 0)} ${esc(ui[l].grams)}</div>
        </div>
        <div style="text-align:${isRTL(l) ? "left" : "right"}">
          <div class="asset-value">${money(l, a.currentValue)}</div>
          <div class="asset-gain" style="color:${up ? T.success : T.error}">
            ${signed(`${up ? "+" : "−"}${D.nf(l, Math.abs(a.gainPercent), 1)}%`)}
          </div>
        </div>
      </div>`;
    })
    .join("");

const portfolioScreen = (l) =>
  screen(
    investHeader(l),
    `${summaryCard(l)}${allocationCard(l)}
     <div class="section-title">${esc(ui[l].assets)}</div>
     <div class="asset-list">${assetRows(l, 5)}</div>`,
    tabBar(l, 4),
  );

// --------------------------------------------------------------------------
// 03 — Shopping trip detail
// --------------------------------------------------------------------------
const tripsScreen = (l) => {
  const verdictStyle = {
    excellent: { bg: "#DCFCE7", color: "#15803D", label: ui[l].fairExcellent },
    fair: { bg: "#E0F2FE", color: "#0369A1", label: ui[l].fairFair },
    high: { bg: "#FEE2E2", color: "#B91C1C", label: ui[l].fairHigh },
  };

  const stops = D.trip.stops
    .map((s) => {
      const v = verdictStyle[s.verdict];
      const best = s === D.trip.best;
      return `<div class="stop" style="border-color:${best ? T.success : T.border}">
        <div class="stop-head">
          <div class="stop-name">${esc(s.store[l])}
            ${best ? pill(ui[l].bestStopBadge, { bg: T.success, color: "#fff" }) : ""}
          </div>
          ${pill(v.label, { bg: v.bg, color: v.color, size: 10 })}
        </div>
        <div class="stop-foot">
          <div class="stop-meta">
            <div>${phrase([`${D.nf(l, s.grams, 1)} ${ui[l].grams}`, `${D.nf(l, s.purity)}K`])}</div>
            <div><bdi>${money(l, s.perGram)} / ${esc(ui[l].grams)}</bdi></div>
          </div>
          <div class="stop-total">${money(l, s.total)}</div>
        </div>
      </div>`;
    })
    .join("");

  return screen(
    stackHeader(l, D.trip.name[l], D.trip.goal[l]),
    `${card(
      `<div class="trip-stats">
         <div><div class="stat-cap">${esc(ui[l].tripStops)}</div>
              <div class="stat-val">${num(l, D.trip.stops.length)}</div></div>
         <div><div class="stat-cap">${esc(ui[l].tripBestPrice)}</div>
              <div class="stat-val">${money(l, D.trip.best.total)}</div></div>
         <div><div class="stat-cap">${esc(ui[l].tripAverage)}</div>
              <div class="stat-val muted">${money(l, D.trip.average)}</div></div>
       </div>
       <div class="savings">${icon("sparkles", { size: 14, color: T.darkGreen })}
         <span>${esc(ui[l].tripSavings)}</span>
         <b>${money(l, D.trip.savings)}</b></div>`,
      "padding:14px",
    )}
     <div class="section-title">${esc(ui[l].tripStops)}</div>
     ${stops}`,
    `<div class="cta-bar"><div class="cta">${icon("plus.circle.fill", { size: 18, color: T.gold })}
       <span>${esc(ui[l].newTrip)}</span></div></div>`,
  );
};

// --------------------------------------------------------------------------
// 04 — Zakat
// --------------------------------------------------------------------------
const zakatScreen = (l) => {
  const z = D.zakat;
  const rows = D.assets.slice(0, 4).map(
    (a) => `<div class="kv">
      <span>${esc(D.assetNames[l][a.key])}</span>
      <b>${money(l, a.currentValue)}</b></div>`,
  ).join("");

  return screen(
    stackHeader(l, ui[l].zakat),
    `<div class="zakat-status">
       ${icon("scale", { size: 22, color: "#B45309" })}
       <div class="zakat-status-text">${esc(ui[l].nisabAlert)}</div>
     </div>
     <div class="zakat-due">
       <div class="zakat-due-label">${esc(ui[l].zakatDue)}</div>
       <div class="zakat-due-value">${money(l, z.due)}</div>
       <div class="zakat-due-note"><bdi>${bdi(D.nf(l, 2.5, 1) + "%")} ${l === "ar" ? "من" : "of"} ${money(l, z.zakatableValue)}</bdi></div>
     </div>
     ${card(
       `<div class="card-title">${esc(ui[l].nisabCalculation)}</div>
        <div class="kv"><span>${phrase([ui[l].nisabThreshold, `${D.nf(l, z.nisabGrams)} ${ui[l].grams} 24K`])}</span>
          <b>${money(l, z.nisabValue)}</b></div>
        <div class="kv"><span>${esc(ui[l].zakatableValue)}</span>
          <b>${money(l, z.zakatableValue)}</b></div>`,
     )}
     ${card(`<div class="card-title">${esc(ui[l].assets)}</div>${rows}`)}
     <div class="footnote">${esc(ui[l].zakatObligatory)}</div>`,
    investNav(l),
  );
};

// --------------------------------------------------------------------------
// 05 — Gold value calculator (app/invest/converter.tsx)
// --------------------------------------------------------------------------
const calculatorScreen = (l) => {
  const c = D.calc;
  const units = l === "ar" ? ["غرام", "تولا", "أوقية", "مثقال"] : ["grams", "tola", "ounce", "mithqal"];
  const pills = (items, activeIdx, isolate = false) =>
    `<div class="pills">${items
      .map((x, i) =>
        `<span class="opt${i === activeIdx ? " on" : ""}">${isolate ? bdi(x) : esc(x)}</span>`)
      .join("")}</div>`;

  return screen(
    stackHeader(l, ui[l].converter),
    `${card(
      `<div class="card-title">${esc(ui[l].goldValueCalculator)}</div>
       <div class="input">${num(l, c.grams)}</div>
       <div class="field-label">${esc(ui[l].unit)}</div>
       ${pills(units, 0)}
       <div class="field-label">${esc(ui[l].karat)}</div>
       ${pills([24, 22, 21, 18].map((k) => `${D.nf(l, k)}K`), 2, true)}
       <div class="calc-out">
         <div class="calc-out-cap">${phrase([`${D.nf(l, c.grams)} ${ui[l].grams}`, `${D.nf(l, c.karat)}K`])}</div>
         <div class="calc-out-val">${money(l, c.total)}</div>
       </div>
       <div class="kv small"><span>${phrase([`${ui[l].gold} ${D.nf(l, c.karat)}K`, `${D.sar(l, D.goldPerGram(c.karat), 2)} / ${ui[l].grams}`])}</span>
         <b>${money(l, c.metal)}</b></div>
       <div class="kv small"><span>${esc(ui[l].makingCharges)}</span><b>${money(l, c.making)}</b></div>
       <div class="kv small"><span>${esc(ui[l].vat)}</span><b>${money(l, c.vat)}</b></div>`,
    )}
     ${card(
       `<div class="card-title">${esc(ui[l].weightConverter)}</div>
        <div class="input">${num(l, 1)}</div>
        ${pills(units, 1)}
        <div class="conv-out">
          <div class="conv-out-cap">1 ${esc(units[1])} =</div>
          <div class="conv-out-val">${num(l, 11.664, 4)} ${esc(units[0])}</div>
        </div>`,
     )}`,
    investNav(l),
  );
};

// --------------------------------------------------------------------------
// 06 — Shop (home tab)
// --------------------------------------------------------------------------
const shopScreen = (l) => {
  const cats = ui[l].categories
    .map((c, i) => `<span class="chip${i === 0 ? " on" : ""}">${esc(c)}</span>`)
    .join("");

  const grid = D.products
    .map(
      (p) => `<div class="product">
        <div class="product-img" style="background-image:url('${dataUri(IMG.product(p.img))}')">
          <span class="wish">${icon("heart", { size: 13, color: p.wish ? T.gold : "#B9B9B9" })}</span>
        </div>
        <div class="product-name">${esc(p.name[l])}</div>
        <div class="product-foot">
          <span class="product-price">${money(l, p.price)}</span>
          <span class="product-add">${icon("cart", { size: 13, color: T.darkGreen })}</span>
        </div>
      </div>`,
    )
    .join("");

  return screen(
    titleBar(l),
    `<div class="hero" style="background-image:linear-gradient(rgba(0,0,0,.45),rgba(0,0,0,.15) 45%,rgba(0,0,0,.6)),url('${dataUri(IMG.hero)}')">
       <div class="hero-title">${esc(ui[l].heroTitle)}</div>
       <div class="hero-sub">${esc(ui[l].heroSubtitle)}</div>
     </div>
     <div class="chips">${cats}</div>
     <div class="grid">${grid}</div>`,
    tabBar(l, 0),
    true,
  );
};

// --------------------------------------------------------------------------
// 07 — Asset detail
// --------------------------------------------------------------------------
const assetDetailScreen = (l) => {
  const a = D.assets[0];
  return screen(
    stackHeader(l, D.assetNames[l][a.key]),
    `<div class="detail-hero">
       <div class="detail-cap">${esc(ui[l].currentValue)}</div>
       <div class="detail-value">${money(l, a.currentValue)}</div>
       <div class="detail-gain">${icon("arrow.up.right", { size: 14, color: T.gainGreen })}
         <span>${signed(`+${D.nf(l, a.gain)}`)} · ${signed(`+${D.nf(l, a.gainPercent, 1)}%`)}</span></div>
     </div>
     ${card(
       `<div class="kv"><span>${esc(ui[l].weight)}</span><b>${num(l, a.grams)} ${esc(ui[l].grams)} · 24K</b></div>
        <div class="kv"><span>${esc(ui[l].goldSpot24)}</span><b><bdi>${money(l, a.perGram, 2)} / ${esc(ui[l].grams)}</bdi></b></div>
        <div class="kv"><span>${esc(ui[l].purchasePriceShort)}</span><b>${money(l, a.purchasePrice)}</b></div>`,
     )}
     ${card(
       `<div class="stat-grid">
          <div><div class="stat-cap">${esc(ui[l].annualizedReturn)}</div>
               <div class="stat-val up">${signed(`+${D.nf(l, a.annualized, 1)}%`)}</div></div>
          <div><div class="stat-cap">${esc(ui[l].since)}</div>
               <div class="stat-val">${bdi(monthYear(l, a.boughtAt))}</div></div>
        </div>`,
     )}
     ${card(
       `<div class="eyebrow">${esc(ui[l].costBreakdown)}</div>
        <div class="kv"><span>${esc(ui[l].purchaseCost)}</span><b>${money(l, a.purchasePrice)}</b></div>
        <div class="kv"><span>${esc(ui[l].vat)}</span><b>${money(l, a.vat)}</b></div>
        <div class="rule"></div>
        <div class="kv"><span class="strong">${esc(ui[l].totalCost)}</span><b>${money(l, a.cost)}</b></div>
        <div class="rule"></div>
        <div class="eyebrow">${esc(ui[l].performance)}</div>
        <div class="kv"><span class="strong">${esc(ui[l].currentValue)}</span><b>${money(l, a.currentValue)}</b></div>
        <div class="kv"><span class="strong">${esc(ui[l].returnPercent)}</span>
          <b style="color:#16a34a">${signed(`+${D.nf(l, a.gainPercent, 2)}%`)}</b></div>`,
     )}`,
    investNav(l),
  );
};

// --------------------------------------------------------------------------
// 08 — Consultation request
// --------------------------------------------------------------------------
const consultationScreen = (l) => {
  const slots = D.consultation.slots
    .map(
      (s) => `<div class="slot${s.picked ? " on" : ""}">
        <div class="slot-day">${esc(s.day[l])}</div>
        <div class="slot-time">${phrase([D.nf(l, s.date), s.time])}</div>
      </div>`,
    )
    .join("");

  return screen(
    stackHeader(l, ui[l].consultationTitle),
    `${card(
      `<div class="specialist">
         <div class="avatar">${icon("person.fill.questionmark", { size: 22, color: T.darkGreen })}</div>
         <div style="flex:1">
           <div class="spec-name">${esc(ui[l].consultationSpecialistGeneric)}</div>
           <div class="spec-fee">${phrase([D.sar(l, D.consultation.feeSAR), ui[l].consultationPerSession])}</div>
         </div>
       </div>`,
      "padding:14px",
    )}
     ${card(
       `<div class="card-title">${esc(ui[l].consultationWhatToExpect)}</div>
        ${[1, 2, 3]
          .map(
            (n) => `<div class="expect">${icon("checkmark", { size: 14, color: T.gold })}
              <span>${esc(ui[l][`consultationExpect${n}`])}</span></div>`,
          )
          .join("")}`,
     )}
     ${card(
       `<div class="card-title">${esc(ui[l].consultationPreferredTimes)}</div>
        <div class="hint">${esc(ui[l].consultationPreferredTimesHint)}</div>
        <div class="slots">${slots}</div>`,
     )}
     <div class="submit">${esc(ui[l].consultationSubmit)}</div>
     <div class="footnote">${esc(ui[l].consultationFeeNote)}</div>`,
    investNav(l),
  );
};

// --------------------------------------------------------------------------

export const SCREENS = {
  "01-live-prices": livePrices,
  "02-portfolio": portfolioScreen,
  "03-trips": tripsScreen,
  "04-zakat": zakatScreen,
  "05-calculator": calculatorScreen,
  "06-shop": shopScreen,
  "07-asset-detail": assetDetailScreen,
  "08-consultation": consultationScreen,
};

export const SHOT_ORDER = Object.keys(SCREENS);
