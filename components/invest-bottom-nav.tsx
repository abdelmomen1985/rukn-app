import { View, Pressable, StyleSheet, Platform } from "react-native";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { Text } from "@/components/ui/text";
import { useColors } from "@/hooks/use-colors";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { useI18n } from "@/lib/i18n";
import { useSafeAreaInsets } from "react-native-safe-area-context";

interface NavItem {
  id: string;
  icon: string;
  labelKey: string;
  route: string;
  iconColor: string;
}

const NAV_ITEMS: NavItem[] = [
  {
    id: "converter",
    icon: "arrow.left.arrow.right",
    labelKey: "converter",
    route: "/invest/converter",
    iconColor: "#D4AF37",
  },
  {
    id: "zakat",
    icon: "scale",
    labelKey: "zakat",
    route: "/invest/zakat",
    iconColor: "#D97706",
  },
  {
    id: "consultation",
    icon: "person.fill.questionmark",
    labelKey: "consultationTitle",
    route: "/invest/consultation",
    iconColor: "#059669",
  },
  {
    id: "trips",
    icon: "bag",
    labelKey: "tripsCardLabel",
    route: "/invest/trips",
    iconColor: "#A4313F",
  },
  {
    id: "add-asset",
    icon: "plus.circle.fill",
    labelKey: "addAsset",
    route: "/invest/add-asset",
    iconColor: "#07352b",
  },
];

export function InvestBottomNav() {
  const colors = useColors();
  const router = useRouter();
  const { t } = useI18n();
  const insets = useSafeAreaInsets();

  const handlePress = (route: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    router.push(route);
  };

  const bottomPadding = Platform.OS === "web" ? 12 : Math.max(insets.bottom, 8);

  return (
    <View style={[
      styles.container,
      {
        borderTopColor: colors.border,
        backgroundColor: colors.background,
        paddingBottom: bottomPadding,
      }
    ]}>
      {NAV_ITEMS.map((item) => (
        <Pressable
          key={item.id}
          testID={`${item.id}-button`}
          onPress={() => handlePress(item.route)}
          style={({ pressed }) => [
            styles.navItem,
            {
              opacity: pressed ? 0.7 : 1,
              backgroundColor: colors.surface,
            },
          ]}
        >
          <View style={[styles.iconContainer, { backgroundColor: item.iconColor + '15' }]}>
            <IconSymbol name={item.icon} size={24} color={item.iconColor} />
          </View>
          <Text style={[styles.label, { color: colors.foreground }]}>
            {t(item.labelKey as any)}
          </Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    borderTopWidth: 1,
    paddingVertical: 12,
    paddingHorizontal: 8,
    gap: 8,
  },
  navItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    paddingHorizontal: 4,
    borderRadius: 12,
    gap: 6,
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    fontSize: 11,
    fontWeight: '600',
    textAlign: 'center',
  },
});