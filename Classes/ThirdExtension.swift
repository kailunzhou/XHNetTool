import Foundation
import MBProgressHUD

public extension MBProgressHUD {
    static func rootView(_ view: UIView?) -> UIView {
        if let views = view {
            return views
        } else {
            if #available(iOS 13.0, *) {
                return UIApplication.shared.windows.filter {$0.isKeyWindow}.first!
            } else {
                return UIApplication.shared.keyWindow!
            }
        }
    }
    
    static func showLoading(_ view: UIView?, with title: String?) {
        let hud = MBProgressHUD.showAdded(to: rootView(view), animated: true)
        hud.contentColor = .white
        hud.bezelView.style = .solidColor
        hud.bezelView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        hud.removeFromSuperViewOnHide = true
        if let text = title {
            hud.label.text = text
            hud.label.font = UIFont.systemFont(ofSize: 13)
        }
    }
    
    static func dismisHUD(_ view: UIView?) {
        MBProgressHUD.forView(rootView(view))?.hide(animated: true)
    }
    
    static func showMessage(_ view: UIView?,
                            with title: String,
                            complete handler: (() -> Void)?) {
        let hud = MBProgressHUD.showAdded(to: rootView(view), animated: true)
        hud.contentColor = .white
        hud.bezelView.style = .solidColor
        hud.bezelView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        hud.removeFromSuperViewOnHide = true
        hud.mode = .text
        hud.label.text = title
        hud.label.font = UIFont.systemFont(ofSize: 13)
        //hud.margin = 10
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            dismisHUD(view)
            handler?()
        }
    }
    
    private static func showHUD(_ view: UIView?,
                                with icon: UIImage?,
                                to title: String?,
                                complete handler: (() -> Void)?) {
        let hud = MBProgressHUD.showAdded(to: rootView(view), animated: true)
        hud.contentColor = .white
        hud.bezelView.style = .solidColor
        hud.bezelView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        hud.removeFromSuperViewOnHide = true
        hud.mode = .customView
        let iconImgv = UIImageView(image: icon)
        hud.customView = iconImgv
        if let text = title {
            hud.label.text = text
            hud.label.numberOfLines = 0
            hud.label.font = UIFont.systemFont(ofSize: 13)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            dismisHUD(view)
            handler?()
        }
    }
    
    static func showSuccess(_ view: UIView?,
                            with title: String?,
                            complete handler: (() -> Void)?) {
        showHUD(view, with: UIImage(named: "state_right"), to: title, complete: handler)
    }
    
    static func showFailure(_ view: UIView?,
                            with title: String?,
                            complete handler: (() -> Void)?) {
        showHUD(view, with: UIImage(named: "state_cancel"), to: title, complete: handler)
    }
}
