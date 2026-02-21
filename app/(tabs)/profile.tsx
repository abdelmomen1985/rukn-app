import { View, Text, ScrollView, Pressable } from "react-native";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import * as Haptics from "expo-haptics";

export default function ProfileScreen() {
  const colors = useColors();

  const menuItems = [
    { icon: "person", title: "Account Settings", subtitle: "Manage your account details" },
    { icon: "box", title: "Order History", subtitle: "View your past orders" },
    { icon: "heart", title: "Saved Addresses", subtitle: "Manage delivery addresses" },
    { icon: "creditcard", title: "Payment Methods", subtitle: "Manage payment options" },
    { icon: "bell", title: "Notifications", subtitle: "Manage notification preferences" },
    { icon: "help", title: "Help & Support", subtitle: "Get help with your orders" },
  ];

  const handleMenuPress = (title: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    console.log("Menu pressed:", title);
  };

  return (
    <ScreenContainer className="bg-background">
      <ScrollView className="flex-1 px-6 py-6" showsVerticalScrollIndicator={false}>
        <Text className="text-foreground text-4xl font-bold mb-8" style={{ fontFamily: "Cormorant_Garamond" }}>
          Profile
        </Text>

        <View className="bg-surface rounded-2xl p-6 mb-6 gap-4">
          <View className="w-20 h-20 bg-primary rounded-full items-center justify-center self-center">
            <IconSymbol name="person" size={40} color={colors.darkGreen} />
          </View>
          <View className="items-center gap-1">
            <Text className="text-foreground text-2xl font-bold" style={{ fontFamily: "Cormorant_Garamond" }}>
              Guest User
            </Text>
            <Text className="text-muted text-sm">Sign in to access all features</Text>
          </View>
          <Pressable
            onPress={() => handleMenuPress("Sign In")}
            style={({ pressed }) => ({
              opacity: pressed ? 0.9 : 1,
              transform: [{ scale: pressed ? 0.97 : 1 }],
            })}
            className="bg-primary py-3 rounded-full items-center"
          >
            <Text className="text-darkGreen text-base font-bold">Sign In</Text>
          </Pressable>
        </View>

        <View className="gap-2">
          {menuItems.map((item, index) => (
            <Pressable
              key={index}
              onPress={() => handleMenuPress(item.title)}
              style={({ pressed }) => ({
                opacity: pressed ? 0.7 : 1,
              })}
              className="bg-surface rounded-xl p-4 flex-row items-center gap-4"
            >
              <View className="w-10 h-10 bg-cream rounded-full items-center justify-center">
                <IconSymbol name={item.icon as any} size={20} color={colors.foreground} />
              </View>
              <View className="flex-1 gap-1">
                <Text className="text-foreground text-base font-semibold">{item.title}</Text>
                <Text className="text-muted text-sm">{item.subtitle}</Text>
              </View>
              <IconSymbol name="chevron.right" size={20} color={colors.muted} />
            </Pressable>
          ))}
        </View>

        <View className="mt-8 items-center gap-2">
          <Text className="text-muted text-sm">Version 1.0.0</Text>
          <Text className="text-muted text-xs">© 2026 Gold Jewelry. All rights reserved.</Text>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}
