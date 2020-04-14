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
import Combine

class MainViewController: UIViewController {
  
  // MARK: - Outlets

  @IBOutlet weak var imagePreview: UIImageView! {
    didSet {
      imagePreview.layer.borderColor = UIColor.gray.cgColor
    }
  }
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  // MARK: - Private properties
    //현재 뷰컨과 라이프 사이클 함께하기 때문에 navigation stack 에서 없어지면 모든 UI subscription들도 취소 될 것.
    private var subscriptions = Set<AnyCancellable>()
    //데이터와 UI control을 바인딩할때는 대개 PassthroughSubject보다 CurrentValueSubject가 낫다.
    //적어도 하나의 값을 보장하기 때문에 UI가 정의되지 않은 상태로 있는 것을 방지하기 때문.
    private let images = CurrentValueSubject<[UIImage], Never>([])

  // MARK: - View controller
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let collageSize = imagePreview.frame.size
    
    images
        //UI update나 logging 등 사이드 이펙트 수행하고 싶을때
        .handleEvents(receiveOutput: { [weak self] photos in
            //업데이트 하고 싶은 UI마다 subscription 바인딩 하면 overkill 일 수 있다.
            //따라서 메인이 되는 것을 assign으로 subscription 생성하되, 나머지 좀좀따리는 handleEvent에서 처리
            self?.updateUI(photos: photos)
        })
        .map{ photos in
            UIImage.collage(images: photos, size: collageSize)
        }
        .assign(to: \.image, on: imagePreview)
        .store(in: &subscriptions)
    
    
    //🤔이런식으로 해도 성능은 같지만 위에 것이 더 보기 좋아서 그런가..?
    /*images
        .sink { [weak self] (photos) in
            self?.updateUI(photos: photos)
            self?.imagePreview.image = UIImage.collage(images: photos, size: collageSize)
        }
        .store(in: &subscriptions)*/
  }

  
  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
  
  // MARK: - Actions
  
  @IBAction func actionClear() {
    images.send([])
  }
  
  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    PhotoWriter.save(image)
        .sink(receiveCompletion: { [unowned self] (completion) in
            //if case 패턴 매칭
            if case .failure(let error) = completion {
                self.showMessage("Error", description: error.localizedDescription)
            }
            self.actionClear()
        }) { [unowned self] (id) in
            self.showMessage("Saved id with \(id)")
    }
    .store(in: &subscriptions)
    
  }
  
  @IBAction func actionAdd() {
//    let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
//    images.send(newImages)
    let photos = storyboard!.instantiateViewController(
      withIdentifier: "PhotosViewController") as! PhotosViewController
    
    photos.$selectedPhotosCount
        .filter{$0 > 0}
        .map { "Selected \($0) photos" }
        .assign(to: \.title, on: self)
        .store(in: &subscriptions)
    
    //read only publisher. 여기서는 발행 불가능.
    //같은 publisher에 대해 여러개 구독할때 share() 연산자 통해서 원래 publisher을 공유해야함. 이는 publisher을 class로 wrap 해서 다수의 subscriber에게 안전하게 방출.
    //주의해야할 점은 share()은 공유된 subscription으로 부터 나온 값을 재방출하지 않는다는 점이다.
    //이에 대한 해결책은 새로운 subscriber가 구독할때 예전 값을 재방출하거나 replay하는 나만의 공유 operator를 만드는 것이다.
    let newPhotos = photos.selectedPhotos.share()

    newPhotos
      .map { [unowned self] newImage in
        return self.images.value + [newImage]
      }
      .assign(to: \.value, on: images) //value 에 새 값이 할당되면 send하니까
      .store(in: &subscriptions) //이 subscription은 preseted된 뷰컨이 사라지자마자 끝날 것 (completion 보냈으니까)
    
    //🤔이런식으로 해도 성능은 같지만 위에 것이 더 보기 좋아서 그런가..?
    /*newPhotos
        .sink{ [unowned self] newImage in
            self.images.value += [newImage]
    }
    .store(in: &subscriptions)*/
        
        

    navigationController!.pushViewController(photos, animated: true)
  }
  
  private func showMessage(_ title: String, description: String? = nil) {
    self.alert(title: title, text: description)
        .sink { (_) in }
        .store(in: &subscriptions)
  }
}
