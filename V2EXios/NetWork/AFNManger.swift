//
//  AFNManger.swift
//  V2EXios
//
//  Created by 王浩 on 2017/6/20.
//  Copyright © 2017年 haowang. All rights reserved.
//

import Foundation
import SwiftyJSON
import AFNetworking
import MBProgressHUD


class AFN : NSObject {
    class var sharedState : AFN {
        struct Static {
            static let instance = AFN()
        }
        return Static.instance
    }
    fileprivate lazy var WHAFN : AFHTTPSessionManager  = {
        let afn = AFHTTPSessionManager(baseURL: URL(string: UrlRoute.rootUrl))
        afn.requestSerializer.timeoutInterval = 10
        afn.responseSerializer.acceptableContentTypes = NSSet(objects: "application/json","text/plain","text/json","text/html","multipart/form-data","image/jpeg", "image/png") as? Set<String>
        afn.requestSerializer.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return afn
    }()
    private var namespace : String!{
        return Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
    }
    
    /// post请求
    ///
    /// - Parameters:
    ///   - url: <#url description#>
    ///   - parameter: <#parameter description#>
    ///   - isNeed:
    ///   - dataCompletionHandler: <#dataCompletionHandler description#>
    func postRequestData(url:String,parameter:[String:Any],model:String,dataCompletionHandler:@escaping (Int,Any)->Void){
        MBProgressHUD.showLoading()
        WHAFN.post(url, parameters: parameter, progress: nil, success: {
            [weak self]  task,value in
            print("====>requesturl",task.currentRequest?.url)
            
            print("====>requestBody",parameter)
            
            let result = JSON(value)
            
            let get_error = self?.fromReturnData(result: result)
            guard get_error == nil else {
                self?.showError(error: get_error!)
                return
            }
            
            let get_result =  self?.detailWithRequestJSON(json: result, model: model)
            dataCompletionHandler((get_result?.0)!, get_result?.1)
            
            }, failure: {
                task,error in
                print(error)
                self.showError(error: error as NSError)
                
        })
        
    }
    
    /// get方法
    ///
    /// - Parameters:
    ///   - url: url
    ///   - model: 模型类型
    ///   - dataCompletionHandler: <#dataCompletionHandler description#>
    func getRequestData(url:String,model:String,dataCompletionHandler:@escaping (Int,Any)->Void){
        WHAFN.get(url, parameters: nil, progress: nil, success: {
            [weak self]  task,value in
            print("====>requesturl",task.currentRequest?.url ?? url)
            
            let result = JSON(value)
            
            let get_error = self?.fromReturnData(result: result)
            
            guard get_error == nil else {
                self?.showError(error: get_error!)
                return
            }
            
            let get_result =  self?.detailWithRequestJSON(json: result, model: model)
            dataCompletionHandler((get_result?.0)!, get_result?.1)
            }, failure: {
                task ,Error in
                print(Error)
                self.showError(error: Error as NSError)
        })
    }
    
    /// 登录接口
    ///
    /// - Parameters:
    ///   - parmaters: <#parmaters description#>
    ///   - CompletHander: <#CompletHander description#>
//    func login(parmaters:[String:Any],CompletHander:@escaping(Bool,String)->Void){
//        
//        WHAFN.sharedManger.post(Config.loginUrl, parameters: parmaters, progress: nil, success: {
//            [weak self]    task,value in
//            print("====>requesturl",task.currentRequest?.url ?? "")
//            print("====>requestBody",parmaters)
//            let result = JSON(value)
//            let get_error = self?.fromReturnData(result: result)
//            
//            guard get_error == nil else {
//                self?.showError(error: get_error!)
//                return
//            }
//            LoginModel.mr_truncateAll()
//            let model : LoginModel = operateData.newObj()
//            model.mr_importValuesForKeys(with: result["result"].dictionaryObject)
//            operateData.save()
//            User.sharedState.loginModel = model
//            WHAFN.sharedManger.setHeader()
//            CompletHander(true, "登录成功")
//            
//            }, failure: {
//                task,error in
//                print(error)
//                self.showError(error: error as NSError)
//                
//        })
//        
//    }
    //上传图片
//    func uploadImage(url:String,parmaters:[String:Any],photos:[UIImage],dataCompletionHandler:@escaping (Int,Any)->Void) {
//        MBProgressHUD.showLoading()
//        weak var weakself = self
//        WHAFN.post(url, parameters: parmaters, constructingBodyWith: {
//            formdata in
//            var i = 0
//            for sub in photos {
//                let image =  UIImageJPEGRepresentation(sub, 0.5)
//                let file_name = currentTime() + "\(i).jpeg"
//                formdata.appendPart(withFileData: image!, name: "imageFiled\(i)", fileName:file_name  , mimeType: "image/jpeg")
//                i += 1
//            }
//            
//        }, progress: {
//            uploadProgress in
//            print("--->图片上传进度:",uploadProgress)
//        }, success: {
//            task , value in
//            
//            print("====>requesturl",task.currentRequest?.url ?? "")
//            print("====>requestBody",parmaters)
//            let result = JSON(value)
//            let get_error = weakself?.fromReturnData(result: result)
//            guard get_error == nil else {
//                weakself?.showError(error: get_error!)
//                return
//            }
//            dataCompletionHandler(1,"提交成功")
//            
//        }, failure: {
//            task ,error in
//        })
//        
//        
//    }
    
    
    
    /// 处理json数据
    ///
    /// - Parameters:
    ///   - json: <#json description#>
    ///   - model: <#model description#>
    /// - Returns: <#return value description#>
    private func detailWithRequestJSON(json:JSON,model:String)->(Int,Any) {
        let calss   = objc_getClass(model) as? BaseModel.Type
        guard (calss != nil)  else {
            print(model,"===>当前模型传入有误")
            return (-1,"")
        }
        switch json.type {
        case .array:
            let data_array = self.transformDataToModel(data: json.array ?? [], model: model)
            return (data_array.count,data_array)
        case .dictionary:
           
            var new_data = calss?.mr_createEntity()
            if let store_data = calss?.mr_find(byAttribute: "id", withValue: json["id"].int){
                 new_data = store_data.first as! BaseModel?
            }
            new_data?.mr_importValuesForKeys(with: json.dictionaryObject)
            return (1,new_data)
            
        default:
            break
        }
        return (-1,"哥,这回真的没有了")
    }
    
    
    /// 转模型
    ///
    /// - Parameter data: <#data description#>
    /// - Returns: <#return value description#>
    private func transformDataToModel(data:[JSON],model:String)->[Any]{
        var dataArray : [Any] = []
        let calss   = objc_getClass(model) as? BaseModel.Type
        for sub in data {
            let new  = calss?.mr_createEntity()
            new?.mr_importValuesForKeys(with: sub.dictionaryObject)
            dataArray.append(new!)
        }
        return dataArray
    }
    
    /// 检查请求状态
    ///
    /// - Parameters:
    ///   - task: <#task description#>
    ///   - result: <#result description#>
    /// - Returns: <#return value description#>
    private func fromReturnData(result:JSON)->NSError?{
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
            MBProgressHUD.hideHUD()
        })
        print("====>result",result)
        var error : NSError?
        if  let isSucess = result["status"].string  {
            if !(isSucess == "notfound") {
                let msg = result["msg"].string ?? "未知错误"
                error = NSError(domain: NSOSStatusErrorDomain, code: 400, userInfo: [NSLocalizedFailureReasonErrorKey:msg])
            }
        }
//        else {
//            error = NSError(domain: NSOSStatusErrorDomain, code: 400, userInfo: [NSLocalizedFailureReasonErrorKey:"发生异常请检查网络或API"])
//        }
        return error
    }
    
    /// 抛出异常
    ///
    /// - Parameter error: <#error description#>
    private func showError(error : NSError) {
        MBProgressHUD.hideHUD()
        
        let userInfo = error.userInfo
        var errorMsg : String?
        if let msg = userInfo[NSLocalizedFailureReasonErrorKey]{
            errorMsg = msg as? String ?? "未知原因"
        }
        else if let msg = userInfo[NSLocalizedRecoverySuggestionErrorKey]{
            errorMsg = msg as? String ?? "未知原因"
        }
        else {
            errorMsg = error.localizedDescription
        }
        
        if errorMsg == "NOT_LOGIN" {
//            requireLogin()
        }
        MBProgressHUD.showText(errorMsg ?? "网络好像有问题")
        
    }
    
    
}
