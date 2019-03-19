//
//  ViewController.swift
//  UnidirectionDataFlow
//
//  Created by 师飞 on 2019/3/19.
//  Copyright © 2019年 师飞. All rights reserved.
/*基于 State 的 View Controller

通过提取 State 统合 UI 操作
上面的三个问题其实环环相扣，如果我们能将 UI 相关代码集中起来，并用单一的状态去管理它，就可以让 View Controller 的复杂度降低很多。我们尝试看看！

在这个简单的界面中，和 UI 相关的 model 包括待办条目 todos (用来组织 table view 和更新标题栏) 以及输入的 text (用来决定添加按钮的 enable 和添加 todo 时的内容)。我们将这两个变量进行简单的封装，在 TableViewController 里添加一个内嵌的 State 结构体：*/

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


}

