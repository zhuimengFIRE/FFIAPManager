//
//  ViewController.swift
//  FFIAPDemo
//
//  Created by FFang on 2023/9/15.
//

import UIKit

class ViewController: UIViewController {
    
    private var iapManager = FFIAPManager.shared
    private var productIds = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        iapManager.delegate = self
        
        /// 第一步 请求可销售的商品数据 传入档位产品id数组
        iapManager.reqestProducts(with: ["xxx1", "xxx2", "xxx3"])
        
        /// 第二步 购买商品
        iapManager.buyProduct(with: "xxx1")
        
        /// 恢复购买
        iapManager.restoreProduct()
        
    }
}

extension ViewController: FFIAPManagerDelegate {
    /// 获取到可购买的商品数据
    func iapPayGotProducts(with productIds: [String]) {
        self.productIds = productIds
    }
    /// 购买成功
    func iapPaySuccess(with productId: String, transactionIdentifier: String) {
        
    }
    /// 购买失败
    func iapPayFailed(with productId: String) {
        
    }
    /// 恢复购买
    func iapPayRestore(with productIds: [String], transactionIds: [String]) {
        
    }
    /// 系统错误
    func iapSysWrong() {
        
    }
    /// 购买中
    func iapPayShowHud() {
        
    }
}

