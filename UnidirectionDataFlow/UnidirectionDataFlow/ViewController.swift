//
//  ViewController.swift
//  UnidirectionDataFlow
//
//  Created by 师飞 on 2019/3/19.
//  Copyright © 2019年 师飞. All rights reserved.
//  单向数据流动的函数式View Controller
/* 这个项目可以从网络加载待办事项，我们通过输入文本进行添加，或者点击对应条目进行删除
打开应用后加载已有待办列表时花费了一些时间，一般来说，我们会从网络请求进行加载，这应该是一个异步操作。在示例项目里，我们不会真的去进行网络请求，而是使用一个本地存储来模拟这个过程。
标题栏的数字表示当前已有的待办项目，随着待办的增减，这个数字会相应变化。
可以使用第一个 cell 输入，并用右上角的加号添加一个待办。我们希望待办事项的标题长度至少为三个字符，在不满足长度的时候，添加按钮不可用。*/
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

