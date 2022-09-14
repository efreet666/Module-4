//
//  MainViewController.swift
//  Module 4
//
//  Created by Влад Бокин on 16.08.2022.
//

import Foundation
import UIKit
import Rswift
import CoreData

final class MainViewController: UIViewController {
    
    var categoriesData: CategoriesModel? = []
    private var categories = [Categories]()
    
    private enum Constants {
        static let headerHeight: CGFloat = 57
    }
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView()
        collectionView.backgroundColor = .gray
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    var activityView = UIActivityIndicatorView()
    
    private func showActivityIndicator() {
        // MARK: - Show activity view
        self.activityView = Spinner.activityIndicator(style: .large,
                                                      center: self.view.center)
        self.view.addSubview(self.activityView)
        self.activityView.startAnimating()
    }
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.mainGreenColor
        setupCollectionView()
        setupNavBar()
        showActivityIndicator()
        
        // MARK: - parse data in background
        //parseData()
        
        CoreDataManager.saveData()
        
     
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.categories = CoreDataManager.readData()
            for el in self.categories {
                print(el.image as Any)
            }
            self.convertToModel(CoreDataCategories: self.categories)
        }
        
        self.collectionView.reloadData()
        self.activityView.stopAnimating()
    }
    
    private func convertToModel(CoreDataCategories: [Categories]) {
        var i = 0
        for _ in CoreDataCategories {
            let el = CategoriesModelElement(id: CoreDataCategories[i].id,
                                            title: CoreDataCategories[i].title,
                                            image: CoreDataCategories[i].image)
            categoriesData?.append(el)
            i += 1
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
    // MARK: - parsing JSON from bundle
    private func parseData() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.categoriesData = Bundle.main.decode(CategoriesModel.self, from: DataPath.categoryData)
            
            // MARK: - update UI
            DispatchQueue.main.async {
                // MARK: - Check if data is empty
                if self.categoriesData?.isEmpty == true {
                    self.errorAlert(title: R.string.localizable.errorTitle(), message: R.string.localizable.erroSubtitle(), style: .alert)
                }
                self.collectionView.reloadData()
                self.activityView.stopAnimating()
            }
        }
    }
   
    // MARK: - setup collectionView
    private func setupCollectionView() {
        // MARK: - collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 9, bottom: 9, right: 9)
        layout.itemSize = CGSize(width: (self.view.frame.width - 28) / 2, height: 160)
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: 84, width: self.view.frame.size.width, height: self.view.frame.size.height), collectionViewLayout: layout)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: CategoryCollectionViewCell.identifier)
        collectionView.register(HeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCollectionReusableView.identifier)
        view.addSubview(collectionView)
    }

    // MARK: - setup navigation bar
    private func setupNavBar() {
        self.title = R.string.localizable.helpTitle()
        let closeItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(popVC))
        closeItem.tintColor = .white
        self.navigationItem.leftBarButtonItem = closeItem
        
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.whiteColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
    }

    func errorAlert(title: String, message: String, style: UIAlertController.Style){
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
            
            let action = UIAlertAction(title: "OK", style: .default) { (action) in
                
            }
           
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        
    }

    // MARK: - back button
    @objc func popVC() {
        print("Button tapped")
        // MARK: - close application
        exit(-1)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = categoriesData?.count {
            return count
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.identifier, for: indexPath) as? CategoryCollectionViewCell
        else {
            return UICollectionViewCell()
        }
        cell.backgroundColor = UIColor.lightGreyColor
        cell.setup(image: UIImage(named: "\(categoriesData?[indexPath.row].image ?? "")") ?? UIImage()
                   ,text: categoriesData?[indexPath.row].title ?? "")
        return cell

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = CurrentCategoryViewController()
        vc.currentCategoryTitle = categoriesData?[indexPath.row].title ?? ""
        vc.currentCategoryId = categoriesData?[indexPath.row].id ?? ""
        self.hidesBottomBarWhenPushed = false
        self.navigationController?.pushViewController(vc, animated: true)
        
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                           withReuseIdentifier: HeaderCollectionReusableView.identifier,
                                                                           for: indexPath) as? HeaderCollectionReusableView else  { return UICollectionReusableView()}
        // MARK: - configure header
        header.configure()
        return header
    }
}
    
// MARK: - UICollectionViewDelegateFlowLayout
extension MainViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.size.width, height: Constants.headerHeight)
    }
}
