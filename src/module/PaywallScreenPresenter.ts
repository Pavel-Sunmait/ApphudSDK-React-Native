import type { ApphudProduct, ApphudPurchaseResult, IDisposable } from './types';
import {
  NativeModules,
  NativeEventEmitter,
  type EventSubscription,
} from 'react-native';

const { PaywallscreenPresenter: PaywallscreenPresenterInternal } =
  NativeModules;

type Options = {
  placementIdentifier: string;
};

let paywallScreenPresenterIdInternal = 0;

const EVENT_TYPES = {
  TRANSACTION_STARTED: 'transactionStarted',
  TRANSACTION_COMPLETED: 'transactionCompleted',
  CLOSE_BUTTON_TAPPED: 'closeButtonTapped',
  ERROR: 'error',
  SCREEN_SHOWN: 'screenShown',
} as const;

type EventCallbacks = {
  [EVENT_TYPES.TRANSACTION_STARTED]: (product: ApphudProduct | null) => void;
  [EVENT_TYPES.TRANSACTION_COMPLETED]: (result: ApphudPurchaseResult) => void;
  [EVENT_TYPES.CLOSE_BUTTON_TAPPED]: () => void;
  [EVENT_TYPES.ERROR]: (error: any) => void;
  [EVENT_TYPES.SCREEN_SHOWN]: () => void;
};

const emitter = new NativeEventEmitter(PaywallscreenPresenterInternal);
const NOP = () => {};

export class PaywallScreenPresenter implements IDisposable {
  private isDisposed = false;
  private readonly id = (++paywallScreenPresenterIdInternal).toString();
  private susbcriptions: Set<EventSubscription> = new Set();

  constructor(private readonly options: Partial<Options> = {}) {}

  displayPaywallScreen() {
    PaywallscreenPresenterInternal.displayPaywallScreen({
      ...this.options,
      paywallScreenPresenterId: this.id,
    });
  }

  addEventListener<Name extends keyof EventCallbacks>(
    name: Name,
    callback: EventCallbacks[Name]
  ) {
    if (this.isDisposed) {
      return NOP;
    }

    const subscription = emitter.addListener(
      name,
      ({ paywallScreenPresenterId, payload }) => {
        if (paywallScreenPresenterId === this.id) {
          callback(payload);
        }
      }
    );

    this.susbcriptions.add(subscription);

    return () => {
      if (this.isDisposed) {
        return;
      }
      this.susbcriptions.delete(subscription);
      subscription.remove();
    };
  }

  dispose() {
    this.isDisposed = true;

    for (const sub of this.susbcriptions.values()) {
      sub.remove();
    }
  }
}
