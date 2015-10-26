//
//  ViewController.swift
//  socket.chat
//
//  Created by 刘伟 on 15/10/22.
//  Copyright © 2015年 刘伟. All rights reserved.
//

import UIKit

public class message: AnyObject {
    var nickname: String
    var content: String
    public init(nickname: String, content: String) {
        self.nickname = nickname;
        self.content = content;
    }
}

class ViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textInput: UITextField!
    var dataArray: NSMutableArray?
    let socket = SocketIOClient(socketURL: "10.10.16.184:3000")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.dataArray = NSMutableArray()
        self.addHandlers()
        self.socket.connect()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidShow:"), name:UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil)
        
    }
    
    deinit {
        // 删除键盘监听
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func addHandlers() {
        self.socket.on("need_nickname") {[weak self] data, ack in
            self?.showLogin()
        }
        
        self.socket.on("user_welcome") {[weak self] data, ack in
            self?.addServerMessage("\(data) 欢迎你进入聊天室")
        }
        
        self.socket.on("user_join") {[weak self] data, ack in
            self?.addServerMessage("\(data) 进入了聊天室")
        }
        
        self.socket.on("user_quit") {[weak self] data, ack in
            self?.addServerMessage("\(data) 离开了聊天室")
        }
        
        self.socket.on("user_say") {[weak self] data, ack in
            let nickname = String(data[0])
            let content = String(data[1])
            self?.addMessage(nickname, content: content)
        }
    }
    
    func showLogin() {
        let alert = UIAlertController(title: "", message: "请设置聊天昵称", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel) {
            (action: UIAlertAction!) -> Void in
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: nil)
        }
        let okAction = UIAlertAction(title: "好的", style: UIAlertActionStyle.Default) {
            (action: UIAlertAction!) -> Void in
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: nil)
            if let textField = alert.textFields?.first {
                self.applyNickname(textField.text!)
            }
        }
        okAction.enabled = false
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
            textField.placeholder = "请输入昵称"
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("alertTextFieldDidChange:"), name: UITextFieldTextDidChangeNotification, object: textField)
        }
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func applyNickname(nickname: String?) {
        if nickname != nil {
            self.socket.emit("set_nickname", nickname!)
        }
    }
    
    func addServerMessage(content: String) {
        let msg = message(nickname: "系统消息", content: content)
        self.dataArray!.addObject(msg)
        self.tableView.reloadData()
        self.scrollToBottom()
    }
    
    func addMessage(nickname: String, content: String) {
        let msg = message(nickname: nickname, content: content)
        self.dataArray!.addObject(msg)
        self.tableView.reloadData()
        self.scrollToBottom()
    }
    
    func scrollToBottom() {
        if self.dataArray!.count > 0 {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.dataArray!.count-1, inSection:0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
    }
    
    @IBAction func send(sender: AnyObject) {
        if self.textInput.text != "" {
            self.socket.emit("say", self.textInput.text!)
            self.textInput.text = "";
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func alertTextFieldDidChange(notification: NSNotification){
        let alertController: UIAlertController? = self.presentedViewController as? UIAlertController
        if alertController != nil {
            let textField = alertController!.textFields?.first
            let okAction = alertController!.actions.last
            if textField != nil && okAction != nil {
                okAction!.enabled = textField!.text?.characters.count > 0
            }
        }
    }
    
    /// 监听键盘弹出
    func keyboardWillShow(notification: NSNotification) {
        let info  = notification.userInfo!
        let value: NSValue = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
        
        let keyboardFrame: CGRect = value.CGRectValue()
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, keyboardFrame.origin.y)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        self.scrollToBottom()
    }
    
    /// 监听键盘收回
    func keyboardWillHide(notification: NSNotification) {
        let info  = notification.userInfo!
        let value: NSValue = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
        
        let keyboardFrame: CGRect = value.CGRectValue()
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, keyboardFrame.origin.y)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.view.endEditing(false)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("chatCell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "chatCell")
        }
        let msg = self.dataArray!.objectAtIndex(indexPath.row) as! message
        cell!.textLabel?.text = "\(msg.nickname): \(msg.content)"
        return cell!
    }

}

