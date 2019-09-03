//
//  ShopViewModel.swift
//  giftadvice
//
//  Created by George Efimenko on 29.03.2019.
//  Copyright © 2019 George Efimenko. All rights reserved.
//

import UIKit
import OwlKit

class ShopViewModel: NSObject {

    @IBOutlet var collectionView: GACollectionView!
    lazy var collectionDirector = FlowCollectionDirector(collection: self.collectionView)

    private let noOrder = UIImageView(image: UIImage(named: "Empty.Image".localized))
    
    func setupCollectionView(adapters: [CollectionCellAdapterProtocol]) {
        collectionDirector.registerAdapters(adapters)
    }
    
    func reloadCollectionData(sections: [CollectionSection]) {
        _ = sections.map({$0.sectionInsets =  UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) })
        
        _ = sections.map({$0.minimumLineSpacing = 18 })

        collectionDirector.removeAll()
        collectionDirector.add(sections: sections)
        collectionDirector.reload()
        collectionView.isLoading = false
        setEmpty()
    }

    func setEmpty() {
        let sections = collectionDirector.sections
        
        noOrder.tintColor = UIColor.gray.withAlphaComponent(0.5)

        if (sections.count > 0 && sections[0].elements.count == 0) || sections.count == 0 {
            collectionView.addSubview(noOrder)
            noOrder.autoCenterInSuperview()
        } else {
            noOrder.removeFromSuperview()
        }
    }
}
