import React from 'react';
import { View, StyleSheet, Text, Button } from 'react-native';
import { type LoadingViewError } from './types';

export const ErrorContent: React.FC<{
  error: LoadingViewError;
  onReload: () => void;
}> = ({ error, onReload }) => (
  <View style={styles.container}>
    <Text style={styles.text}>{error.localizedDescription}</Text>
    <Button title="Reload" onPress={onReload} />
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    maxWidth: '100%',
  },
});
