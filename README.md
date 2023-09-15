# FFIAPManager
##### 苹果内购封装， 轻松实现Apple Pay

**第一步**

```
/// 第一步 请求可销售的商品数据 传入档位产品id数组
iapManager.reqestProducts(with: ["xxx1", "xxx2", "xxx3"])
```

**第二步**

```
/// 第二步 购买商品
iapManager.buyProduct(with: "xxx1")
```

**恢复购买**

```
/// 恢复购买
iapManager.restoreProduct()
```



**代理方法**

```
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
```

