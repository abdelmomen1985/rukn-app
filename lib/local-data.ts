import AsyncStorage from "@react-native-async-storage/async-storage";
import * as SecureStore from "expo-secure-store";
import { Platform } from "react-native";
import { SESSION_TOKEN_KEY, USER_INFO_KEY } from "@/constants/oauth";

/**
 * Everything this app stores on the device. Account deletion (required by both
 * stores — Play "Account deletion" policy and App Store Guideline 5.1.1(v))
 * must clear all of it, plus the server-side copy via Medusa.
 *
 * `app_language` is intentionally preserved: it is a preference, not personal
 * data, and wiping it logs the user straight back into a language prompt.
 */
export const DEVICE_DATA_KEYS = [
  "portfolio_assets",
  "portfolio_metals",
  "spot_prices_cache",
  "market_trips",
  "cart",
  "wishlist",
] as const;

/** Medusa customer JWT lives in SecureStore on native, AsyncStorage on web. */
const MEDUSA_TOKEN_KEY = "medusa_customer_token";

const AUTH_KEYS = [SESSION_TOKEN_KEY, USER_INFO_KEY];

export async function wipeDeviceData(): Promise<void> {
  await AsyncStorage.multiRemove([...DEVICE_DATA_KEYS, MEDUSA_TOKEN_KEY]);

  try {
    if (Platform.OS === "web") {
      await AsyncStorage.multiRemove(AUTH_KEYS);
    } else {
      await Promise.all(AUTH_KEYS.map((key) => SecureStore.deleteItemAsync(key)));
    }
  } catch (error) {
    console.warn("[local-data] could not clear session keys:", error);
  }
}
