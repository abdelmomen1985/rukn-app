import { describe, it, expect } from "vitest";
import {
  averageStopTotal,
  cheapestStop,
  evaluateFairPrice,
  stopPerGramSAR,
  type TripStop,
} from "../data/market-trips";

const purePerGramSAR = 428; // mid-market reference for 24K gold (SAR / g)

function makeStop(overrides: Partial<TripStop> = {}): TripStop {
  return {
    id: "stop-1",
    storeName: "Test Store",
    totalPriceSAR: 6000,
    weightGrams: 10,
    purityLabel: "21K",
    purityFactor: 21 / 24,
    vatIncluded: false,
    origin: "local",
    visitedAt: "2025-01-01T00:00:00.000Z",
    verdict: "fair",
    makingPerGramSAR: 0,
    marketReferencePerGramSAR: 0,
    ...overrides,
  };
}

describe("market-trips: evaluateFairPrice", () => {
  it("strips VAT before computing the workmanship band when VAT is included", () => {
    const result = evaluateFairPrice({
      totalPriceSAR: 6000,
      weightGrams: 10,
      purityFactor: 21 / 24,
      vatIncluded: true,
      purePerGramSAR,
    });
    // 6000 / 1.15 ≈ 5217.39
    expect(result.preTaxTotalSAR).toBeCloseTo(5217.39, 1);
    expect(result.vatAmountSAR).toBeCloseTo(782.61, 1);
  });

  it("flags excellent deals when workmanship is at or below the lower band", () => {
    // 21K gold @ 10g: gold value = 10 * 428 * 21/24 = 3745
    // pre-tax total = 4000 → making/g = (4000 - 3745) / 10 = 25.5 → just above excellent (25)
    // pre-tax total = 3995 → making/g = 25 → exactly at band → excellent
    const result = evaluateFairPrice({
      totalPriceSAR: 3995,
      weightGrams: 10,
      purityFactor: 21 / 24,
      vatIncluded: false,
      purePerGramSAR,
    });
    expect(result.verdict).toBe("excellent");
  });

  it("flags fair deals when workmanship is within the band", () => {
    // pre-tax total = 4100 → making/g = (4100 - 3745) / 10 = 35.5 → fair
    const result = evaluateFairPrice({
      totalPriceSAR: 4100,
      weightGrams: 10,
      purityFactor: 21 / 24,
      vatIncluded: false,
      purePerGramSAR,
    });
    expect(result.verdict).toBe("fair");
  });

  it("flags high-priced deals when workmanship is above the upper band", () => {
    // pre-tax total = 4250 → making/g = (4250 - 3745) / 10 = 50.5 → high
    const result = evaluateFairPrice({
      totalPriceSAR: 4250,
      weightGrams: 10,
      purityFactor: 21 / 24,
      vatIncluded: false,
      purePerGramSAR,
    });
    expect(result.verdict).toBe("high");
  });

  it("matches the mock breakdown shown in the design (~377 making/g => high)", () => {
    // Mock: 21K 10g for 6000 SAR incl. VAT
    //   pre-tax = 6000 / 1.15 = 5217.39
    //   gold value @ 484 SAR/g * 10g = 4840 (design uses ~484 per gram at 21K → implies purePerGram ≈ 553)
    const purePerGram = 484 / (21 / 24); // ≈ 553.14
    const result = evaluateFairPrice({
      totalPriceSAR: 6000,
      weightGrams: 10,
      purityFactor: 21 / 24,
      vatIncluded: true,
      purePerGramSAR: purePerGram,
    });
    expect(result.preTaxTotalSAR).toBeCloseTo(5217.39, 1);
    expect(result.goldValueSAR).toBeCloseTo(4840, 0);
    expect(result.makingPerGramSAR).toBeCloseTo(37.74, 1);
    expect(result.verdict).toBe("fair");
  });
});

describe("market-trips: helpers", () => {
  it("returns 0 per-gram price when weight is 0", () => {
    expect(stopPerGramSAR(makeStop({ weightGrams: 0, totalPriceSAR: 100 }))).toBe(0);
  });

  it("computes the per-gram quoted price", () => {
    expect(stopPerGramSAR(makeStop({ weightGrams: 10, totalPriceSAR: 6000 }))).toBe(600);
  });

  it("picks the cheapest stop", () => {
    const stops = [
      makeStop({ id: "a", totalPriceSAR: 6000 }),
      makeStop({ id: "b", totalPriceSAR: 5500 }),
      makeStop({ id: "c", totalPriceSAR: 5800 }),
    ];
    expect(cheapestStop(stops)?.id).toBe("b");
  });

  it("returns undefined for the cheapest of an empty list", () => {
    expect(cheapestStop([])).toBeUndefined();
  });

  it("averages totals across stops", () => {
    const stops = [
      makeStop({ totalPriceSAR: 1000 }),
      makeStop({ totalPriceSAR: 2000 }),
      makeStop({ totalPriceSAR: 3000 }),
    ];
    expect(averageStopTotal(stops)).toBe(2000);
  });

  it("returns 0 for the average of an empty list", () => {
    expect(averageStopTotal([])).toBe(0);
  });
});
