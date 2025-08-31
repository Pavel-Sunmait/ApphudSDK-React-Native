import React from 'react';
import {
  type RouteProp,
  useRoute,
  useNavigation,
} from '@react-navigation/native';
import { PaywallScreenView } from '@apphud/react-native-apphud-sdk';

const PaywallNativeScreen = () => {
  const route = useRoute<RouteProp<Record<string, Record<string, any>>>>();
  const navigation = useNavigation();

  return (
    <PaywallScreenView
      placementIdentifier={route.params.placementIdentifier}
      onFinished={({ nativeEvent: { result } }) => {
        if (result.type === 'userClosed') {
          navigation.goBack();
        }
      }}
    />
  );
};

export default PaywallNativeScreen;
