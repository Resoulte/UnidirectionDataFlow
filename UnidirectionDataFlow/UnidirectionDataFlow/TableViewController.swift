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
// 这种基于State的View Controller虽然比原来好了很多，但是依然存在一些问题，也还有大量的改进空间
/*
 1.state的didSet不会在controller初始化中首次赋值时被调用。理想状态下，UI的更新应该只和输入有关，而与当前状态无关（也就是“纯函数式”）
 2.State难以扩展
 3.Data Source重用
 4.异步操作的测试
 */

import UIKit
import Foundation

// 为了能够尽量通用，先定义几个协议;除了限制类型以外，这几个protocol并没有其他特别的意义
protocol ActionType {}
protocol StateType {}
protocol CommandType {}

// 这个Store接收一个reducer和一个初始状态initialState作为输入。它提供了dispatch方法，持有该store的类型可以通过dispatch向其发送Action, store将根据reducer提供的方式生产新的state和必要的command，然后通知它的订阅者
class Store<A: ActionType, S: StateType, C: CommandType> {
    let reducer: (_ state: S, _ action: A) -> (S, C?)
    
    var subsciber: ((_ state: S, _ previousState: S, _ command: C?) -> Void)?
    var state: S
    
    init(reducer: @escaping (S, A) -> (S, C?), initialState: S) {
        self.reducer = reducer
        self.state = initialState
    }
    
    func dispatch(_ action: A) {
        let previousState = state
        let (nextState, command) = reducer(state, action)
        state = nextState
        subsciber?(state, previousState, command)
    }
    
    func subscribe(_ handler: @escaping (S, S, C?) -> Void) {
        self.subsciber = handler
    }
    
    func unsubscribe() {
        self.subsciber = nil
    }
}


// 这是基本的将DataSource分离出View Controller的方法
class TableViewControllerDataSource: NSObject, UITableViewDataSource {
    /// 内嵌枚举
    enum Section: Int {
        case input = 0, todos, max
    }
    var todos: [String]
    weak var owner: TableViewController?
    init(todos: [String], owner: TableViewController?) {
        self.todos = todos
        self.owner = owner
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.max.rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {
        case .input:
            print("返回input cell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewInputCell", for: indexPath) as! TableViewInputCell
            cell.delegate = owner
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
}


class TableViewController: UITableViewController {
   
    /// 内嵌结构体
    // 为了将datasource提取出来，我们在State中把原来的todos换成了整个的datasource.TableViewControllerDataSource就是标准的UITableViewDataSource,它包含todos和用来作为inputcell设定delegate的owner.基本上就是将原来TableViewController的Data Source部分的代码搬过去
    struct State: StateType{
        var dataSource = TableViewControllerDataSource(todos: [], owner: nil)
        var text: String = ""
    }
    
    enum Action: ActionType {
        case updateText(text: String)
        case addToDos(items: [String])
        case removeToDo(index: Int)
        case loadToDos
    }
    
    // Command只是触发异步操作的手段，他不应该和状态变化有关，所以它没有出现在reducer的输入一侧
    // Command中包含的loadToDos成员，他关联了一个方法作为结束时的回调，我们稍后会在这个方法里向store发送.addToDos的Action
    enum Command: CommandType {
        case loadToDos(completion: ([String]) -> Void)
    }
    
    lazy var reducer: (State, Action) -> (state: State, command: Command?) = { [weak self] (state: State, action: Action) in
        var state = state
        var command: Command? = nil
        
        switch action {
        case .updateText(let text):
            state.text = text
            
        case .addToDos(let items):
            state.dataSource = TableViewControllerDataSource(todos: items + state.dataSource.todos, owner: state.dataSource.owner)
        case .removeToDo(let index):
            let oldTodos = state.dataSource.todos
            state.dataSource = TableViewControllerDataSource(todos: Array(oldTodos[..<index] + oldTodos[(index + 1)...]), owner: state.dataSource.owner)
        case .loadToDos:
            command = Command.loadToDos(completion: { (data) in
                // 发送额外的.addToDos
                self?.store.dispatch(.addToDos(items: data))
            })
        }
        return (state, command)
    }
    
    var store: Store<Action, State, Command>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let pressedBtn = UIButton(type: .contactAdd)
        pressedBtn.isEnabled = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: pressedBtn)
        pressedBtn.addTarget(self, action: #selector(addButtonPressed(_:)), for: .touchUpInside)
        
        let dataSource = TableViewControllerDataSource(todos: [], owner: self)
        store = Store<Action, State, Command>(reducer: reducer, initialState: State(dataSource: dataSource, text: ""))
        
        // 订阅store
        store.subscribe { [weak self] (state, previousState, command) in
            self?.stateDidChanged(state: state, previousState: previousState, command: command)
        }
        
        // 初始化UI
        stateDidChanged(state: store.state, previousState: nil, command: nil)
        
        // 开始异步加载
        store.dispatch(.loadToDos)
        
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "reuseIdentifier")
    }
    
    // 将stateDidChanged添加到store.subcribe后，每次store状态改变时，stateDidChanged都将被调用
    // 现在stateDidChanged是一个纯函数式的UI更新方法，它的输出（UI）只取决于输入的state和previousState.另一个输入Command负责触发一些不影响输出的“副作用”，在实践中，除了发送请求这样的异步操作外，View Controller的转换，弹窗之类的交互都可以通过Command来进行。Command本身不应该影响State的转换，它需要通过再次发送Action来改变状态，以此才能影响UI
    func stateDidChanged(state: State, previousState: State?, command: Command?) {
        if let command = command {
            switch command {
            case .loadToDos(let handler):
                ToDoStore.shared.getToDoItems(completionHandler: handler)
            }
        }
        
        if previousState == nil || previousState?.dataSource.todos != state.dataSource.todos {
            let dataSource = state.dataSource
            tableView.dataSource = dataSource
            tableView.reloadData()
            title = "TODO - (\(dataSource.todos.count))"
        }
        
        if previousState == nil || previousState?.text != state.text {
            let isItemLengthEnough = state.text.count >= 3
            navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
            
            let inputIndexPath = IndexPath(row: 0, section: TableViewControllerDataSource.Section.input.rawValue)
            let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell
            inputCell?.textFiled.text = state.text
        }
    }
    
    // 添加代办
    @objc func addButtonPressed(_ btn: UIButton) {
        // 优化后
        store.dispatch(.addToDos(items: [store.state
            .text]))
        store.dispatch(.updateText(text: ""))
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 移除代办
        // 优化后
        guard indexPath.section == TableViewControllerDataSource.Section.todos.rawValue else {
            return
        }
        store.dispatch(.removeToDo(index: indexPath.row))
    }
}

extension TableViewController: TableViewInputCellDelegate {
    func inputChanged(cell: TableViewInputCell, text: String) {
        // 优化后
        store.dispatch(.updateText(text: text))
    }
}

