//
//  CatBreedViewModel.swift
//  sword-health-test
//
//  Created by MAC on 11/02/2025.
//

import Foundation

final class CatBreedViewModel {
    
    private let apiManager: APIManager
    private let dbManager: DBManager
    
    private var catBreeds = [CatBreedResponse]()
    private var favourites = [Favourites]()
    
    var reloadCollectionView: (()->())?
    var reloadCollectionViewAt: ((IndexPath)->())?
    var showLoading: (()->())?
    var hideLoading: (()->())?
    
    private var cellViewModels = [CatBreedCellViewModel]() {
        didSet {
            self.reloadCollectionView?()
        }
    }
    
    var numberOfCells: Int {
        return catBreeds.count
    }
    
//    init() {
//        apiManager = APIManager()
//        dbManager = DBManager()
//    }
    
    init(apiManager: APIManager = .shared) {
        self.apiManager = apiManager
        dbManager = DBManager()
    }
    
    func getCatBreeds(pageSize: Int) {
        showLoading?()
        apiManager.fetchCatBreeds(pageSize: pageSize) { [weak self] result in
            self?.hideLoading?()
            do {
                self?.createCell(breeds: try result.get())
            } catch {
                
            }
        }
    }
    
    func searchCatBreed(by key: String) {
        showLoading?()
        cleanData()
        apiManager.searchCatBreed(by: key) { [weak self] result in
            self?.hideLoading?()
            do {
                self?.createCell(breeds: try result.get())
            } catch {}
        }
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> CatBreedCellViewModel {
        return cellViewModels[indexPath.row]
    }
    
    func getDetailsViewModel(at indexPath: IndexPath) -> CatBreedDetailViewModel {
        return CatBreedDetailViewModel(info: catBreeds[indexPath.row])
    }
    
    func createCell(breeds: [CatBreedResponse]) {
        self.catBreeds += breeds
        var vms = [CatBreedCellViewModel]()
        
        for breed in breeds {
            
//            guard let name = breed.name,
//                  let urlString = breed.image?.url,
//                  let url = URL(string: urlString)
//            else { return }
            
            vms.append(CatBreedCellViewModel(nameText: breed.name ?? "",
                                             imageURL: URL(string: breed.image?.url ?? ""),
                                             isFavourite: isFavourite(breed)))
        }
        
        cellViewModels += vms
    }
    
    private func cleanData() {
        catBreeds.removeAll()
        cellViewModels.removeAll()
    }
    
    func saveFavouriteBreed(indexPath: IndexPath) {
        guard let id = catBreeds[indexPath.row].id,
              let name = catBreeds[indexPath.row].name,
              let url = catBreeds[indexPath.row].image?.url,
              let origin = catBreeds[indexPath.row].origin,
              let temperament = catBreeds[indexPath.row].temperament,
              let description = catBreeds[indexPath.row].description
        else { return }
        
        dbManager.saveFavouriteBreed(id: id, name: name, url: url, origin: origin, temperament: temperament, description: description)
        cellViewModels[indexPath.row].isFavourite = true
        reloadCollectionViewAt?(indexPath)
    }
    
    func fetchFavourites() {
        dbManager.getFavouritesFromDataBase { favourites in
            self.favourites = favourites
        }
    }
    
    private func isFavourite(_ breed: CatBreedResponse) -> Bool {
        var isFavourite = false
        
        favourites.forEach { favourite in
            if favourite.id == breed.id {
                isFavourite = true
            }
        }
        
        return isFavourite
    }
}
