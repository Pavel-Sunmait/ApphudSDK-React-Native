import ApphudSDK
import StoreKit

@objc(ApphudSdk)
class ApphudSdk: NSObject {
    
  override init() {
    ApphudHttpClient.shared.sdkType = "reactnative";
    ApphudHttpClient.shared.sdkVersion = "2.2.0";
  }

  @objc(start:withResolver:withRejecter:)
  func start(
    options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    let apiKey = options["apiKey"] as! String;
    let userID = options["userId"] as? String;
    let observerMode = options["observerMode"] as? Bool ?? true;
    DispatchQueue.main.async {
#if DEBUG
      ApphudUtils.enableAllLogs()
#endif
      Apphud.start(apiKey: apiKey, userID: userID, observerMode: observerMode) { _ in
        resolve(nil)
      }
      Apphud.setDeviceIdentifiers(idfa: nil, idfv: UIDevice.current.identifierForVendor?.uuidString)
    }
  }
    
  @objc(startManually:withResolver:withRejecter:)
  func startManually(
    options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: RCTPromiseRejectBlock
  ) {
    let apiKey = options["apiKey"] as! String;
    let userID = options["userId"] as? String;
    let deviceID = options["deviceId"] as? String;
    let observerMode = options["observerMode"] as? Bool ?? true;
    DispatchQueue.main.async {
      Apphud
        .startManually(
          apiKey: apiKey,
          userID: userID,
          deviceID: deviceID,
          observerMode: observerMode
        ) { _ in
          resolve(nil)
        }
      Apphud.setDeviceIdentifiers(idfa: nil, idfv: UIDevice.current.identifierForVendor?.uuidString)
    }
  }
    
  @objc(logout:withRejecter:)
  func logout(
    resolve: @escaping RCTPromiseResolveBlock,
    reject:RCTPromiseRejectBlock
  ) {
    Task {
      await Apphud.logout()
      resolve(nil)
    }
  }
    
  @objc(hasActiveSubscription:withRejecter:)
  func hasActiveSubscription(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    resolve(Apphud.hasActiveSubscription());
  }

  @objc(hasPremiumAccess:withRejecter:)
  func hasPremiumAccess(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    resolve(Apphud.hasPremiumAccess());
  }

  @objc(products:withRejecter:)
  func products(resolve: @escaping RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    Apphud.fetchProducts { products, error in
      resolve(products.map { DataTransformer.skProduct(product: $0) });
    }
  }
  
  
  private func paywalls() async -> [ApphudPaywall] {
    await withCheckedContinuation { continuation in
      Task { @MainActor in
        Apphud.paywallsDidLoadCallback { paywalls, _ in
          continuation.resume(returning: paywalls)
        }
      }
    }
  }
  
  @objc(purchase:withResolver:withRejecter:)
  func purchase(args: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {

    guard let productId = args["productId"] as? String, productId.count > 0 else {
      reject("Error", "ProductId not set", nil)
      return
    }
    let paywallId = args["paywallId"] as? String

    Task { @MainActor in
      var product: ApphudProduct?
      let paywalls = await paywalls()

      for paywall in paywalls where product == nil {
        product = paywall.products.first { product in
          return product.productId == productId && (
            (
              paywallId?.count ?? 0 == 0
            ) || product.paywallIdentifier == paywallId
          )
        }
      }

      guard let product = product else {
        reject("Error", "Product not found", nil);
        return
      }

      Apphud.purchase(product) { result in
        DispatchQueue.main.async {

          var response = [String: Any]()

          response["success"] = result.error == nil

          let sub = result.subscription.map {
            DataTransformer.apphudSubscription(subscription: $0)
          }
          let non = result.nonRenewingPurchase.map {
            DataTransformer.nonRenewingPurchase(nonRenewingPurchase: $0)
          }

          if let skError = result.error as? SKError, skError.code == .paymentCancelled {
            response["userCanceled"] = NSNumber(booleanLiteral: true)
          }

          if let sub = sub {
            response["subscription"] = sub
          }
          if let non = non {
            response["nonRenewingPurchase"] = non
          }

          if let err = result.error as? NSError {
            response["error"] = [
              "code": err.code,
              "message": err.localizedDescription,
            ]
          }

          if let transaction = result.transaction {
            response["appStoreTransaction"] = [
              "state": transaction.transactionState.rawValue,
              "id": transaction.transactionIdentifier as Any,
              "date": transaction.transactionDate?.timeIntervalSince1970 as Any,
              "productId": transaction.payment.productIdentifier
            ]
          }

          resolve(response);
        }
      }
    }
  }
   
  @objc(paywalls:withRejecter:)
  func paywalls(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    Task {
      let paywalls = await paywalls()
      resolve(
        paywalls.map({ paywall in
          return paywall.toMap();
        })
      );
    }
  }

  @objc(paywallShown:)
  func paywallShown(identifier: String) {
    print("Paywall Shown: \(identifier)")
    Task {
      if let paywall = await paywalls().first(
        where: { $0.identifier == identifier
        }) {
        Apphud.paywallShown(paywall)
      }
    }
  }

  @objc(paywallClosed:)
  func paywallClosed(identifier: String) {
    Task {
      if let paywall = await paywalls().first(
        where: { $0.identifier == identifier
        }) {
        Apphud.paywallClosed(paywall)
      }
    }
  }

  @MainActor @objc(subscription:withRejecter:)
  func subscription(resolve: RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    guard let subscription = Apphud.subscription() else {
      reject("Error", "User has no subscriptions", nil)
      return
    }

    resolve(DataTransformer.apphudSubscription(subscription: subscription));
  }

    
  @MainActor @objc(subscriptions:withRejecter:)
  func subscriptions(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    let subs = Apphud.subscriptions() ?? []
    let array: Array = subs.map {
      DataTransformer.apphudSubscription(subscription: $0)
    }
    resolve(array as NSArray)
  }

  @MainActor @objc(isNonRenewingPurchaseActive:withResolver:withRejecter:)
  func isNonRenewingPurchaseActive(productIdentifier: String, resolve: RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    resolve(
      Apphud.isNonRenewingPurchaseActive(productIdentifier: productIdentifier)
    );
  }

  @MainActor @objc(nonRenewingPurchases:withRejecter:)
  func nonRenewingPurchases(resolve: RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    let purchases = Apphud.nonRenewingPurchases() ?? []
    let array: Array = purchases.map {
      DataTransformer.nonRenewingPurchase(nonRenewingPurchase: $0)
    }
    resolve(array)
  }
    
  @MainActor @objc(restorePurchases:withRejecter:)
  func restorePurchases(resolve: @escaping RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    Apphud.restorePurchases { (subscriptions, purchases, error) in
      resolve([
        "subscriptions": subscriptions?
          .map{ DataTransformer.apphudSubscription(subscription: $0) } as Any,
        "purchases": purchases?.map {
          [
            "productId": $0.productId,
            "canceledAt": $0.canceledAt?.timeIntervalSince1970 as Any,
            "purchasedAt": $0.purchasedAt.timeIntervalSince1970 as Any
          ]
        } as Any,
        "error": error?.localizedDescription as Any,
      ])
    }
  }
    
  @MainActor @objc(userId:withRejecter:)
  func userId(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    resolve(
      Apphud.userID()
    );
  }
    
  @objc(addAttribution:)
  func addAttribution(options: NSDictionary) {

    let data = options["data"] as? [AnyHashable : Any]
    let identifier = options["identifier"]  as? String
    let providerString = options["attributionProviderId"] as? String
    let provider: ApphudAttributionProvider
    switch providerString {
    case "appsFlyer":
      provider = .appsFlyer
    case "adjust":
      provider = .adjust
    case "appleSearchAds":
      provider = .appleAdsAttribution
    case "firebase":
      provider = .firebase
    default:
      return
    }

    Apphud
      .addAttribution(data: data, from: provider, identifer: identifier) {
        _ in
      }
  }

  @objc(setUserProperty:)
  func setUserProperty(options: NSDictionary) {
    guard let key = options["key"] as? String else {return}
        
    let value = options["value"]
    let setOnce: Bool = (options["setOnce"] as? Bool) ?? false
    let _key = ApphudUserPropertyKey.init(key)
    Apphud.setUserProperty(key: _key, value: value, setOnce: setOnce)
  }
    
  @objc(incrementUserProperty:)
  func incrementUserProperty(options: NSDictionary) {
    guard let key = options["key"] as? String, let by = options["by"] else {
      return
    }

    let _key = ApphudUserPropertyKey.init(key)
    Apphud.incrementUserProperty(key: _key, by: by)
  }

  @MainActor @objc(syncPurchasesInObserverMode:withRejecter:)
  func syncPurchasesInObserverMode(resolve: @escaping RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    Apphud.restorePurchases { _, _, _ in
      resolve(true)
    }
  }

  @objc(setAdvertisingIdentifier:)
  func setAdvertisingIdentifier(idfa: String) {
    Apphud
      .setDeviceIdentifiers(
        idfa: idfa,
        idfv: UIDevice.current.identifierForVendor?.uuidString
      )
  }

  @objc(enableDebugLogs)
  func enableDebugLogs() {
    ApphudUtils.enableAllLogs()
  }

  @objc(optOutOfTracking)
  func optOutOfTracking() {
    Apphud.optOutOfTracking()
  }

  @objc(collectDeviceIdentifiers)
  func collectDeviceIdentifiers() {
    // do nothing
  }

  @objc(submitPushNotificationsToken:)
  func submitPushNotificationsToken(token:String) {
    Apphud.submitPushNotificationsTokenString(string: token, callback: nil)
  }

  @objc(handlePushNotification:)
  func handlePushNotification(apsInfo: NSDictionary) -> Void {
    if let payload = apsInfo as? [AnyHashable: Any] {
      DispatchQueue.main.async {
        Apphud.handlePushNotification(apsInfo: payload)
      }
    }
  }

  @objc(checkEligibilitiesForIntroductoryOffer:withResolver:withRejecter:)
  func checkEligibilitiesForIntroductoryOffer(productIdentifier: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
      Apphud.fetchProducts { products, error in 
          let product = products.first { $0.productIdentifier == productIdentifier };
        
          if (product == nil) {
              reject("Error", "Product not found", nil);
              return;
          }
            
          Apphud.checkEligibilityForIntroductoryOffer(product: product!, callback: { result in
              resolve(result)
          })
      }
  }
  
  @MainActor @objc(attributeFromWeb:withResolver:withRejecter:)
  func attributeFromWeb(
    data: [AnyHashable: Any],
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock) {
      Apphud.attributeFromWeb(data: data) { success, user in
      
        var result: [String: Any] = [:]
      
        if let userId = user?.userId {
          result["user_id"] = userId
        }
      
        result["is_premium"] = Apphud.hasPremiumAccess()
        result["result"] = success
      
        resolve(result)
      }
    }
}
