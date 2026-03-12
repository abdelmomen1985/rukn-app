import "@/global.css";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useCallback, useEffect, useMemo, useState } from "react";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import "react-native-reanimated";
import { Platform, View } from "react-native";
import * as Font from "expo-font";
import "@/lib/_core/nativewind-pressable";
import { ThemeProvider } from "@/lib/theme-provider";
import {
  SafeAreaFrameContext,
  SafeAreaInsetsContext,
  SafeAreaProvider,
  initialWindowMetrics,
} from "react-native-safe-area-context";
import type { EdgeInsets, Metrics, Rect } from "react-native-safe-area-context";

import { trpc, createTRPCClient } from "@/lib/trpc";
import { initManusRuntime, subscribeSafeAreaInsets } from "@/lib/_core/manus-runtime";
import { I18nProvider, useI18n } from "@/lib/i18n";
import { MockDataProvider } from "@/lib/mock-data-provider";
import { PortfolioProvider } from "@/lib/portfolio-provider";
import * as CairoFont from "@expo-google-fonts/cairo";
import * as InterFont from "@expo-google-fonts/inter";

function DirectionWrapper({ children }: { children: React.ReactNode }) {
  const { isRTL } = useI18n();

  return (
    <View style={{ flex: 1, direction: isRTL ? "rtl" : "ltr" }}>
      {children}
    </View>
  );
}


const DEFAULT_WEB_INSETS: EdgeInsets = { top: 0, right: 0, bottom: 0, left: 0 };
const DEFAULT_WEB_FRAME: Rect = { x: 0, y: 0, width: 0, height: 0 };

export const unstable_settings = {
  anchor: "(tabs)",
};

export default function RootLayout() {
  const initialInsets = initialWindowMetrics?.insets ?? DEFAULT_WEB_INSETS;
  const initialFrame = initialWindowMetrics?.frame ?? DEFAULT_WEB_FRAME;

  const [insets, setInsets] = useState<EdgeInsets>(initialInsets);
  const [frame, setFrame] = useState<Rect>(initialFrame);
  const [fontsLoaded, setFontsLoaded] = useState(false);

  // Load custom fonts — names must match what CSS and StyleSheet reference
  useEffect(() => {
    const loadFonts = async () => {
      try {
        await Font.loadAsync({
          Cairo_200ExtraLight: CairoFont.Cairo_200ExtraLight,
          Cairo_300Light: CairoFont.Cairo_300Light,
          Cairo_400Regular: CairoFont.Cairo_400Regular,
          Cairo_500Medium: CairoFont.Cairo_500Medium,
          Cairo_600SemiBold: CairoFont.Cairo_600SemiBold,
          Cairo_700Bold: CairoFont.Cairo_700Bold,
          Cairo_800ExtraBold: CairoFont.Cairo_800ExtraBold,
          Cairo_900Black: CairoFont.Cairo_900Black,
          Inter_100Thin: InterFont.Inter_100Thin,
          Inter_200ExtraLight: InterFont.Inter_200ExtraLight,
          Inter_300Light: InterFont.Inter_300Light,
          Inter_400Regular: InterFont.Inter_400Regular,
          Inter_500Medium: InterFont.Inter_500Medium,
          Inter_600SemiBold: InterFont.Inter_600SemiBold,
          Inter_700Bold: InterFont.Inter_700Bold,
          Inter_800ExtraBold: InterFont.Inter_800ExtraBold,
          Inter_900Black: InterFont.Inter_900Black,
        });
        setFontsLoaded(true);
      } catch (error) {
        console.warn("Error loading fonts:", error);
        setFontsLoaded(true);
      }
    };
    loadFonts();
  }, []);

  // Initialize Manus runtime for cookie injection from parent container
  useEffect(() => {
    initManusRuntime();
  }, []);

  const handleSafeAreaUpdate = useCallback((metrics: Metrics) => {
    setInsets(metrics.insets);
    setFrame(metrics.frame);
  }, []);

  useEffect(() => {
    if (Platform.OS !== "web") return;
    const unsubscribe = subscribeSafeAreaInsets(handleSafeAreaUpdate);
    return () => unsubscribe();
  }, [handleSafeAreaUpdate]);

  // Create clients once and reuse them
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            // Disable automatic refetching on window focus for mobile
            refetchOnWindowFocus: false,
            // Retry failed requests once
            retry: 1,
          },
        },
      }),
  );
  const [trpcClient] = useState(() => createTRPCClient());

  // Ensure minimum 8px padding for top and bottom on mobile
  const providerInitialMetrics = useMemo(() => {
    const metrics = initialWindowMetrics ?? { insets: initialInsets, frame: initialFrame };
    return {
      ...metrics,
      insets: {
        ...metrics.insets,
        top: Math.max(metrics.insets.top, 16),
        bottom: Math.max(metrics.insets.bottom, 12),
      },
    };
  }, [initialInsets, initialFrame]);

  const content = (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <trpc.Provider client={trpcClient} queryClient={queryClient}>
        <QueryClientProvider client={queryClient}>
          {/* Default to hiding native headers so raw route segments don't appear (e.g. "(tabs)", "products/[id]"). */}
          {/* If a screen needs the native header, explicitly enable it and set a human title via Stack.Screen options. */}
          {/* in order for ios apps tab switching to work properly, use presentation: "fullScreenModal" for login page, whenever you decide to use presentation: "modal*/}
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="(tabs)" />
            <Stack.Screen name="oauth/callback" />
            <Stack.Screen name="order-history" />
            <Stack.Screen name="portfolio/add-asset" />
            <Stack.Screen name="portfolio/asset-detail" />
            <Stack.Screen name="portfolio/converter" />
            <Stack.Screen name="portfolio/zakat" />
          </Stack>
          <StatusBar style="auto" />
        </QueryClientProvider>
      </trpc.Provider>
    </GestureHandlerRootView>
  );

  const shouldOverrideSafeArea = Platform.OS === "web";

  if (shouldOverrideSafeArea) {
    return (
      <I18nProvider>
        <MockDataProvider>
        <PortfolioProvider>
        <ThemeProvider>
          <SafeAreaProvider initialMetrics={providerInitialMetrics}>
            <SafeAreaFrameContext.Provider value={frame}>
              <SafeAreaInsetsContext.Provider value={insets}>
                <DirectionWrapper>{content}</DirectionWrapper>
              </SafeAreaInsetsContext.Provider>
            </SafeAreaFrameContext.Provider>
          </SafeAreaProvider>
        </ThemeProvider>
        </PortfolioProvider>
        </MockDataProvider>
      </I18nProvider>
    );
  }

  return (
    <I18nProvider>
      <MockDataProvider>
        <PortfolioProvider>
          <ThemeProvider>
            <SafeAreaProvider initialMetrics={providerInitialMetrics}>
              <DirectionWrapper>{content}</DirectionWrapper>
            </SafeAreaProvider>
          </ThemeProvider>
        </PortfolioProvider>
      </MockDataProvider>
    </I18nProvider>
  );
}
