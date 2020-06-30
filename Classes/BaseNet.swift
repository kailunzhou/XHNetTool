import Foundation
import Alamofire
import MBProgressHUD

open class BaseNet: NSObject {
    public static let `default` = BaseNet()
    
    public var tokenInvalid: (()->())?//token失效方法
    public var token: String?//token值
    public var service: String? //服务器地址
    /*
     用于：只需要传入data内参数的接口，而且都需要token
     urlStr: 接口地址拼接部分
     data: 传入data参数
     view: 当前的视图
     isParse: 返回的数据是否要先解析
     endAction: 请求完成就会调用的事件
     okAction: 解析完成调用的事件
     */
    public func BaseNetDataRequest(_ urlStr: String, _ data: [String: Any]?, _ view: UIView?, _ isParse: Bool, endAction: @escaping ()->(), okAction: @escaping (_ result: Any?)->()) {
        guard let tokens = token else {return}
        var param: [String: Any] = ["token": tokens]
        if let datas = data {
            param["data"] = datas
        }
        netRequest(urlStr: urlStr, method: .post, param: param, beginDeal: {
            MBProgressHUD.showLoading(view, with: nil)
        }, endDeal: {
            MBProgressHUD.dismisHUD(view)
        }, success: { (result) in
            endAction()
            if isParse {
                if let code = result["code"] as? Int {
                    switch code {
                    case 0:
                        if let data = result["data"] {
                            okAction(data)
                        } else {
                            okAction(nil)
                        }
                    case -100:
                        self.tokenInvalid?()
                    default:
                        if let msg = result["msg"] as? String {
                            MBProgressHUD.showMessage(view, with: msg, complete: nil)
                        }
                    }
                }
            } else {
                okAction(result)
            }
        }) { (err) in
        }
    }
    /*
    用于：1.不需要token传入 或者 2.有与token平级的其它参数传入 的接口
    urlStr: 接口地址拼接部分
    param: 传入参数
    view: 当前的视图
    isParse: 返回的数据是否要先解析
    endAction: 请求完成就会调用的事件
    okAction: 解析完成调用的事件
    */
    public func BaseNetParamRequest(_ urlStr: String, _ param: [String: Any]?, _ view: UIView?, _ isParse: Bool, endAction: @escaping ()->(), okAction: @escaping (_ result: Any?)->()) {
        netRequest(urlStr: urlStr, method: .post, param: param, beginDeal: {
            MBProgressHUD.showLoading(view, with: nil)
        }, endDeal: {
            MBProgressHUD.dismisHUD(view)
        }, success: { (result) in
            endAction()
            if isParse {
                if let code = result["code"] as? Int {
                    switch code {
                    case 0:
                        if let data = result["data"] {
                            okAction(data)
                        } else {
                            okAction(nil)
                        }
                    case -100:
                        self.tokenInvalid?()
                    default:
                        if let msg = result["msg"] as? String {
                            MBProgressHUD.showMessage(view, with: msg, complete: nil)
                        }
                    }
                }
            } else {
                okAction(result)
            }
        }) { (err) in
        }
    }
    /*
     urlStr: 接口地址拼接部分
     data: 传入参数
     images: 上传的图片
     view: 当前的视图
     okAction: 解析完成调用的事件
    */
    public func BaseNetPicRequest(_ urlStr: String, _ data: [String: String]?, _ images: [UIImage], _ view: UIView?, okAction: @escaping (_ fileUrl: String?)->()) {
        picRequest(urlStr: urlStr, params: data, images: images, name: [], beginDeal: {
            MBProgressHUD.showLoading(view, with: nil)
        }, endDeal: {
            MBProgressHUD.dismisHUD(view)
        }, success: { (result) in
            if let status = result["status"] as? Int {
                switch status {
                case 1:
                    if let fileUrl = result["fileUrl"] as? String {
                        okAction(fileUrl)
                    } else {
                        okAction(nil)
                    }
                default:
                    if let message = result["message"] as? String {
                        MBProgressHUD.showMessage(view, with: message, complete: nil)
                    }
                }
            }
        }) { (err) in
        }
    }
    /*
     可以本地自己对这个方法进行封装处理。
     */
    ///一般接口处理
    public func netRequest(urlStr: String, method: HTTPMethod, param: [String : Any]?, beginDeal: @escaping ()->(), endDeal: @escaping ()->(), success: @escaping (_ response : [String : Any])->(), failture: @escaping (_ error : Error?)->()) {
        guard let services = service else {return}
        if proxyStatus() {return}
        let header: HTTPHeaders = [
            "Authorization": "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==",
            "Accept": "application/json"
        ]
        var paramDic: [String: Any] = [:]
        if let params = param {
            paramDic = params
        }
        paramDic["userId"] = "11111111111"
        paramDic["sign"] = "AGFSDFRTGF56GTS"
        paramDic["version"] = "1.1"
        paramDic["timeStamp"] = getTimeStamp()
        beginDeal()
        Alamofire.request(services + urlStr, method: method, parameters: paramDic, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            endDeal()
            switch response.result {
            case .success:
                guard let successDic = response.result.value as? [String: Any] else {
                    failture(nil)
                    return
                }
                let jsonStr = successDic.showJsonString
                #if DEBUG
                print("\n请求链接:\(urlStr)\n请求参数:\(paramDic)\n请求结果:\(jsonStr)")
                #endif
                success(successDic)
            case .failure(let error):
                failture(error)
            }
        }
    }
    ///图片上传处理
    public func picRequest(urlStr : String, params:[String: String]?, images: [UIImage], name: [String], beginDeal: @escaping ()->(), endDeal: @escaping ()->(), success : @escaping (_ response : [String : Any])->(), failture : @escaping (_ error : Error?)->()) {
        guard let services = service else {return}
        if proxyStatus() {return}
        let header = ["content-type":"multipart/form-data"]
        beginDeal()
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            if let fileType = params?["fileType"], let fileTypeData = fileType.data(using: .utf8) {
                multipartFormData.append(fileTypeData, withName: "fileType")
            }
            for index in 0 ..< images.count {
                var arc = String()
                for _ in 0 ... 9 {
                    arc += "\(arc4random() % 9)"
                }
                multipartFormData.append(images[index].jpegData(compressionQuality: 0.3)!, withName: "file", fileName: "file\(arc).png", mimeType: "image/png")
            }
        }, to: services + urlStr, headers: header, encodingCompletion: { (encodingResult) in
            endDeal()
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { (response) in
                    guard let successDic = response.result.value as? [String: Any] else {
                        failture(nil)
                        return
                    }
                    let jsonStr = successDic.showJsonString
                    #if DEBUG
                    print("\n请求链接:\(urlStr)\n请求参数:\(params ?? [:])\n请求结果:\(jsonStr)")
                    #endif
                    success(successDic)
                }
            case .failure(let error):
                failture(error)
            }
        })
    }
    ///获取时间戳
    fileprivate func getTimeStamp() -> String {
        let formart = DateFormatter()
        formart.dateFormat = "yyyyMMddHHmmssSSS"
        let timeStamp = formart.string(from: Date())
        return timeStamp
    }
    ///判断是否代理
    fileprivate func proxyStatus() -> Bool {
        let dic = CFNetworkCopySystemProxySettings()!.takeUnretainedValue()
        let arr = CFNetworkCopyProxiesForURL(URL(string: "https://www.baidu.com")! as CFURL, dic).takeUnretainedValue()
        let obj = (arr as [AnyObject])[0]
//        let host = obj.object(forKey: kCFProxyHostNameKey) ?? "null"
//        let port = obj.object(forKey: kCFProxyPortNumberKey) ?? "null"
//        let type = obj.object(forKey: kCFProxyTypeKey) ?? "null"
//        delog("host = \(host)\nport = \(port)\ntype = \(type)")
        if obj.object(forKey: kCFProxyTypeKey) == kCFProxyTypeNone {
            return false//没有设置代理
        }else {
            return true//设置代理了
        }
    }
}

public extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var showJsonString: String {
        do {
            var dic: [String: Any] = [String: Any]()
            for (key, value) in self {
                dic["\(key)"] = value
            }
            let jsonData = try JSONSerialization.data(withJSONObject: dic, options: JSONSerialization.WritingOptions.prettyPrinted)

            if let data = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String? {
                return data
            } else {
                return "{}"
            }
        } catch {
            return "{}"
        }
    }
}


