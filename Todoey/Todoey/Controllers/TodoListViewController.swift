//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!

    var itemArray = [Item]()
    
    //CategoryViewControllerのdestinationVC.selectedCategory = categoryArray[indexPath.row]が実行されるまで，空なのでoptional型
    var selectedCategory: Category? {
        //didSet: selectedCategoryに値が代入されるとblock内の処理を実行
        didSet {
            loadItems()//ここでloadItem()を実行するのでviewDidLoad()で実行する必要ない
        }
    }
        
    //.persitentContainer.viewContextはAppDelegateクラスのmethodだが，AppDelegate()とオブジェクトを生成せずに以下のように記述
    //shared: sigleton app instance
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    
    //UITableViewControllerでは，TableViewとは異なり，tableView.dataSource=selfやtableView.delegate=selfが必要ない（protocolにはdefaultで従っている）
    override func viewDidLoad() {
        super.viewDidLoad()

        //print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))//sqliteファイルが保存されているpathを出力
        
        searchBar.delegate = self
    }
    
    //MARK: - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAtIndexPath Called")//iterateするのでitemArrayの要素数分だけ呼び出される
        
        //UITableViewControllerではIBOutletを定義しなくてもdefaultでtableViewが定義されている
        let cell = tableView.dequeueReusableCell(withIdentifier: K.itemCellIdentifier, for: indexPath)
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        
        //Ternary opratorを用いてシンプルに記述
        cell.accessoryType = item.isChecked ? .checkmark : .none
        
        return cell
    }
    
    
    //MARK: - TableView Delegate Methods
    //cellをtapしたときに発火するmethod
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        //tapしたcellをdelete(contextにdeleteをcommitしてから，実際にitemArrayの要素をdeleteする）
//        context.delete(itemArray[indexPath.row])//indexPath.rowでitemArrayの要素をこの行で使っているので，仮にitemArray.removeで要素を削除してからcontext.deleteを行うと，commitするindexPathがおかしくなる
//        itemArray.remove(at: indexPath.row)
        
        //tapしたcellにcheckmarkをつける，すでにcheckmarkがついていたら外す
        itemArray[indexPath.row].isChecked = !itemArray[indexPath.row].isChecked//trueだったらfalseに反転

        self.saveItems()
        
        //cellをtapして選択した後，選択されてない状態にする＝tapしたら灰色になり，すぐ元に戻る
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Item
    //nav barのaddbuttonをtapしたときに，itemを追加するpopupを表示
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            //What will happen once the user clicks the Add Item button on our UIAlert
            
            let newItem = Item(context: self.context)//ItemはNSManagedObject型で各行のデータ
            //Attribute
            newItem.isChecked = false
            newItem.title = textField.text!
            newItem.parentCategory = self.selectedCategory
            
            //このブロックはcompletion handlerなので，"Add Item"が押された後に発火する
            self.itemArray.append(newItem)//今の状態だとtextが空の時に""が追加される（textが空の時にvalidationを後でつける)
            self.saveItems()
            //print("Success!")
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new items"
            textField = alertTextField//alertTextFieldはこのblock内でしか扱えないので，扱える範囲を広げるためにtextFieldに代入
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Model Manupulation Methods
    func saveItems() {
        
        do {
            try context.save()//dataをcontextを介して保存
        } catch {
            print("Error saving context. \(error)")
        }
        
        tableView.reloadData()
    }

    //localのPersistentContainer（SQLiteファイル）に保存されているdataを読み込む
    //request引数に初期値（default値）を入れておく（viewDidLoad()で引数なしで呼び出すときのために）
    //通常，型は推測できるが，CoreDataのNSFetchRequestでは読み取るdataの型を記述する必要あり
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
                
        do {
            itemArray = try context.fetch(request)//context.fetchで読み取ったdataを返す
        } catch {
            print("Error fetching data from context. \(error)")
        }
        tableView.reloadData()
    }
}

//MARK: - Search Bar Methods
extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        //NSPredicate言語:"title CONTAINS[cd] %@",書き方によってフィルタの掛け方が変わる.query言語で,SQL whereのようなもの．
        //（https://academy.realm.io/posts/nspredicate-cheatsheet/）
        //[cd]のc: 大文字．小文字の区別なし，d: 発音記号を無視
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)//%@にsearchBar.text!が入る
        
        //sortDescriptorsで検索結果をソート（今回の場合はアルファベット順のみを指定）,arrayに複数の条件を入れることで，複数条件でソートを可能
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request, predicate: predicate)
    }
    
    //searchbarのtextが変更された時に発火するmethod
    //searchbarのtextの入力がない時に，元々のリスト表示に戻す
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text?.count == 0 {
            loadItems()//引数なしの場合，defaultのrequestは単にデータを取ってくるだけなので元々のリストを表示
            
            //main threadで処理させる（キーボードを閉じるなどUIに関する処理は早くするためにmain threadで処理させる)
            //仮にfirebaseなどのdataの取得をmain threadで行わせると, dataの取得が終わるまでUIが表示されなくなってしまうので，UIに関係ない時間のかかりそうな処理はmain threadで行わせる必要なし
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()//searchBarを閉じる（キーボードを閉じる）
            }
            
            
        }
    }
}
