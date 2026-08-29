import { z } from "zod";
import { consultationRequests } from "../drizzle/schema";
import { getDb } from "./db";
import { notifyOwner } from "./_core/notification";
import { publicProcedure, router } from "./_core/trpc";

/**
 * Consultation booking requests.
 *
 * This endpoint deliberately accepts NO payment information. The session is a
 * human service that is paid for off-platform (Apple 3.1.1(e) / Google Play
 * "physical goods and services" exemption) — see docs/PUBLISHING.md §2.3.
 */

const MAX_REQUESTS_PER_WINDOW = 5;
const WINDOW_MS = 10 * 60 * 1000;
/** Coarse in-memory throttle; good enough to stop drive-by spam on one instance. */
const rate = new Map<string, number[]>();

function tooMany(key: string): boolean {
  const now = Date.now();
  // Drop expired buckets first, otherwise every IP that ever posted stays in the
  // map for the life of the process.
  for (const [ip, stamps] of rate) {
    if (stamps.every((t) => now - t >= WINDOW_MS)) rate.delete(ip);
  }
  const hits = (rate.get(key) ?? []).filter((t) => now - t < WINDOW_MS);
  hits.push(now);
  rate.set(key, hits);
  return hits.length > MAX_REQUESTS_PER_WINDOW;
}

function buildReference(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no I/O/0/1 look-alikes
  let suffix = "";
  for (let i = 0; i < 6; i += 1) {
    suffix += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return `RT-${suffix}`;
}

const requestSchema = z.object({
  fullName: z.string().trim().min(2, "Name is too short").max(160),
  email: z
    .preprocess((v) => (typeof v === "string" && v.trim() === "" ? undefined : v), z.email())
    .optional(),
  phone: z
    .preprocess(
      (v) => (typeof v === "string" && v.trim() === "" ? undefined : v),
      z
        .string()
        .trim()
        .regex(/^\+?[0-9\s-]{7,20}$/, "Phone number looks invalid")
        .max(20),
    )
    .optional(),
  preferredDate: z.string().trim().max(32).optional(),
  preferredTimes: z.array(z.string().trim().min(1).max(24)).max(8).default([]),
  notes: z.string().trim().max(2000).optional(),
  language: z.enum(["en", "ar"]).default("en"),
  /** Honeypot — bots fill this, humans never see it. */
  website: z.string().max(0).optional(),
  /** Price shown in the app at the time of the request, for the owner's reference. */
  sessionFeeSar: z.number().int().positive().max(100000).optional(),
});

export const consultationRouter = router({
  request: publicProcedure.input(requestSchema).mutation(async ({ input, ctx }) => {
    if (input.website) {
      // Silently accept spam so bots do not learn which field to remove.
      return { received: true, ignored: true } as const;
    }
    if (!input.email && !input.phone) {
      return { received: false, reason: "missing_contact" } as const;
    }

    const ip =
      (ctx.req.headers["x-forwarded-for"]?.toString().split(",")[0] ?? "").trim() ||
      ctx.req.ip ||
      "unknown";
    if (tooMany(ip)) {
      return { received: false, reason: "rate_limited" } as const;
    }

    const reference = buildReference();
    const record = {
      reference,
      fullName: input.fullName,
      email: input.email ?? null,
      phone: input.phone ?? null,
      preferredDate: input.preferredDate ?? null,
      preferredTimes: JSON.stringify(input.preferredTimes),
      notes: input.notes ?? null,
      language: input.language,
    };

    let persisted = false;
    try {
      const db = await getDb();
      if (db) {
        await db.insert(consultationRequests).values(record);
        persisted = true;
      } else {
        console.warn("[consultation] DATABASE_URL not configured — request not stored");
      }
    } catch (error) {
      console.error("[consultation] failed to store request:", error);
    }

    // Best effort: the Manus notification service is only wired up in sandboxes.
    try {
      await notifyOwner({
        title: `Gold consultation request ${reference}`,
        content: [
          `Name: ${input.fullName}`,
          `Email: ${input.email ?? "-"}`,
          `Phone: ${input.phone ?? "-"}`,
          `Date: ${input.preferredDate ?? "-"}`,
          `Times: ${input.preferredTimes.join(", ") || "-"}`,
          `Language: ${input.language}`,
          `Fee shown: ${input.sessionFeeSar ?? "-"} SAR`,
          `Notes: ${input.notes ?? "-"}`,
          `Stored in database: ${persisted ? "yes" : "no"}`,
        ].join("\n"),
      });
    } catch (error) {
      console.warn("[consultation] owner notification failed:", error);
    }

    if (!persisted) {
      // The request could not be recorded anywhere: tell the client the truth so
      // it can hand the customer a direct contact channel instead of a fake tick.
      return { received: false, reason: "not_persisted" } as const;
    }

    return { received: true, reference } as const;
  }),
});
