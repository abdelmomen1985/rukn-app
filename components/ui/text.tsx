import { Text as RNText, StyleSheet, type TextProps } from "react-native";
import { useI18n } from "@/lib/i18n";

// NativeWind font-weight class → fontWeight value
const CLASS_WEIGHT: Record<string, string> = {
  "font-thin": "100",
  "font-extralight": "200",
  "font-light": "300",
  "font-normal": "400",
  "font-medium": "500",
  "font-semibold": "600",
  "font-bold": "700",
  "font-extrabold": "800",
  "font-black": "900",
};

// fontWeight → exact loaded font variant name
const CAIRO_WEIGHT: Record<string, string> = {
  "100": "Cairo_200ExtraLight",
  "200": "Cairo_200ExtraLight",
  "300": "Cairo_300Light",
  "400": "Cairo_400Regular",
  "500": "Cairo_500Medium",
  "600": "Cairo_600SemiBold",
  "700": "Cairo_700Bold",
  "800": "Cairo_800ExtraBold",
  "900": "Cairo_900Black",
};

const INTER_WEIGHT: Record<string, string> = {
  "100": "Inter_100Thin",
  "200": "Inter_200ExtraLight",
  "300": "Inter_300Light",
  "400": "Inter_400Regular",
  "500": "Inter_500Medium",
  "600": "Inter_600SemiBold",
  "700": "Inter_700Bold",
  "800": "Inter_800ExtraBold",
  "900": "Inter_900Black",
};

export function Text({ style, className, ...props }: TextProps) {
  const { lang } = useI18n();
  const isAr = lang === "ar";

  // 1. Detect fontWeight from className (e.g. "font-bold" → "700")
  const classes = className?.split(" ") ?? [];
  const weightFromClass =
    classes.map((c) => CLASS_WEIGHT[c]).find(Boolean) ?? null;

  // 2. Also read fontWeight from explicit style prop
  const flat = StyleSheet.flatten(style) ?? {};
  const weightFromStyle = flat.fontWeight ? String(flat.fontWeight) : null;

  const weight = weightFromClass ?? weightFromStyle ?? "400";
  const weightMap = isAr ? CAIRO_WEIGHT : INTER_WEIGHT;
  const fontFamily = weightMap[weight] ?? (isAr ? "Cairo_400Regular" : "Inter_400Regular");

  // 3. Strip font-weight classes so NativeWind doesn't inject a conflicting
  //    fontWeight that causes iOS to look up a non-existent bold variant.
  const cleanedClassName = classes
    .filter((c) => !CLASS_WEIGHT[c])
    .join(" ") || undefined;

  // 4. Strip fontWeight and fontFamily from explicit style — fontFamily variant encodes both.
  const { fontWeight: _fw, fontFamily: _ff, ...restStyle } = flat;

  return (
    <RNText
      style={[restStyle, { fontFamily }]}
      className={cleanedClassName}
      {...props}
    />
  );
}
