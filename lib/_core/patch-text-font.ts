/**
 * Monkey-patches React Native's Text component to apply a global fontFamily.
 * On native, Text components don't inherit font from CSS or parent Views,
 * so each Text must have fontFamily in its style. This patch injects it
 * as a base style that can still be overridden by component-level styles.
 *
 * Import this file once in _layout.tsx (side-effect import).
 */
import { Text, Platform } from "react-native";

// Only patch on native — web uses the <style> tag approach in i18n.tsx
if (Platform.OS !== "web") {
  // forwardRef components in RN expose a .render property
  const originalRender = (Text as any).render;

  if (typeof originalRender === "function") {
    (Text as any).render = function patchedTextRender(props: any, ref: any) {
      // Read the current font from the global set by i18n
      const fontFamily =
        (globalThis as any).__currentAppFont ?? "Inter";

      const patchedProps = {
        ...props,
        style: [{ fontFamily }, props.style],
      };
      return originalRender.call(this, patchedProps, ref);
    };
  }
}
