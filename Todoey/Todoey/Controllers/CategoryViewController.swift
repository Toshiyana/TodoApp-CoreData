//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Toshiyana on 2021/03/19.
//  Copyright © 2021 App Brewery. All rights reserved.
//

//Thread 1: "-[UITableViewController addCategoryButtonPressed:]: unrecognized selector sent to instance 0x7f97a7807430"というエラーの原因が不明．一旦保留．

import UIKit
import CoreData

class CategoryViewController: UITableViewController {
    
    var categoryArray = [Category]()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        loadCategories()
    }
    
    //MARK: - TableView Datasource Methods
    //persistentContainer内のdataをTableViewに表示
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.categoryCellItendifier, for: indexPath)
        cell.textLabel?.text = categoryArray[indexPath.row].name
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    //CRUDを行う
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: K.categorySegue, sender: self)
    }

    //prepare(): performSegue()が実行される前に実行
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //今回は，遷移先がTododListViewControllerのみだが，複数の選択肢が考えられる場合，ここでif文で分岐を行う
        let destinationVC = segue.destination as! TodoListViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categoryArray[indexPath.row]
        }
    }
    
    //MARK: - Add New Categories
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()

        let alert = UIAlertController(title: "Add New Todoey Category", message: "", preferredStyle: .alert)

        let action = UIAlertAction(title: "Add Category", style: .default) { (action) in
            let newCategory = Category(context: self.context)
            newCategory.name = textField.text!

            self.categoryArray.append(newCategory)
            self.saveCategories()
        }

        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new categories"
            textField = alertTextField
        }

        alert.addAction(action)

        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - TableView Manupulation Methods
    func saveCategories() {
        do {
            try context.save()
        } catch {
            print("Error saving categories. \(error)")
        }
        
        tableView.reloadData()
    }
    
    func loadCategories() {
        
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            categoryArray = try context.fetch(request)
        } catch {
            print("Error loading categories. \(error)")
        }
        
        tableView.reloadData()
    }
}
