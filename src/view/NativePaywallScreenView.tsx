import React, { type ComponentProps, type ReactElement } from 'react';
import {
  requireNativeComponent,
  View,
  UIManager,
  StyleSheet,
  findNodeHandle,
  type NativeSyntheticEvent,
  type ViewStyle,
  type ViewProps,
} from 'react-native';
import { type ApphudProduct, type ApphudPaywallResult } from '../module';
import { LoadingContent } from './LoadingContent';
import { ErrorContent } from './ErrorContent';
import { type LoadingViewError } from './types';

const NativePaywallScreenView = requireNativeComponent<{
  placementIdentifier: string;
  onStartLoading?: (
    event: NativeSyntheticEvent<{ placementIdentifier: string }>
  ) => void;
  onReceiveView?: (event: NativeSyntheticEvent<{}>) => void;
  onLoadingError?: (
    event: NativeSyntheticEvent<{
      placementIdentifier: string;
      error: LoadingViewError;
    }>
  ) => void;
  onTransactionStarted?: (product: ApphudProduct | null) => void;
  onFinished?: (
    event: NativeSyntheticEvent<{ result: ApphudPaywallResult }>
  ) => void;
  style?: ViewStyle;
  renderLoading?: () => ReactElement;
  renderError?: (error: LoadingViewError, onReload: () => void) => ReactElement;
}>('PaywallScreenView');

type Props = ComponentProps<typeof NativePaywallScreenView> & ViewProps;

export const PaywallScreenView: React.FC<Props> = ({
  onStartLoading,
  onLoadingError,
  onReceiveView,
  style,
  renderLoading = () => <LoadingContent />,
  renderError = (error: any, onReload: () => void) => (
    <ErrorContent error={error} onReload={onReload} />
  ),
  ...props
}) => {
  const nativeView = React.useRef(null);

  const [isLoading, setIsLoading] = React.useState(false);
  const [error, setError] = React.useState<LoadingViewError | null>(null);

  const commonStyles = StyleSheet.compose(
    [innerStyles.flex, innerStyles.background],
    style
  );

  const reload = React.useCallback(() => {
    const reactTag = findNodeHandle(nativeView.current);
    const command =
      UIManager.getViewManagerConfig('PaywallScreenView').Commands.reload;

    if (!command) {
      return;
    }

    UIManager.dispatchViewManagerCommand(reactTag, command, []);
  }, []);

  const _onStartLoading = React.useCallback<
    NonNullable<Props['onStartLoading']>
  >(
    (event) => {
      setIsLoading(true);
      setError(null);
      onStartLoading?.(event);
    },
    [onStartLoading]
  );

  const _onLoadingError = React.useCallback<
    NonNullable<Props['onLoadingError']>
  >(
    (event) => {
      setIsLoading(false);
      setError(event.nativeEvent.error);
      onLoadingError?.(event);
    },
    [onLoadingError]
  );

  const _onReceiveView = React.useCallback<NonNullable<Props['onReceiveView']>>(
    (event) => {
      setIsLoading(false);
      onReceiveView?.(event);
    },
    [onReceiveView]
  );

  return (
    <View style={commonStyles}>
      <NativePaywallScreenView
        ref={nativeView}
        style={innerStyles.flex}
        {...props}
        onStartLoading={_onStartLoading}
        onLoadingError={_onLoadingError}
        onReceiveView={_onReceiveView}
      />
      {(isLoading || error !== null) && (
        <View style={[innerStyles.overload, innerStyles.background]}>
          {isLoading && renderLoading()}
          {error !== null && renderError(error, reload)}
        </View>
      )}
    </View>
  );
};

const innerStyles = StyleSheet.create({
  background: {
    backgroundColor: 'white',
  },
  flex: {
    flex: 1,
  },
  overload: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
});
