import { int, mysqlEnum, mysqlTable, text, timestamp, varchar } from "drizzle-orm/mysql-core";

/**
 * Core user table backing auth flow.
 * Extend this file with additional tables as your product grows.
 * Columns use camelCase to match both database fields and generated types.
 */
export const users = mysqlTable("users", {
  /**
   * Surrogate primary key. Auto-incremented numeric value managed by the database.
   * Use this for relations between tables.
   */
  id: int("id").autoincrement().primaryKey(),
  /** Manus OAuth identifier (openId) returned from the OAuth callback. Unique per user. */
  openId: varchar("openId", { length: 64 }).notNull().unique(),
  name: text("name"),
  email: varchar("email", { length: 320 }),
  loginMethod: varchar("loginMethod", { length: 64 }),
  role: mysqlEnum("role", ["user", "admin"]).default("user").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
  lastSignedIn: timestamp("lastSignedIn").defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;

// Consultation booking requests sent from app/invest/consultation.tsx.
// Personal data only: no payment data is ever collected by this app.
export const consultationRequests = mysqlTable("consultationRequests", {
  id: int("id").autoincrement().primaryKey(),
  /** Human-readable reference shown to the customer, e.g. "RT-8F2K-4QX". */
  reference: varchar("reference", { length: 24 }).notNull().unique(),
  fullName: varchar("fullName", { length: 160 }).notNull(),
  email: varchar("email", { length: 320 }),
  phone: varchar("phone", { length: 40 }),
  preferredDate: varchar("preferredDate", { length: 32 }),
  /** JSON-encoded string[] of the time slots the customer selected. */
  preferredTimes: text("preferredTimes"),
  notes: text("notes"),
  language: varchar("language", { length: 8 }).default("en").notNull(),
  status: mysqlEnum("status", ["new", "contacted", "closed"]).default("new").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type ConsultationRequest = typeof consultationRequests.$inferSelect;
export type InsertConsultationRequest = typeof consultationRequests.$inferInsert;
