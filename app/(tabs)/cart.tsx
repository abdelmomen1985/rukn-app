import { View, Text, FlatList, Image, Pressable } from "react-native";
import { ScreenContainer } from "@/components/screen-container";
import { CTAButton } from "@/components/cta-button";
import { products } from "@/data/products";
import { useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import * as Haptics from "expo-haptics";

export default function CartScreen() {
  const colors = useColors();
  const [cart, setCart] = useState<Set<string>>(new Set());

  useEffect(() => {
    loadCart();
  }, []);

  const loadCart = async () => {
    try {
      const data = await AsyncStorage.getItem("cart");
      if (data) {
        setCart(new Set(JSON.parse(data)));
      }
    } catch (error) {
      console.error("Failed to load cart:", error);
    }
  };

  const handleRemoveFromCart = async (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const newCart = new Set(cart);
    newCart.delete(id);
    setCart(newCart);
    try {
      await AsyncStorage.setItem("cart", JSON.stringify(Array.from(newCart)));
    } catch (error) {
      console.error("Failed to save cart:", error);
    }
  };

  const cartProducts = products.filter((p) => cart.has(p.id));
  const total = cartProducts.reduce((sum, p) => sum + p.price, 0);

  return (
    <ScreenContainer className="bg-background">
      <View className="flex-1 px-6 py-6">
        <Text className="text-foreground text-4xl font-bold mb-6" style={{ fontFamily: "Cormorant_Garamond" }}>
          Shopping Cart
        </Text>
        {cartProducts.length === 0 ? (
          <View className="flex-1 items-center justify-center gap-4">
            <Text className="text-muted text-lg text-center">Your cart is empty</Text>
            <Text className="text-muted text-sm text-center">
              Add items to your cart to continue shopping
            </Text>
          </View>
        ) : (
          <>
            <FlatList
              data={cartProducts}
              contentContainerStyle={{ gap: 16, paddingBottom: 120 }}
              showsVerticalScrollIndicator={false}
              renderItem={({ item }) => (
                <View className="flex-row gap-4 bg-surface p-4 rounded-xl">
                  <Image source={item.image} className="w-24 h-24 rounded-lg" resizeMode="cover" />
                  <View className="flex-1 gap-2">
                    <Text className="text-foreground text-base font-semibold" numberOfLines={2}>
                      {item.name}
                    </Text>
                    <Text className="text-primary text-lg font-bold">${item.price.toFixed(2)}</Text>
                  </View>
                  <Pressable
                    onPress={() => handleRemoveFromCart(item.id)}
                    style={({ pressed }) => ({
                      opacity: pressed ? 0.6 : 1,
                    })}
                    className="w-8 h-8 items-center justify-center"
                  >
                    <IconSymbol name="trash" size={20} color={colors.error} />
                  </Pressable>
                </View>
              )}
              keyExtractor={(item) => item.id}
            />
            <View className="absolute bottom-0 left-0 right-0 bg-background border-t border-border px-6 py-6 gap-4">
              <View className="flex-row justify-between items-center">
                <Text className="text-foreground text-xl font-semibold">Total</Text>
                <Text className="text-primary text-2xl font-bold">${total.toFixed(2)}</Text>
              </View>
              <CTAButton title="Checkout" />
            </View>
          </>
        )}
      </View>
    </ScreenContainer>
  );
}
