//  MainViewController.swift
//  Diary
//
//  Created by Kyo, Baem on 2022/12/19.
//

import UIKit

final class MainViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, DiaryData>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DiaryData>
    
    private lazy var dataSource = configureDataSource()
    private var diaryDatas: [DiaryData] = []
    
    private lazy var mainDiaryView = MainDiaryView(collectionView: configureCollectionView())
    private let coreDataManager = CoreDataManager.shared
    
    enum Section {
        case main
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupData()
        applySnapshot(animatingDifferences: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = mainDiaryView
        
        mainDiaryView.collectionView.delegate = self
        setNavigationBar()
    }
    
    private func setNavigationBar() {
        self.title = "일기장"
        let appearence = UINavigationBarAppearance()
        appearence.backgroundColor = .systemGray5
        self.navigationController?.navigationBar.standardAppearance = appearence
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearence
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add,
                                           target: self,
                                           action: #selector(addButtonTapped))
        self.navigationItem.rightBarButtonItem = addBarButton
    }
    
    private func setupData() {
        let result = coreDataManager.fetchData()
        switch result {
        case .success(let data):
            diaryDatas = data
        case .failure(let error):
            self.showCustomAlert(alertText: error.localizedDescription,
                                 alertMessage: error.errorDescription ?? "",
                                 useAction: true,
                                 completion: nil)
        }
    }
    
    @objc private func addButtonTapped() {
        let addViewController = EditViewController(diaryData: nil, status: .new)
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
}

// MARK: - UICollectionViewDelegate
extension MainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let addViewController = EditViewController(diaryData: diaryDatas[indexPath.item],
                                                   status: .edit)
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
}

// MARK: - DiffableDataSource And Snapshot
extension MainViewController {
    private func configureDataSource() -> DataSource {
        let cellRegistration = UICollectionView
            .CellRegistration<CustomListCell, DiaryData> { cell, _, diaryData in
                cell.bindData(diaryData)
                cell.accessories = [.disclosureIndicator()]
            }
        
        let dataSource = DataSource(
            collectionView: mainDiaryView.collectionView
        ) { collectionView, indexPath, diaryData in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                for: indexPath,
                                                                item: diaryData)
        }
        return dataSource
    }
    
    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(diaryDatas)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

// MARK: - Configuration
extension MainViewController {
    private func configureLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        
        configuration.trailingSwipeActionsConfigurationProvider = makeSwipeActions(for:)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    private func configureCollectionView() -> UICollectionView {
        var collectionView: UICollectionView! = nil
        collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: configureLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }
    
    private func makeSwipeActions(for indexPath: IndexPath?) -> UISwipeActionsConfiguration? {
        guard let indexPath = indexPath,
            let id = diaryDatas[indexPath.item].id else { return nil }
        
        let deleteActionTitle = NSLocalizedString("Delete", comment: "Delete action title")
        let deleteAction = UIContextualAction(style: .destructive, title: deleteActionTitle) {
            [weak self] UIContextualAction, UIView, completion in
            
            self?.coreDataManager.deleteData(id: id) { bool in
                print(bool)
                self?.setupData()
                self?.applySnapshot(animatingDifferences: true)
            }
            completion(false)
        }
        
        let shareActionTitle = NSLocalizedString("Share", comment: "Share action title")
        let shareAction = UIContextualAction(style: .normal, title: shareActionTitle) {
            [weak self] UIContextualAction, UIView, completion in
            self?.applySnapshot(animatingDifferences: false)
            completion(false)
        }
        deleteAction.backgroundColor = .red
        shareAction.backgroundColor = .blue
        return UISwipeActionsConfiguration(actions: [deleteAction,shareAction])
    }
}
