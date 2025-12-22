import Foundation
import UIKit

@objc(PaywallScreenViewManager)
class PaywallScreenViewManager : RCTViewManager {
  override func view() -> UIView! {
    return PaywallScreenView()
  }
  
  override class func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  @objc func reload(_ reactTag: NSNumber) {
    if let view = bridge.uiManager.view(forReactTag: reactTag) as? PaywallScreenView {
      view.reload()
    }
  }
}
