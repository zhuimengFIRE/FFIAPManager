//
//  FFIAPManager.swift
//  FFTools
//
//  Created by FFang on 2023/6/27.
//

import Foundation
import StoreKit

#if DEBUG
let checkURL = "https://sandbox.itunes.apple.com/verifyReceipt"
#else
let checkURL = "https://buy.itunes.apple.com/verifyReceipt"
#endif

@objc protocol FFIAPManagerDelegate {
    /// 获取到可购买商品列表
    func iapPayGotProducts(with productIds: [String])
    /// 购买成功
    func iapPaySuccess(with productId: String, transactionIdentifier: String)
    /// 购买失败
    @objc optional func iapPayFailed(with productId: String)
    /// 恢复商品（仅限永久有效商品）
    @objc optional func iapPayRestore(with productIds: [String], transactionIds: [String])
    /// 加载
    @objc optional func iapPayShowHud()
    /// 系统错误
    @objc optional func iapSysWrong()
    /// 验证成功
    @objc optional func verifySuccess()
    /// 验证失败
    @objc optional func verifyFailed()
}

class FFIAPManager: NSObject {
    /// 单例
    static let shared = FFIAPManager()
    /// 可售商品字典
    private var productDic: Dictionary<String, SKProduct>?
    /// 代理
    weak var delegate: FFIAPManagerDelegate?
    
    /// 票据
    public var receiptString: String {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL, let receiptData = NSData(contentsOf: receiptUrl) else {
            return ""
        }
        let receiptString = receiptData.base64EncodedString(options: .endLineWithLineFeed)
        return receiptString
    }
    
    override init() {
        super.init()
        /// 添加购买队列监听
        SKPaymentQueue.default().add(self)
    }
    
    /// 询问苹果的服务器能够购买哪些商品
    func reqestProducts(with productIds: [String]) {
        let set = Set(productIds)
        let productsRequest = SKProductsRequest(productIdentifiers: set)
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    /// 购买商品
    func buyProduct(with productId: String) {
        guard let productDic = productDic, let product = productDic[productId] else {
            delegate?.iapSysWrong?()
            return
        }
        // 要购买商品，开个小票
        let payment = SKPayment(product: product)
        // 去收银台排队，准备购买
        SKPaymentQueue.default().add(payment)
    }
    
    /// 恢复商品 仅限永久有效商品
    func restoreProduct() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /// 支付成功后验证凭据 一般是交由服务器去验证
    func verifyPruchase(with productId: String) {
        // 从沙盒中获取到购买凭据
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return
        }
        guard let receiptData = try? Data(contentsOf: receiptURL) else {
            return
        }
        guard let url = URL(string: checkURL) else {
            return
        }
        // 发送网络POST请求，对购买凭据进行验证
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20.0)
        request.httpMethod = "POST"
        // BASE64 常用的编码方案，通常用于数据传输，以及加密算法的基础算法，传输过程中能够保证数据传输的稳定性
        // BASE64是可以编码和解码的
        let encodeStr = receiptData.base64EncodedString(options: .endLineWithLineFeed)
        let payload = String(format: "{\"receipt-data\" : \"%@\"}", encodeStr)
        let payloadData = payload.data(using: .utf8)
        request.httpBody = payloadData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (try? JSONSerialization.data(withJSONObject: data as Any, options: .fragmentsAllowed)) != nil {
                self.delegate?.verifySuccess?()
            }else {
                self.delegate?.verifyFailed?()
            }
        }.resume()
    }
}

extension FFIAPManager: SKProductsRequestDelegate {
    /// 获取到可销售商品
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if self.productDic == nil {
            self.productDic = Dictionary<String, SKProduct>()
        }
        var productArray = [String]()
        for product in response.products {
            self.productDic![product.productIdentifier] = product
            productArray.append(product.productIdentifier)
        }
        delegate?.iapPayGotProducts(with: productArray)
    }
}

extension FFIAPManager: SKPaymentTransactionObserver {
    /// 监测购买队列的变化,判断购买状态是否成功
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // 处理支付成功的逻辑
                delegate?.iapPaySuccess(with: transaction.payment.productIdentifier, transactionIdentifier: transaction.transactionIdentifier ?? "")
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                // 处理支付失败的逻辑
                delegate?.iapPayFailed?(with: transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                delegate?.iapPayRestore?(with: [transaction.payment.productIdentifier], transactionIds: [transaction.transactionIdentifier ?? ""])
                SKPaymentQueue.default().finishTransaction(transaction)
            case .purchasing:
                delegate?.iapPayShowHud?()
            default:
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            }
        }
    }
    
    /// 恢复购买回调
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        var productIds = [String]()
        var transactionIds = [String]()
        for transaction in queue.transactions {
            let productId = transaction.payment.productIdentifier
            let transactionId = transaction.original?.transactionIdentifier ?? ""
            productIds.append(productId)
            transactionIds.append(transactionId)
        }
        delegate?.iapPayRestore?(with: productIds, transactionIds: transactionIds)
    }
}
