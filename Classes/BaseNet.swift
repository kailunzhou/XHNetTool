import Foundation
import Alamofire

open class BaseNet: NSObject {
    ///一般接口处理
    public func netRequest(urlStr: String, method: HTTPMethod, params: [String : Any]?, beginDeal: @escaping ()->(), endDeal: @escaping ()->(), success: @escaping (_ response : [String : Any])->(), failture: @escaping (_ error : Error?)->()) {
        if proxyStatus() {return}
        let header: HTTPHeaders = [
            "Authorization": "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==",
            "Accept": "application/json"
        ]
        var param: [String: Any] = [:]
        if let paramss = params {
            param = paramss
        }
        param["userId"] = "11111111111"
        param["sign"] = "AGFSDFRTGF56GTS"
        param["timeStamp"] = getTimeStamp()
        beginDeal()
        Alamofire.request(urlStr, method: method, parameters: param, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            endDeal()
            switch response.result {
            case .success:
                guard let successDic = response.result.value as? [String: Any] else {
                    failture(nil)
                    return
                }
                let jsonStr = successDic.showJsonString
                #if DEBUG
                print("\n请求链接:\(urlStr)\n请求参数:\(param)\n请求结果:\(jsonStr)")
                #endif
                success(successDic)
            case .failure(let error):
                failture(error)
            }
        }
    }
    ///图片上传处理
    public func picRequest(urlStr : String, params:[String: String]?, images: [UIImage], name: [String], beginDeal: @escaping ()->(), endDeal: @escaping ()->(), success : @escaping (_ response : [String : Any])->(), failture : @escaping (_ error : Error?)->()) {
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
        }, to: urlStr, headers: header, encodingCompletion: { (encodingResult) in
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

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
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
