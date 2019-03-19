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
    /// 内嵌枚举
    enum Section: Int {
        case input = 0, todos, max
    }
    /// 内嵌结构体（将两个变量进行简单地封装）
    struct State {
        let todos: [String]
        let text:String
    }
    // 这样就有一个统一按照状态更新UI的地方了
    var state = State(todos: [], text: "") {
        didSet {
            if oldValue.todos != state.todos {
                tableView.reloadData()
                title = "TODO - (\(state.todos.count))"
            }
            
            if oldValue.text != state.text {
                let isItemLengthEnough = state.text.count >= 3
                navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
                
                let inputIndexPath = IndexPath(item: 0, section: Section.input.rawValue)
                let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell
                inputCell?.textFiled.text = state.text
            }
            // 这里我们将新值和旧值进行了一些比较，以避免不必要的UI更新，就可以将原来的UI操作换成对state的操作了
        }
        
    }
    
    var todos = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let pressedBtn = UIButton(type: .contactAdd)
        pressedBtn.isEnabled = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: pressedBtn)
        pressedBtn.addTarget(self, action: #selector(addButtonPressed(_:)), for: .touchUpInside)
        
        // 变更前
       /* ToDoStore.shared.getToDoItems { (data) in
            self.todos += data
            self.title = "TODO - (\(self.todos.count))"
            self.tableView.reloadData()
        }*/
        // 变更后
        ToDoStore.shared.getToDoItems { (data) in
            self.state = State(todos: self.state.todos + data, text: self.state.text)
        }
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "reuseIdentifier")
    }
    
    // 添加代办
    @objc func addButtonPressed(_ btn: UIButton) {
        // 变更前
        /*let inputIndexPath = IndexPath(row: 0, section: Section.input.rawValue)
        guard let inputcell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell, let text = inputcell.textFiled.text else {
            return
        }
        todos.insert(text, at: 0)
        inputcell.textFiled.text = ""
        title = "TODO - (\(todos.count))"
        tableView.reloadData()*/
        // 变更后
        state = State(todos: [state.text] + state.todos, text: "")
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
        // 变更前
        /*guard indexPath.section == Section.todos.rawValue else {
            return
        }
        todos.remove(at: indexPath.row)
        title = "TODO - (\(todos.count))"
        tableView.reloadData()*/
        // 变更后
        guard indexPath.section == Section.todos.rawValue else {
            return
        }
        let newTodos = Array(state.todos[..<indexPath.row] + state.todos[(indexPath.row + 1)...])
        state = State(todos: newTodos, text: state.text)
    }
}

extension TableViewController: TableViewInputCellDelegate {
    func inputChanged(cell: TableViewInputCell, text: String) {
        // 变更前
        /*let isItemLengthEnough = text.count >= 3
        navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough*/
        // 变更后
        state = State(todos: state.todos, text: text)
    }
    
    /*测试State View Controller
     在基于state的实现下，用户的操作被统一为状态的变更，而状态的变更将统一地4去更新当前的UI.这让View Controller的测试变得容易的多。我们可以将本来混杂在一起的行为分离开来:首先，测试状态变更可以导致正确地UI;然后，测试用户输入可以导致正确地状态变更，这样即可覆盖View Controller的测试。
     */
    // 先测试状态变更导致的UI变化，在单元测试中：
    func testSettingState() {
        // 初始状态
//        XCTAssertEqual()
    }
}

