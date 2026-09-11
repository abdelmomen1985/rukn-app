/**
 * Inline SVG icon set.
 *
 * The old Pillow generator drew tab icons as empty rounded rectangles and pulled
 * arrows from the font, which rendered as tofu. Every glyph here is a path, so
 * nothing depends on an installed symbol font. Names mirror the SF Symbol names
 * the app passes to `components/ui/icon-symbol.tsx`.
 */

const svg = (body, { size = 24, color = "currentColor", fill = "none", stroke = 1.8 } = {}) =>
  `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="${fill}" stroke="${color}" ` +
  `stroke-width="${stroke}" stroke-linecap="round" stroke-linejoin="round">${body}</svg>`;

const PATHS = {
  "magnifyingglass": '<circle cx="10.5" cy="10.5" r="6.75"/><path d="M15.6 15.6 21 21"/>',
  "heart":
    '<path d="M12 20.3s-8.4-5.2-8.4-11A4.6 4.6 0 0 1 12 6.3a4.6 4.6 0 0 1 8.4 3c0 5.8-8.4 11-8.4 11Z"/>',
  "cart":
    '<path d="M2.5 3.5h2.2l2.4 11.2h10.5l2-8.2H6"/><circle cx="9.5" cy="19.3" r="1.6"/><circle cx="17.4" cy="19.3" r="1.6"/>',
  "house.fill": '<path d="M3 10.6 12 3l9 7.6V20a1 1 0 0 1-1 1h-5v-6.2h-6V21H4a1 1 0 0 1-1-1Z"/>',
  "person":
    '<circle cx="12" cy="7.8" r="3.9"/><path d="M4.4 20.4a7.6 7.6 0 0 1 15.2 0"/>',
  "chart.line.uptrend.xyaxis":
    '<path d="M3.2 20.2V3.6M3.2 20.4h17.2"/><path d="M6.4 16.2 10.6 12l3.2 3 5.6-6.4"/><path d="M15.8 8.4h3.8v3.8"/>',
  "arrow.clockwise":
    '<path d="M20.2 12a8.2 8.2 0 1 1-2.6-6"/><path d="M20.4 4.2v4.6h-4.6"/>',
  "arrow.up.right": '<path d="M6.6 17.4 17.4 6.6"/><path d="M9.4 6.6h8v8"/>',
  "arrow.down.right": '<path d="M6.6 6.6 17.4 17.4"/><path d="M17.4 9.4v8h-8"/>',
  "arrow.left.arrow.right":
    '<path d="M7.6 5.4 3.8 9.2l3.8 3.8"/><path d="M3.8 9.2h16.4"/><path d="M16.4 18.6l3.8-3.8-3.8-3.8"/><path d="M20.2 14.8H3.8"/>',
  "scale":
    '<path d="M12 3.6v16.8M6.2 20.4h11.6"/><path d="M4.6 6.6h14.8"/><path d="M4.6 6.6 1.8 13h5.6Z"/><path d="M19.4 6.6 16.6 13h5.6Z"/>',
  "person.fill.questionmark":
    '<circle cx="9.4" cy="7.4" r="3.6"/><path d="M2.6 20.2a6.8 6.8 0 0 1 13.6 0"/>' +
    '<path d="M18.2 8.4a2 2 0 1 1 2.6 1.9c-.7.3-1 .8-1 1.6"/><path d="M19.8 14.8h.01"/>',
  "bag":
    '<path d="M5.4 7.6h13.2l1 12.8H4.4Z"/><path d="M8.8 10V6.6a3.2 3.2 0 0 1 6.4 0V10"/>',
  "plus.circle.fill": '<circle cx="12" cy="12" r="8.8"/><path d="M12 8.2v7.6M8.2 12h7.6"/>',
  "chevron.left": '<path d="M14.6 5.4 8 12l6.6 6.6"/>',
  "chevron.right": '<path d="M9.4 5.4 16 12l-6.6 6.6"/>',
  "checkmark": '<path d="M4.6 12.6 9.4 17.4 19.4 6.6"/>',
  "sparkles":
    '<path d="M12 3.4 13.7 9l5.6 1.7-5.6 1.7L12 18l-1.7-5.6L4.7 10.7 10.3 9Z"/>' +
    '<path d="M18.6 15.6l.8 2.4 2.4.8-2.4.8-.8 2.4-.8-2.4-2.4-.8 2.4-.8Z"/>',
  "calendar":
    '<rect x="3.4" y="5.2" width="17.2" height="15.4" rx="2.4"/><path d="M3.4 10h17.2M8 3.4v3.6M16 3.4v3.6"/>',
  "info": '<circle cx="12" cy="12" r="8.8"/><path d="M12 11.2v5M12 7.9h.01"/>',
};

// Solid marks: a filled shape reads better than a stroke at tab-bar size.
const FILLED = {
  "triangle.up": (color) =>
    `<svg width="1em" height="1em" viewBox="0 0 24 24"><path d="M12 5.5 21 19H3Z" fill="${color}"/></svg>`,
  "triangle.down": (color) =>
    `<svg width="1em" height="1em" viewBox="0 0 24 24"><path d="M12 18.5 3 5h18Z" fill="${color}"/></svg>`,
  "dot": (color) =>
    `<svg width="1em" height="1em" viewBox="0 0 24 24"><circle cx="12" cy="12" r="5" fill="${color}"/></svg>`,
};

export function icon(name, opts = {}) {
  if (FILLED[name]) return FILLED[name](opts.color ?? "currentColor");
  const body = PATHS[name];
  if (!body) throw new Error(`icon(): unknown symbol "${name}"`);
  return svg(body, opts);
}

export const iconNames = [...Object.keys(PATHS), ...Object.keys(FILLED)];
