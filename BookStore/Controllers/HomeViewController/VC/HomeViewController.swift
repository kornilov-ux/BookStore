import UIKit
import OpenLibraryKit
import Kingfisher

final class HomeViewController: UIViewController {
    
    private var coverLoader: ImageLoader?
    private var openLibraryService: OpenLibraryService?
    private var recentService = RecentService.shared
    private var recentBooks: [Book] = []
    private var searchingBooks: [SearchResult] = []
    private var sortButtonNames = ["This Week", "This Month", "This Year"]
    private var images = [UIImage]() {
        didSet {
            if images.count == trendingsBooks?.works.count {
                topBooksCollectionView.reloadData()
                UIBlockingProgressHUD.dismiss()
            }
        }
    }
    private var searchingImages = [UIImage]() {
        didSet {
            if searchingImages.count == searchingBooks.count {
                searchBookCollection.reloadData()
                UIBlockingProgressHUD.dismiss()
            }
        }
    }
    private (set) var searchText: String = ""
    private var trendingsBooks: MyTrendingModel?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.tabBarController?.tabBar.isHidden = false
        navigationController?.navigationBar.tintColor = .black
        recentBooks = recentService.recentBooks.reversed()
        recentBooksCollectionView.reloadData()
        print(recentBooks)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        addView()
        applyConstraints()
        sortByNow()
    }
    
    init(coverLoader: ImageLoader, openLibraryService: OpenLibraryService) {
        super.init(nibName: nil, bundle: nil)
        self.coverLoader = coverLoader
        self.openLibraryService = openLibraryService
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private lazy var topBooksCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TopBooksCollectionViewCell.self, forCellWithReuseIdentifier: TopBooksCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var recentBooksCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(RecentBooksCollectionViewCell.self, forCellWithReuseIdentifier: RecentBooksCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var searchBooksField: UITextField = {
        let textfield = UITextField()
        textfield.text = ""
        textfield.font = UIFont.systemFont(ofSize: 16)
        textfield.textColor = .black
        textfield.placeholder = "Type somethings"
        textfield.delegate = self
        textfield.isEnabled = true
        textfield.addTarget(self, action: #selector(textFieldChanged), for: .editingDidEnd)
        return textfield
    }()
    
    private lazy var searchButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "searchLogo"), for: .normal)
        button.addTarget(self, action: #selector(textFieldChanged), for: .touchUpInside)
        return button
    }()
    
    private lazy var topBooksTitle: UILabel = {
        let label = UILabel()
        label.text = "Top Books"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private lazy var topBooksSeeMoreLabel: UILabel = {
        let label = UILabel()
        label.text = "see more"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTopSeeMoreLabel)))
        return label
    }()
    
    private lazy var buttonCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: ButtonCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var recentLabel: UILabel = {
        let label = UILabel()
        label.text = "Recent Books"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private lazy var recentBooksSeeMoreLabel: UILabel = {
        let label = UILabel()
        label.text = "see more"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRecentSeeMoreLabel)))
        return label
    }()
    
    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.text = "Search books:"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.isHidden = true
        return label
    }()
    
    private lazy var searchBookCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(SearchBooksCollectionViewCell.self, forCellWithReuseIdentifier: SearchBooksCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isHidden = true
        return collectionView
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        button.tintColor = .black
        button.isHidden = true
        button.addTarget(self, action: #selector(backTapButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var plugImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "searchError")
        image.isHidden = true
        return image
    }()
    
    private func sortByWeekly() {
        UIBlockingProgressHUD.show()
        openLibraryService?.fetchTrendingLimit10(sortBy: .weekly, limit: 10) { [weak self] result in
            guard let self else { return}
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.images = []
                    for i in data.works {
                        ImageLoader.loadImage(withCoverID: "\(i.coverId ?? 0)", size: .M) { image in
                            if let image = image {
                                self.images.append(image)
                                print(self.images.count)
                            } else {
                                print("Failed to file image")
                            }
                        }
                    }
                    self.trendingsBooks = data
                    UIBlockingProgressHUD.dismiss()
                case .failure(let error):
                    print(error.localizedDescription)
                    UIBlockingProgressHUD.dismiss()
                }
            }
        }
    }
    
    private func sortByMothly() {
        UIBlockingProgressHUD.show()
        openLibraryService?.fetchTrendingLimit10(sortBy: .monthly, limit: 10) { [weak self] result in
            guard let self else { return}
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.images = []
                    for i in data.works {
                        ImageLoader.loadImage(withCoverID: "\(i.coverId ?? 0)", size: .M) { image in
                            if let image = image {
                                self.images.append(image)
                                print(self.images.count)
                            } else {
                                print("Failed to file image")
                            }
                        }
                    }
                    self.trendingsBooks = data
                case .failure(let error):
                    print(error.localizedDescription)
                    UIBlockingProgressHUD.dismiss()
                }
            }
        }
    }
    
    private func sortByYearly() {
        UIBlockingProgressHUD.show()
        openLibraryService?.fetchTrendingLimit10(sortBy: .yearly, limit: 10) { [weak self] result in
            guard let self else { return}
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.images = []
                    for i in data.works {
                        ImageLoader.loadImage(withCoverID: "\(i.coverId ?? 0)", size: .M) { image in
                            if let image = image {
                                self.images.append(image)
                                print(self.images.count)
                            } else {
                                print("Failed to file image")
                            }
                        }
                    }
                    self.trendingsBooks = data
                case .failure(let error):
                    print(error.localizedDescription)
                    UIBlockingProgressHUD.dismiss()
                }
            }
        }
    }
    
    private func sortByNow() {
        UIBlockingProgressHUD.show()
        openLibraryService?.fetchTrendingLimit10(sortBy: .now, limit: 10) { [weak self] result in
            guard let self else { return}
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.images = []
                    for i in data.works {
                        ImageLoader.loadImage(withCoverID: "\(i.coverId ?? 0)", size: .M) { image in
                            if let image = image {
                                self.images.append(image)
                                print(self.images.count)
                            } else {
                                print("Failed to file image")
                            }
                        }
                    }
                    self.trendingsBooks = data
                    self.topBooksCollectionView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                    UIBlockingProgressHUD.dismiss()
                }
            }
        }
    }
    
    @objc func textFieldChanged() {
        searchText = searchBooksField.text ?? ""
        UIBlockingProgressHUD.show()
        openLibraryService?.fetchSearch(with: searchText) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    for i in data {
                        ImageLoader.loadImage(withCoverID: "\(i.coverId ?? 0)", size: .M) { image in
                            if let image = image {
                                self.images.append(image)
                                print(self.images.count)
                            } else {
                                print("Failed to file image")
                            }
                        }
                    }
                    self.searchingBooks = data
                    print(data)
                    if self.searchingBooks.isEmpty {
                        self.plugImage.isHidden = false
                        self.hideUIwithSearch()
                    } else {
                        print(data)
                        self.plugImage.isHidden = true
                        self.hideUIwithSearch()
                        self.searchBookCollection.reloadData()
                        UIBlockingProgressHUD.dismiss()
                    }
                case let .failure(error):
                    print(error)
                    UIBlockingProgressHUD.dismiss()
                    }
                }
            }
        }
    
    @objc func backTapButton() {
        print("tap")
        showUIwithSearch()
    }
    
    @objc func tapTopSeeMoreLabel() {
        let vc = SeeMoreViewController(typeOfEvent: .topBooks)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func tapRecentSeeMoreLabel() {
        let vc = SeeMoreViewController(typeOfEvent: .recentBooks)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func hideUIwithSearch() {
        [topBooksTitle, topBooksSeeMoreLabel, topBooksCollectionView, recentLabel, recentBooksCollectionView, recentBooksSeeMoreLabel, buttonCollection].forEach { view in
            view.isHidden = true
        }
        searchLabel.isHidden = false
        searchBookCollection.isHidden = false
        backButton.isHidden = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 85),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchLabel.topAnchor.constraint(equalTo: searchBooksField.bottomAnchor, constant: 20),
            searchBookCollection.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchBookCollection.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchBookCollection.topAnchor.constraint(equalTo: searchLabel.topAnchor, constant: 35),
            searchBookCollection.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5)
        ])
    }
    
    private func showUIwithSearch() {
        [topBooksTitle, topBooksSeeMoreLabel, topBooksCollectionView, recentLabel, recentBooksCollectionView, recentBooksSeeMoreLabel, buttonCollection].forEach { view in
            view.isHidden = false
        }
        searchLabel.isHidden = true
        searchBookCollection.isHidden = true
        backButton.isHidden = true
        plugImage.isHidden = true
    }
    
    private func hideUIwithSeeMore() {
        [recentLabel, recentBooksCollectionView, recentBooksSeeMoreLabel].forEach { view in
            view.isHidden = true
        }
    }
    
    private func addView() {
        [searchBooksField, searchButton, topBooksTitle, topBooksSeeMoreLabel, topBooksCollectionView, recentLabel, recentBooksSeeMoreLabel, recentBooksCollectionView, buttonCollection, searchLabel, searchBookCollection, backButton, plugImage].forEach(view.setupView(_:))
    }
    
    private func applyConstraints() {
        NSLayoutConstraint.activate([
            searchBooksField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchBooksField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor),
            searchBooksField.topAnchor.constraint(equalTo: view.topAnchor, constant: 95),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchButton.centerYAnchor.constraint(equalTo: searchBooksField.centerYAnchor),
            topBooksTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topBooksTitle.topAnchor.constraint(equalTo: searchBooksField.bottomAnchor, constant: 15),
            topBooksSeeMoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topBooksSeeMoreLabel.centerYAnchor.constraint(equalTo: topBooksTitle.centerYAnchor),
            buttonCollection.leadingAnchor.constraint(equalTo: topBooksTitle.leadingAnchor),
            buttonCollection.topAnchor.constraint(equalTo: topBooksTitle.bottomAnchor, constant: 15),
            buttonCollection.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buttonCollection.bottomAnchor.constraint(equalTo: topBooksCollectionView.topAnchor,constant: -15),
            topBooksCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topBooksCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topBooksCollectionView.topAnchor.constraint(equalTo: topBooksTitle.bottomAnchor, constant: 65),
            topBooksCollectionView.bottomAnchor.constraint(equalTo: recentLabel.topAnchor, constant: -15),
            recentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recentLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 465),
            recentBooksSeeMoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recentBooksSeeMoreLabel.centerYAnchor.constraint(equalTo: recentLabel.centerYAnchor),
            recentBooksCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recentBooksCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recentBooksCollectionView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: 20),
            recentBooksCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            plugImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            plugImage.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -330),
        ])
    }
    
   private func removeSubstringFromWorks(_ input: String) -> String {
        return input.replacingOccurrences(of: "/works/", with: "")
    }
    
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case topBooksCollectionView:
            guard let count = trendingsBooks?.works.count else { return 0}
            return count
        case recentBooksCollectionView:
            return recentBooks.count
        case buttonCollection:
            return sortButtonNames.count
        case searchBookCollection:
            return searchingBooks.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case topBooksCollectionView:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TopBooksCollectionViewCell.identifier, for: indexPath) as? TopBooksCollectionViewCell else { return UICollectionViewCell()}
            guard let model = trendingsBooks?.works[indexPath.row] else { return UICollectionViewCell()}
            var coverImage = UIImage()
            ImageLoader.loadImage(withCoverID: "\(trendingsBooks?.works[indexPath.row].coverId ?? 0)", size: .M) { image in
                if let image = image {
                    coverImage = image
                }
            }
            cell.configureCell(title: model.title,
                                author: model.authorNames?[0] ?? "Unknown",
                               genre: "\(model.firstPublishYear ?? 0)",
                               image: coverImage)
            return cell
        case recentBooksCollectionView:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentBooksCollectionViewCell.identifier, for: indexPath) as? RecentBooksCollectionViewCell else { return UICollectionViewCell()}
            let model = recentBooks[indexPath.row]
            cell.configureCell(title: model.title, author: model.category, image: model.image)
            return cell
        case buttonCollection:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ButtonCollectionViewCell.identifier, for: indexPath) as? ButtonCollectionViewCell else { return UICollectionViewCell() }
            let model = sortButtonNames[indexPath.row]
            cell.configure(title: model)
            return cell
        case searchBookCollection:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchBooksCollectionViewCell.identifier, for: indexPath) as? SearchBooksCollectionViewCell
            let model = searchingBooks[indexPath.row]
            var coverImage = UIImage()
            ImageLoader.loadImage(withCoverID: "\(model.coverId ?? 0)", size: .M) { image in
                if let image = image {
                    coverImage = image
                }
            }
            cell?.configureCell(title: model.title,
                                author: model.authors?[0] ?? "Unknown",
                                image: coverImage,
                                counting: "\(model.editionCount)")
            return cell ?? UICollectionViewCell()
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        switch collectionView {
        case topBooksCollectionView:
            return CGSize(width: collectionView.bounds.width / 2.4 + 23, height: collectionView.bounds.height)
        case recentBooksCollectionView:
            return CGSize(width: collectionView.bounds.width / 2, height: collectionView.bounds.height)
        case buttonCollection:
            return CGSize(width: collectionView.bounds.width / 3 - 10, height: collectionView.bounds.height)
        case searchBookCollection:
            return CGSize(width: collectionView.bounds.width / 2.4 + 23, height: collectionView.bounds.height / 2.5 + 10)
        default:
            return CGSize()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        case topBooksCollectionView:
            return 10
        case recentBooksCollectionView:
            return 10
        case searchBookCollection:
            return 10
        case buttonCollection:
            return 10
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ButtonCollectionViewCell else {
            guard let model = trendingsBooks?.works[indexPath.row] else { return }
            let id = removeSubstringFromWorks(model.key)
            let vc = BookDescriptionViewController(bookId: id)
            navigationController?.pushViewController(vc, animated: true)
            print("id")
            var coverImage = UIImage()
            ImageLoader.loadImage(withCoverID: "\(model.coverId ?? 0)", size: .M) { image in
                if let image = image {
                    coverImage = image
                }
            }
            recentService.appendElement(Book(id: model.key,
                                             title: model.title,
                                             image: coverImage,
                                             category: "\(model.firstPublishYear ?? 0)"))
            print(recentBooks)
            
            return
        }
        
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            sortByWeekly()
            cell.selectedCell()
        case IndexPath(row: 1, section: 0):
            cell.selectedCell()
            sortByMothly()
        case IndexPath(row: 2, section: 0):
            cell.selectedCell()
            sortByYearly()
        default: break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ButtonCollectionViewCell else { return }
        cell.deselectedCell()
    }
    
}

extension HomeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchBooksField.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        searchBooksField.text = ""
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if searchBooksField.text != "" {
            return true
        } else {
            searchBooksField.placeholder = "Type somethings"
            return false
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        
    }
}


