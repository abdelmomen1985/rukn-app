import { View, ScrollView, Pressable, Image } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useMockData } from "@/lib/mock-data-provider";
import { useRouter } from "expo-router";
import type { Order, OrderStatus } from "@/data/orders";

const STATUS_CONFIG: Record<OrderStatus, { label: string; labelAr: string; color: string; bg: string; icon: string }> = {
  pending:    { label: "Pending",    labelAr: "قيد الانتظار", color: "#92400E", bg: "#FEF3C7", icon: "clock" },
  processing: { label: "Processing", labelAr: "جارٍ المعالجة", color: "#1E40AF", bg: "#DBEAFE", icon: "gear" },
  shipped:    { label: "Shipped",    labelAr: "تم الشحن",      color: "#5B21B6", bg: "#EDE9FE", icon: "shippingbox" },
  delivered:  { label: "Delivered",  labelAr: "تم التسليم",    color: "#065F46", bg: "#D1FAE5", icon: "checkmark.circle" },
  cancelled:  { label: "Cancelled",  labelAr: "ملغي",          color: "#991B1B", bg: "#FEE2E2", icon: "xmark.circle" },
};

function StatusBadge({ status, isRTL }: { status: OrderStatus; isRTL: boolean }) {
  const cfg = STATUS_CONFIG[status];
  return (
    <View
      style={{
        flexDirection: isRTL ? "row-reverse" : "row",
        alignItems: "center",
        gap: 4,
        backgroundColor: cfg.bg,
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 20,
      }}
    >
      <IconSymbol name={cfg.icon as any} size={12} color={cfg.color} />
      <Text style={{ color: cfg.color, fontSize: 12, fontWeight: "600" }}>
        {isRTL ? cfg.labelAr : cfg.label}
      </Text>
    </View>
  );
}

function OrderCard({ order, isRTL, colors }: { order: Order; isRTL: boolean; colors: any }) {
  const itemCount = order.items.reduce((sum, i) => sum + i.quantity, 0);
  const formattedDate = new Date(order.date).toLocaleDateString(isRTL ? "ar-SA" : "en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <View
      style={{
        backgroundColor: colors.surface,
        borderRadius: 16,
        padding: 16,
        gap: 12,
        marginBottom: 12,
      }}
    >
      {/* Order header */}
      <View style={{ flexDirection: isRTL ? "row-reverse" : "row", justifyContent: "space-between", alignItems: "center" }}>
        <Text style={{ color: colors.foreground, fontSize: 16, fontWeight: "700" }}>
          {order.orderNumber}
        </Text>
        <StatusBadge status={order.status} isRTL={isRTL} />
      </View>

      {/* Date & item count */}
      <View style={{ flexDirection: isRTL ? "row-reverse" : "row", gap: 12 }}>
        <View style={{ flexDirection: isRTL ? "row-reverse" : "row", alignItems: "center", gap: 4 }}>
          <IconSymbol name="calendar" size={14} color={colors.muted} />
          <Text style={{ color: colors.muted, fontSize: 13 }}>{formattedDate}</Text>
        </View>
        <View style={{ flexDirection: isRTL ? "row-reverse" : "row", alignItems: "center", gap: 4 }}>
          <IconSymbol name="bag" size={14} color={colors.muted} />
          <Text style={{ color: colors.muted, fontSize: 13 }}>
            {isRTL ? `${itemCount} قطعة` : `${itemCount} item${itemCount !== 1 ? "s" : ""}`}
          </Text>
        </View>
      </View>

      {/* Item images strip */}
      <View style={{ flexDirection: isRTL ? "row-reverse" : "row", gap: 8 }}>
        {order.items.slice(0, 3).map((item, idx) => (
          <View key={idx} style={{ position: "relative" }}>
            <Image
              source={item.image}
              style={{ width: 56, height: 56, borderRadius: 8 }}
              resizeMode="cover"
            />
            {item.quantity > 1 && (
              <View
                style={{
                  position: "absolute",
                  bottom: -4,
                  right: -4,
                  backgroundColor: colors.primary,
                  borderRadius: 10,
                  width: 18,
                  height: 18,
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <Text style={{ color: colors.darkGreen, fontSize: 10, fontWeight: "700" }}>
                  ×{item.quantity}
                </Text>
              </View>
            )}
          </View>
        ))}
        {order.items.length > 3 && (
          <View
            style={{
              width: 56,
              height: 56,
              borderRadius: 8,
              backgroundColor: colors.border,
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Text style={{ color: colors.muted, fontSize: 13, fontWeight: "600" }}>
              +{order.items.length - 3}
            </Text>
          </View>
        )}
      </View>

      {/* Divider */}
      <View style={{ height: 1, backgroundColor: colors.border }} />

      {/* Total & address */}
      <View style={{ flexDirection: isRTL ? "row-reverse" : "row", justifyContent: "space-between", alignItems: "flex-end" }}>
        <View style={{ gap: 2, flex: 1, marginRight: isRTL ? 0 : 12, marginLeft: isRTL ? 12 : 0 }}>
          <View style={{ flexDirection: isRTL ? "row-reverse" : "row", alignItems: "center", gap: 4 }}>
            <IconSymbol name="location" size={12} color={colors.muted} />
            <Text style={{ color: colors.muted, fontSize: 12 }} numberOfLines={1}>
              {order.address}
            </Text>
          </View>
        </View>
        <Text style={{ color: colors.primary, fontSize: 18, fontWeight: "700", flexShrink: 0 }}>
          ${order.total.toLocaleString()}
        </Text>
      </View>
    </View>
  );
}

export default function OrderHistoryScreen() {
  const colors = useColors();
  const { t, isRTL } = useI18n();
  const { orders } = useMockData();
  const router = useRouter();

  return (
    <ScreenContainer className="bg-background">
      {/* Header */}
      <View
        style={{
          flexDirection: isRTL ? "row-reverse" : "row",
          alignItems: "center",
          gap: 12,
          paddingHorizontal: 24,
          paddingVertical: 16,
          borderBottomWidth: 0.5,
          borderBottomColor: colors.border,
        }}
      >
        <Pressable
          onPress={() => router.back()}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
            width: 36,
            height: 36,
            borderRadius: 18,
            backgroundColor: colors.surface,
            alignItems: "center",
            justifyContent: "center",
          })}
        >
          <IconSymbol
            name={isRTL ? "chevron.right" : "chevron.left"}
            size={20}
            color={colors.foreground}
          />
        </Pressable>
        <Text
          style={{ color: colors.foreground, fontSize: 20, fontWeight: "700", flex: 1, textAlign: isRTL ? "right" : "left" }}
        >
          {t("orderHistory")}
        </Text>
        <Text style={{ color: colors.muted, fontSize: 14 }}>
          {isRTL ? `${orders.length} طلبات` : `${orders.length} orders`}
        </Text>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16 }}>
        {orders.map((order) => (
          <OrderCard key={order.id} order={order} isRTL={isRTL} colors={colors} />
        ))}
      </ScrollView>
    </ScreenContainer>
  );
}
