/**
 * Page composition: the caption band, the app-screen viewport under it, the
 * feature graphic, and the stylesheet that both share.
 *
 * The app screen is authored at real app dp sizes and scaled up with a single
 * transform, so one set of numbers serves the phone (1080 px) and both tablet
 * widths without re-tuning any layout.
 */
import { T } from "./theme.mjs";
import { dataUri, IMG } from "./assets.mjs";
import { isRTL, BRAND, feature } from "./copy.mjs";

const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

/** Gold hexagon watermark for the caption band and the feature graphic. */
const HEX = (color, opacity) =>
  "data:image/svg+xml;base64," +
  Buffer.from(
    `<svg xmlns="http://www.w3.org/2000/svg" width="120" height="104" viewBox="0 0 120 104">
       <path d="M30 2h60l30 50-30 50H30L0 52Z" fill="none" stroke="${color}"
             stroke-opacity="${opacity}" stroke-width="2"/></svg>`,
  ).toString("base64");

export const appCss = (locale) => {
  const rtl = isRTL(locale);
  const uiFont = rtl ? "var(--font-arabic)" : "var(--font-latin)";
  const displayFont = rtl ? "var(--font-arabic)" : "var(--font-display)";
  return `
  :root { --ui: ${uiFont}; --display: ${displayFont};
          --gold:${T.gold}; --dark:${T.darkGreen}; --cream:${T.cream};
          --fg:${T.foreground}; --muted:${T.muted}; --border:${T.border}; --surface:${T.surface}; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: var(--ui); -webkit-font-smoothing: antialiased; }

  /* ---------- app screen ---------- */
  .screen { width:100%; height:100%; display:flex; flex-direction:column;
            background:#fff; overflow:hidden; color:var(--fg); }
  .scroll { flex:1; padding:16px; display:flex; flex-direction:column; gap:12px; overflow:hidden; }
  .scroll.flush { padding:0; gap:0; }

  .titlebar { height:62px; background:var(--dark); display:flex; align-items:center;
              justify-content:space-between; padding:0 18px; flex:none; }
  .tb-side { display:flex; align-items:center; gap:8px; }
  .tb-end { gap:14px; }
  .tb-search { color:var(--gold); font-size:13px; font-weight:600; }
  .tb-logo { width:46px; height:46px; object-fit:contain; }
  .tb-badge-wrap { position:relative; display:flex; }
  .tb-badge { position:absolute; top:-4px; inset-inline-end:-5px; min-width:13px; height:13px;
              border-radius:999px; background:var(--gold); color:var(--dark); font-size:8px;
              font-weight:800; font-style:normal; display:grid; place-items:center; padding:0 3px; }

  .stack-header { height:56px; display:flex; align-items:center; gap:10px; padding:0 16px;
                  border-bottom:1px solid var(--border); flex:none; background:#fff; }
  .stack-title { font-size:16px; font-weight:700; }
  .stack-sub { font-size:10.5px; color:var(--muted); margin-top:1px; }
  .invest-header .top-nav { display:flex; align-items:center; gap:14px; }
  .back { display:flex; }

  .tabbar { height:58px; flex:none; background:#fff; border-top:1px solid var(--border);
            display:flex; align-items:center; padding-bottom:4px; }
  .tab { flex:1; display:flex; flex-direction:column; align-items:center; gap:3px;
         font-size:9px; font-weight:600; }
  .tab span { color:#8A8A8E; }
  .invest-nav .tab { font-size:8px; }
  .invest-nav .tab span { color:#6B6B70; max-width:64px; text-align:center; line-height:1.2; }

  .card { background:var(--surface); border:1px solid var(--border); border-radius:16px;
          padding:14px; display:flex; flex-direction:column; gap:9px; flex:none; }
  .card-title { font-size:13px; font-weight:700; }
  .section-title { font-size:13px; font-weight:700; margin-top:2px; }
  .footnote { font-size:9.5px; color:var(--muted); line-height:1.55; }
  .hint { font-size:10px; color:var(--muted); line-height:1.5; }

  .ticker-head { display:flex; align-items:center; justify-content:space-between;
                 font-size:10.5px; color:var(--muted); }
  .metals { display:flex; gap:7px; }
  .metal { flex:1; border:1px solid; border-radius:12px; padding:8px 7px; }
  .metal-top { display:flex; align-items:center; gap:3px; font-size:9px; font-weight:700; }
  .metal-top .emoji { font-size:10px; }
  .metal-val { font-size:14px; font-weight:800; margin-top:3px; }
  .metal-unit { font-size:8px; opacity:.72; }

  .nisab { background:#FFFBEB; border:1px solid #FDE68A; border-radius:12px; padding:10px 12px;
           display:flex; align-items:center; gap:8px; flex:none; }
  .nisab span { flex:1; font-size:11px; font-weight:600; color:#92400E; }

  .summary { background:var(--dark); border-radius:20px; padding:18px; color:#fff; flex:none; }
  .summary-label { font-size:11.5px; color:rgba(255,255,255,.7); }
  .summary-value { font-size:31px; font-weight:800; color:var(--gold); margin:2px 0 14px;
                   letter-spacing:-.5px; }
  .summary-row { display:flex; justify-content:space-between; align-items:flex-start; }
  .summary-sub { font-size:10.5px; color:rgba(255,255,255,.6); margin-bottom:3px; }
  .gain { display:flex; align-items:center; gap:4px; color:${T.gainGreen};
          font-size:15px; font-weight:800; }
  .gain-pct { color:${T.gainGreen}; font-size:10.5px; font-weight:600; margin-top:1px; }
  .summary-count { font-size:18px; font-weight:800; }

  .trips-entry { display:flex; align-items:center; gap:10px; background:#fff; flex:none;
                 border:1px solid var(--border); border-radius:14px; padding:11px 12px; }
  .trips-icon { width:32px; height:32px; border-radius:10px; background:#FDECEE;
                display:grid; place-items:center; }
  .trips-title { font-size:12.5px; font-weight:700; }
  .trips-sub { font-size:10px; color:var(--muted); margin-top:1px; }

  .alloc { display:flex; align-items:center; gap:16px; }
  .donut { width:92px; height:92px; border-radius:50%; position:relative; flex:none; }
  .donut-hole { position:absolute; inset:15px; background:var(--surface); border-radius:50%;
                display:grid; place-items:center; align-content:center; }
  .donut-pct { font-size:15px; font-weight:800; }
  .donut-cap { font-size:9px; color:var(--muted); }
  .legend { flex:1; display:flex; flex-direction:column; gap:7px; }
  .legend-row { display:flex; align-items:center; gap:8px; font-size:11px; }
  .legend-row i { width:10px; height:10px; border-radius:3px; flex:none; }
  .legend-name { color:#4A4A4A; }
  .legend-pct { margin-inline-start:auto; font-weight:700; }

  .asset-list { display:flex; flex-direction:column; gap:8px; }
  .asset { display:flex; align-items:center; gap:10px; background:#fff; border:1px solid var(--border);
           border-radius:14px; padding:10px 12px; }
  .asset-bar { width:3px; height:26px; border-radius:2px; flex:none; }
  .asset-name { font-size:12px; font-weight:700; white-space:nowrap; overflow:hidden;
                text-overflow:ellipsis; }
  .asset-sub { font-size:10px; color:var(--muted); margin-top:2px; }
  .asset-value { font-size:12.5px; font-weight:800; }
  .asset-gain { font-size:10px; font-weight:700; margin-top:2px; }

  .pill { border-radius:999px; padding:2px 8px; font-weight:800; white-space:nowrap; }
  .stop { background:var(--surface); border:1px solid var(--border); border-radius:14px;
          padding:12px; display:flex; flex-direction:column; gap:9px; flex:none; }
  .stop-head { display:flex; align-items:flex-start; justify-content:space-between; gap:8px; }
  .stop-name { font-size:12.5px; font-weight:700; display:flex; align-items:center; gap:6px;
               flex-wrap:wrap; }
  .stop-foot { display:flex; align-items:flex-end; justify-content:space-between; }
  .stop-meta { font-size:9.5px; color:var(--muted); display:flex; flex-direction:column; gap:2px; }
  .stop-total { font-size:16px; font-weight:800; }
  .trip-stats { display:flex; justify-content:space-between; gap:8px; }
  .stat-cap { font-size:9.5px; color:var(--muted); margin-bottom:2px; }
  .stat-val { font-size:13.5px; font-weight:800; }
  .stat-val.muted { color:#6B7280; }
  .stat-val.up { color:#15803D; }
  .stat-grid { display:flex; justify-content:space-between; }
  .savings { display:flex; align-items:center; gap:7px; background:#fff; border:1px solid var(--border);
             border-radius:10px; padding:8px 10px; font-size:10.5px; font-weight:600; color:var(--dark); }
  .savings b { margin-inline-start:auto; font-size:12px; color:var(--fg); }
  .cta-bar { padding:10px 16px 14px; background:#fff; flex:none; }
  .cta { background:var(--dark); border-radius:16px; padding:12px; display:flex;
         align-items:center; justify-content:center; gap:8px; color:var(--gold);
         font-size:13.5px; font-weight:800; }

  .zakat-status { background:#FFFBEB; border:1px solid #FDE68A; border-radius:20px; padding:16px;
                  display:flex; flex-direction:column; align-items:center; gap:7px; flex:none; }
  .zakat-status-text { font-size:12px; font-weight:700; color:#92400E; text-align:center; }
  .zakat-due { background:var(--dark); border-radius:20px; padding:18px; text-align:center; flex:none; }
  .zakat-due-label { font-size:11.5px; color:rgba(255,255,255,.7); }
  .zakat-due-value { font-size:29px; font-weight:800; color:var(--gold); margin:4px 0 3px;
                     letter-spacing:-.5px; }
  .zakat-due-note { font-size:10.5px; color:rgba(255,255,255,.65); }
  .kv { display:flex; align-items:center; justify-content:space-between; gap:10px;
        font-size:11.5px; color:#4A4A4A; padding:4px 0; }
  .kv b { font-weight:700; color:var(--fg); white-space:nowrap; }
  .kv.small { font-size:10.5px; padding:2px 0; }

  .eyebrow { font-size:9.5px; font-weight:700; color:var(--muted); text-transform:uppercase;
             letter-spacing:.5px; }
  .rule { height:1px; background:var(--border); margin:3px 0; }
  .kv .strong { color:var(--fg); font-weight:600; }
  .input { background:#fff; border:1px solid var(--border); border-radius:10px;
           padding:10px 12px; font-size:15px; font-weight:700; }
  .field-label { font-size:10px; color:var(--muted); }
  .pills { display:flex; gap:6px; flex-wrap:wrap; }
  .opt { border:1px solid var(--border); background:#fff; border-radius:999px; padding:5px 11px;
         font-size:10.5px; font-weight:600; color:#585858; }
  .opt.on { background:var(--dark); border-color:var(--dark); color:var(--gold); }
  .calc-out { background:#FFF9E6; border:1px solid #F5D766; border-radius:12px; padding:12px;
              text-align:center; }
  .calc-out-cap { font-size:10px; color:#92710B; }
  .calc-out-val { font-size:21px; font-weight:800; color:#5A460A; margin-top:2px; }
  .conv-out { background:var(--dark); border-radius:12px; padding:12px; text-align:center; }
  .conv-out-cap { font-size:10px; color:rgba(255,255,255,.7); }
  .conv-out-val { font-size:17px; font-weight:800; color:var(--gold); margin-top:2px; }

  .hero { height:172px; background-size:cover; background-position:center; display:flex;
          flex-direction:column; justify-content:center; gap:8px; padding:0 20px; flex:none; }
  .hero-title { font-family:var(--display); font-size:29px; font-weight:700; color:#fff;
                line-height:1.12; max-width:250px; }
  .hero-sub { font-size:11px; color:rgba(255,255,255,.92); max-width:250px; line-height:1.45; }
  .chips { display:flex; gap:7px; padding:12px 16px 10px; }
  .chip { border:1px solid var(--border); background:#fff; border-radius:999px; padding:6px 12px;
          font-size:10.5px; font-weight:600; color:#585858; white-space:nowrap; }
  .chip.on { background:var(--gold); border-color:var(--gold); color:var(--dark); }
  .grid { display:grid; grid-template-columns:1fr 1fr; gap:10px; padding:0 16px 14px; }
  .product { border:1px solid var(--border); border-radius:14px; overflow:hidden; background:#fff; }
  .product-img { height:112px; background-size:cover; background-position:center; position:relative; }
  .wish { position:absolute; top:8px; inset-inline-end:8px; width:22px; height:22px; border-radius:50%;
          background:rgba(255,255,255,.94); display:grid; place-items:center; }
  .product-name { font-size:10.5px; font-weight:600; padding:8px 10px 0; line-height:1.35; }
  .product-foot { display:flex; align-items:center; justify-content:space-between; padding:5px 10px 10px; }
  .product-price { font-size:12px; font-weight:800; color:var(--dark); }
  .product-add { width:24px; height:24px; border-radius:8px; background:#FFF3D0;
                 display:grid; place-items:center; }

  .detail-hero { background:var(--dark); border-radius:20px; padding:18px; flex:none; }
  .detail-cap { font-size:11.5px; color:rgba(255,255,255,.7); }
  .detail-value { font-size:29px; font-weight:800; color:var(--gold); margin:3px 0 9px;
                  letter-spacing:-.5px; }
  .detail-gain { display:flex; align-items:center; gap:6px; color:${T.gainGreen};
                 font-size:12.5px; font-weight:700; }

  .specialist { display:flex; align-items:center; gap:12px; }
  .avatar { width:44px; height:44px; border-radius:50%; background:#FFF3D0; display:grid;
            place-items:center; flex:none; }
  .spec-name { font-size:12.5px; font-weight:700; }
  .spec-fee { font-size:11px; font-weight:700; color:#92710B; margin-top:2px; }
  .expect { display:flex; align-items:flex-start; gap:8px; font-size:11.5px; line-height:1.5; }
  .expect svg { flex:none; margin-top:2px; }
  .slots { display:grid; grid-template-columns:1fr 1fr; gap:8px; }
  .slot { border:1px solid var(--border); border-radius:12px; padding:9px; text-align:center;
          background:#fff; }
  .slot.on { background:var(--dark); border-color:var(--dark); }
  .slot-day { font-size:10px; color:var(--muted); }
  .slot.on .slot-day { color:rgba(255,255,255,.7); }
  .slot-time { font-size:12px; font-weight:800; margin-top:2px; }
  .slot.on .slot-time { color:var(--gold); }
  .submit { background:var(--dark); border-radius:14px; padding:13px; text-align:center;
            color:var(--gold); font-weight:800; font-size:13.5px; flex:none; }
  `;
};

/** Caption band + scaled app screen. */
export const captionedPage = ({
  locale, width, height, capHeight, uiWidth, title, sub, screenHtml, fontCssHref,
}) => {
  const deviceH = height - capHeight;
  const scale = width / uiWidth;
  const uiHeight = Math.round(deviceH / scale);
  const pad = Math.round(width * 0.067);

  return `<!doctype html>
<html lang="${locale === "ar" ? "ar" : "en"}" dir="${isRTL(locale) ? "rtl" : "ltr"}">
<head><meta charset="utf-8"><link rel="stylesheet" href="${fontCssHref}">
<style>
${appCss(locale)}
html, body { width:${width}px; height:${height}px; overflow:hidden; background:${T.darkGreen}; }
.caption { height:${capHeight}px; padding:0 ${pad}px; display:flex; flex-direction:column;
           justify-content:center; gap:${Math.round(width * 0.017)}px; position:relative;
           background:
             radial-gradient(120% 90% at ${isRTL(locale) ? "82%" : "18%"} -10%, rgba(212,175,55,.20), transparent 60%),
             linear-gradient(155deg, #0B4A3B 0%, ${T.darkGreen} 58%, #04241D 100%);
           overflow:hidden; }
.caption::after { content:""; position:absolute; inset-inline-end:-40px; top:-30px;
                  width:${Math.round(width * 0.42)}px; height:${capHeight + 60}px;
                  background-image:url('${HEX(T.gold, 0.5)}'); background-size:120px 104px;
                  opacity:.35; transform:rotate(-6deg); }
.cap-brand { display:flex; align-items:center; gap:${Math.round(width * 0.014)}px; position:relative; z-index:1; }
.cap-brand img { width:${Math.round(width * 0.05)}px; height:${Math.round(width * 0.05)}px; object-fit:contain; }
.cap-brand span { color:${T.gold}; font-size:${Math.round(width * 0.023)}px; font-weight:700;
                  letter-spacing:${isRTL(locale) ? 0 : ".14em"}; text-transform:${isRTL(locale) ? "none" : "uppercase"}; }
.cap-title { color:${T.cream}; font-size:${Math.round(width * 0.052)}px; font-weight:800;
             line-height:1.18; letter-spacing:-.4px; position:relative; z-index:1;
             max-width:${Math.round(width * 0.86)}px; }
.cap-sub { color:rgba(212,175,55,.95); font-size:${Math.round(width * 0.026)}px; font-weight:500;
           line-height:1.4; position:relative; z-index:1; max-width:${Math.round(width * 0.84)}px; }
.cap-rule { width:${Math.round(width * 0.09)}px; height:3px; border-radius:2px; background:${T.gold};
            position:relative; z-index:1; }
.device { height:${deviceH}px; overflow:hidden; border-radius:${Math.round(width * 0.042)}px
          ${Math.round(width * 0.042)}px 0 0; background:#fff; position:relative;
          box-shadow:0 -14px 44px rgba(0,0,0,.42); }
.ui { width:${uiWidth}px; height:${uiHeight}px; transform:scale(${scale});
      transform-origin:top ${isRTL(locale) ? "right" : "left"}; }
</style></head>
<body>
  <div class="caption">
    <div class="cap-brand"><img src="${dataUri(IMG.logoMark)}" alt="">
      <span>${esc(locale === "ar" ? BRAND.ar : BRAND.en)}</span></div>
    <div class="cap-title">${esc(title)}</div>
    <div class="cap-rule"></div>
    <div class="cap-sub">${esc(sub)}</div>
  </div>
  <div class="device"><div class="ui">${screenHtml}</div></div>
</body></html>`;
};

/** Feature graphic, 1024×500. */
export const featurePage = ({ locale, fontCssHref }) => {
  const f = feature[locale];
  const rtl = isRTL(locale);
  return `<!doctype html>
<html lang="${rtl ? "ar" : "en"}" dir="${rtl ? "rtl" : "ltr"}">
<head><meta charset="utf-8"><link rel="stylesheet" href="${fontCssHref}">
<style>
${appCss(locale)}
html, body { width:1024px; height:500px; overflow:hidden; }
.fg { width:1024px; height:500px; position:relative; overflow:hidden; display:flex;
      align-items:center;
      background:
        radial-gradient(90% 120% at ${rtl ? "88%" : "12%"} 0%, rgba(212,175,55,.22), transparent 55%),
        linear-gradient(140deg, #0C5040 0%, ${T.darkGreen} 55%, #04231C 100%); }
.photo { position:absolute; inset-block:0; inset-inline-end:0; width:470px;
         background-image:url('${dataUri(IMG.hero)}');
         background-size:cover; background-position:50% 42%;
         -webkit-mask-image:linear-gradient(to ${rtl ? "right" : "left"},
             rgba(0,0,0,1) 55%, rgba(0,0,0,0) 100%); }
.photo::after { content:""; position:absolute; inset:0;
                background:linear-gradient(to ${rtl ? "right" : "left"},
                  rgba(4,35,28,.10), rgba(4,35,28,.86)); }
.hexes { position:absolute; inset-block:0; inset-inline-start:-50px; width:280px;
         background-image:url('${HEX(T.gold, 0.55)}'); background-size:120px 104px;
         opacity:.30; transform:rotate(-8deg); }
.fg-inner { position:relative; z-index:2; padding-inline-start:64px; max-width:600px;
            display:flex; flex-direction:column; gap:16px; }
.fg-brand { display:flex; align-items:center; gap:16px; }
.fg-brand img { width:76px; height:76px; object-fit:contain; }
.fg-name { color:${T.cream}; font-size:46px; font-weight:800; line-height:1.05; letter-spacing:-.5px; }
.fg-name small { display:block; color:#EBCF6E; font-size:19px; font-weight:700;
                 font-family:${rtl ? "var(--font-latin)" : "var(--font-arabic)"};
                 letter-spacing:${rtl ? 0 : ".22em"}; text-transform:${rtl ? "none" : "uppercase"};
                 margin-top:6px; }
.fg-tag { color:${T.gold}; font-size:29px; font-weight:700; line-height:1.25; }
.fg-sub { color:rgba(255,249,237,.86); font-size:18px; font-weight:500; line-height:1.4; }
.fg-rule { width:96px; height:3px; border-radius:2px; background:${T.gold}; }
</style></head>
<body><div class="fg">
  <div class="hexes"></div><div class="photo"></div>
  <div class="fg-inner">
    <div class="fg-brand"><img src="${dataUri(IMG.logoMark)}" alt="">
      <div class="fg-name">${esc(rtl ? BRAND.ar : BRAND.en)}
        <small>${esc(rtl ? BRAND.en : BRAND.ar)}</small></div></div>
    <div class="fg-rule"></div>
    <div class="fg-tag">${esc(f.tagline)}</div>
    <div class="fg-sub">${esc(f.sub)}</div>
  </div>
</div></body></html>`;
};
