import React from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';

export const LoadingContent: React.FC = React.memo(
  () => (
    <View style={styles.container}>
      <ActivityIndicator />
    </View>
  ),
  () => true
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'white',
  },
});
