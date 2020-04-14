/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Photos
import Combine

class PhotosViewController: UICollectionViewController {
  
  // MARK: - Public properties
    //read-only publisher로 만듦. AnyPublisher는 send 불가능하니까 
    var selectedPhotos: AnyPublisher<UIImage, Never> {
        return selectedPhotosSubject.eraseToAnyPublisher()
    }
    
    @Published var selectedPhotosCount = 0
  
  // MARK: - Private properties
    //private 통해 여기서만 발행하게
    private let selectedPhotosSubject = PassthroughSubject<UIImage, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
  private lazy var photos = PhotosViewController.loadPhotos()
  private lazy var imageManager = PHCachingImageManager()
  
  private lazy var thumbnailSize: CGSize = {
    let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    return CGSize(width: cellSize.width * UIScreen.main.scale,
                  height: cellSize.height * UIScreen.main.scale)
  }()
  
  // MARK: - View controller
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Check for Photos access authorization and reload the list if authorized.
    PHPhotoLibrary.isAuthorized
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (isAuth) in
            if isAuth {
                self?.photos = PhotosViewController.loadPhotos()
                self?.collectionView.reloadData()
            } else {
                self?.showErrorMessage()
            }
        }
       .store(in: &subscriptions)
  }
    
    //답안?에서는 receiveCompletion 쪽에 pop을 작성했다.
    //Future은 값을 하나 방출하고 완료하거나, 실패하는 publisher이다.
    
    func showErrorMessage() {
        alert(title: "Cannot Access", text: "Please set auth")
           .sink(receiveValue: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil) //alert 창 위한 것
                self?.navigationController?.popViewController(animated: true)
                })
            .store(in: &subscriptions)
 
    }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    //해당 subject를 다른 type에 드러내고 있으니까, 뷰 컨트롤러가 해제되는 경우에 외부 구독을 제거하기 위해 완료 이벤트를 명시적으로 보냄
    selectedPhotosSubject.send(completion: .finished)
  }
    
  // MARK: - UICollectionViewDataSource
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let asset = photos.object(at: indexPath.item)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell

    cell.representedAssetIdentifier = asset.localIdentifier
    imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
      if cell.representedAssetIdentifier == asset.localIdentifier {
        cell.preview?.image = image
      }
    })
    
    return cell
  }
  
  // MARK: - UICollectionViewDelegate
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let asset = photos.object(at: indexPath.item)
    
    if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
      cell.flash()
    }
    
    imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
      guard let self = self,
        let image = image,
        let info = info
        else { return }
      
      if let isThumbnail = info[PHImageResultIsDegradedKey as String] as? Bool, isThumbnail {
        // Skip the thumbnail version of the asset
        return
      }
      
      // Send the selected photo
        self.selectedPhotosSubject.send(image)
        self.selectedPhotosCount += 1
      
    })
  }

}

// MARK: - Fetch assets
extension PhotosViewController {
  
  static func loadPhotos() -> PHFetchResult<PHAsset> {
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    return PHAsset.fetchAssets(with: allPhotosOptions)
  }
  
}
