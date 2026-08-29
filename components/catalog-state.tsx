import { ActivityIndicator, View } from "react-native";
import { Text } from "@/components/ui/text";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { CTAButton } from "@/components/cta-button";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";

/**
 * One place for the three non-happy catalog states so no screen can quietly
 * render "an empty screen that looks like a broken app" — reviewers rate that
 * 1 star, and Apple 4.2.2 rejects builds whose core content never loads.
 */
export function CatalogState({
  isLoading,
  error,
  isEmpty,
  onRetry,
  emptyIcon = "bag",
}: {
  isLoading: boolean;
  error: string | null;
  isEmpty: boolean;
  onRetry: () => void;
  emptyIcon?: string;
}) {
  const colors = useColors();
  const { t } = useI18n();

  if (isLoading) {
    return (
      <View className="items-center justify-center py-16 gap-3">
        <ActivityIndicator size="large" color={colors.primary} />
        <Text className="text-muted text-base">{t("catalogLoading")}</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View className="items-center justify-center px-6 py-16 gap-3">
        <IconSymbol name="wifi.slash" size={40} color={colors.muted} />
        <Text className="text-foreground text-lg font-bold text-center">
          {t("catalogErrorTitle")}
        </Text>
        <Text className="text-muted text-sm text-center">{t("catalogErrorSubtitle")}</Text>
        <View className="w-full max-w-[220px] pt-2">
          <CTAButton title={t("retry")} onPress={onRetry} />
        </View>
      </View>
    );
  }

  if (isEmpty) {
    return (
      <View className="items-center justify-center px-6 py-16 gap-3">
        <IconSymbol name={emptyIcon} size={40} color={colors.muted} />
        <Text className="text-foreground text-lg font-bold text-center">
          {t("catalogEmptyTitle")}
        </Text>
        <Text className="text-muted text-sm text-center">{t("catalogEmptySubtitle")}</Text>
        <View className="w-full max-w-[220px] pt-2">
          <CTAButton title={t("retry")} onPress={onRetry} variant="outline" />
        </View>
      </View>
    );
  }

  return null;
}
