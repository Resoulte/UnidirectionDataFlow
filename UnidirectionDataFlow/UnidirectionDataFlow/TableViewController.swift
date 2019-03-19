//
//  TableViewController.swift
//  UnidirectionDataFlow
//
//  Created by 师飞 on 2019/3/19.
//  Copyright © 2019年 师飞. All rights reserved.
//
/*
 上面的数组长度为3，如果我们在开发过程中由于某些原因，在使用上面的数组时写成了 array[100] 就会报数组越界错误，程序崩溃。
 
 　　　　在 OC 中数组越界输出的错误信息为:*** Terminating app due to uncaught exception 'NSRangeException',reason: '*** -[__NSArrayI objectAtIndex:]:index 100 beyond bounds [0 .. 2]'
 
 　　　　在 Swift 中为 fatal error: Array index out of range
 
 　　　　在调试时我们可以用断言来排除类似这样的问题，但是断言只会在 Debug 环境中有效，而在 Release 编译中所以变得断言都将被禁用。所以我们会考虑以产生致命错误(fatalError)的方式来种植程序
 */

import UIKit

class TableViewController: UITableViewController {
    // 内嵌枚举
    enum Section: Int {
        case input = 0, todos, max
    }
    var todos = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let pressedBtn = UIButton(type: .contactAdd)
        pressedBtn.isEnabled = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: pressedBtn)
        pressedBtn.addTarget(self, action: #selector(addButtonPressed(_:)), for: .touchUpInside)
        ToDoStore.shared.getToDoItems { (data) in
            self.todos += data
            self.title = "TODO - (\(self.todos.count))"
            self.tableView.reloadData()
        }
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "reuseIdentifier")
    }
    
    // 添加代办
    @objc func addButtonPressed(_ btn: UIButton) {
        let inputIndexPath = IndexPath(row: 0, section: Section.input.rawValue)
        guard let inputcell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell, let text = inputcell.textFiled.text else {
            return
        }
        todos.insert(text, at: 0)
        inputcell.textFiled.text = ""
        title = "TODO - (\(todos.count))"
        tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.max.rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            fatalError()
        }
        switch section {
        case .input:
            return 1
        case .todos:
            return todos.count
        case .max:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {
        case .input:
            print("返回input cell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewInputCell", for: indexPath) as! TableViewInputCell
            cell.delegate = self
            return cell
        case .todos:
            print("返回todo item cell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            cell.textLabel?.text = todos[indexPath.row]
            return cell
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 移除代办
        guard indexPath.section == Section.todos.rawValue else {
            return
        }
        todos.remove(at: indexPath.row)
        title = "TODO - (\(todos.count))"
        tableView.reloadData()
    }
}

extension TableViewController: TableViewInputCellDelegate {
    func inputChanged(cell: TableViewInputCell, text: String) {
        let isItemLengthEnough = text.count >= 3
        navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
    }
}

/*
 1.UI 相关的代码散落各处 - 重载 tableView 和设置 title 的代码出现了三次，设置右上 button 的 isEnabled 的代码存在于 extension 中，添加新项目时我们先获取了输入的 cell，然后再读取 cell 中的文本。这些散落在各处的 UI 操作将会成为隐患，因为你可能在代码的任意部分操作这些 UI，而它们的状态将随着代码的复杂变得“飘忽不定”。
 2.因为 1 的状态复杂，使得 View Controller 难以测试 - 举个例子，如果你想测试 title 的文字正确，你可能需要手动向列表里添加一个待办事项，这涉及到调用 addButtonPressed，而这个方法需要读取 inputCell 的文本，那么你可能还需要先去设置这个 cell 中 UITextField 的 text 值。当然你也可以用依赖注入的方式给 add 方法一个文本参数，或者将 todos.insert 和之后的内容提取成一个新的方法，但是无论怎么样，对于 model 的操作和对于 UI 的更新都没有分离 (因为毕竟我们写的就是“胶水代码”)。这正是你觉得 View Controller 难以测试的最主要原因。
 3.因为 2 的难以测试，最后让 View Controller 难以重构 - 状态和 UI 复杂度的增加往往会导致多个 UI 操作维护着同一个变量，或者多个状态变量去更新同一个 UI 元素。不论是哪种情况，都让测试变得几乎不可能，也会让后续的开发人员 (其实往往就是你自己！) 在面对复杂情况下难以正确地继续开发。Massive View Controller 最终的结果常常是牵一发而动全身，一个微小的改动可能都需要花费大量的时间进行验证，而且还没有人敢拍胸脯保证正确性。这会让项目逐渐陷入泥潭。

 */
