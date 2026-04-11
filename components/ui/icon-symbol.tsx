// Fallback for using MaterialIcons on Android and web.

import MaterialIcons from "@expo/vector-icons/MaterialIcons";
import { SymbolWeight, SymbolViewProps } from "expo-symbols";
import { ComponentProps } from "react";
import { OpaqueColorValue, type StyleProp, type TextStyle } from "react-native";

type IconMapping = Record<SymbolViewProps["name"], ComponentProps<typeof MaterialIcons>["name"]>;
type IconSymbolName = keyof typeof MAPPING;

/**
 * Add your SF Symbols to Material Icons mappings here.
 * - see Material Icons in the [Icons Directory](https://icons.expo.fyi).
 * - see SF Symbols in the [SF Symbols](https://developer.apple.com/sf-symbols/) app.
 */
const MAPPING: Record<string, ComponentProps<typeof MaterialIcons>["name"]> = {
  "house.fill": "home",
  "paperplane.fill": "send",
  "chevron.left.forwardslash.chevron.right": "code",
  "chevron.right": "chevron-right",
  "heart": "favorite-border",
  "heart.fill": "favorite",
  "bag": "shopping-bag",
  "cart": "shopping-cart",
  "person": "person",
  "magnifyingglass": "search",
  "trash": "delete",
  "box": "inventory",
  "creditcard": "credit-card",
  "bell": "notifications",
  "help": "help",
  "chart.pie": "pie-chart",
  "chart.bar": "bar-chart",
  "plus": "add",
  "plus.circle.fill": "add-circle",
  "arrow.up.right": "trending-up",
  "arrow.down.right": "trending-down",
  "trending-up": "trending-up",
  "trending-down": "trending-down",
  "arrow.clockwise": "refresh",
  "arrow.left.arrow.right": "swap-horiz",
  "wifi.slash": "wifi-off",
  "calendar": "calendar-today",
  "location": "location-on",
  "clock": "access-time",
  "gear": "settings",
  "shippingbox": "inventory-2",
  "checkmark.circle": "check-circle",
  "xmark.circle": "cancel",
  "chevron.left": "chevron-left",
  "scale": "balance",
  "sparkles": "auto-awesome",
  "pencil": "edit",
  "info.circle": "info",
  "person.fill.questionmark": "support-agent",
  "chart.line.uptrend.xyaxis": "trending-up",
  "lightbulb": "lightbulb-outline",
  "lock.fill": "lock",
  "lock.shield": "security",
};

/**
 * An icon component that uses native SF Symbols on iOS, and Material Icons on Android and web.
 * This ensures a consistent look across platforms, and optimal resource usage.
 * Icon `name`s are based on SF Symbols and require manual mapping to Material Icons.
 */
export function IconSymbol({
  name,
  size = 24,
  color,
  style,
}: {
  name: IconSymbolName;
  size?: number;
  color: string | OpaqueColorValue;
  style?: StyleProp<TextStyle>;
  weight?: SymbolWeight;
}) {
  return <MaterialIcons color={color} size={size} name={MAPPING[name]} style={style} />;
}
