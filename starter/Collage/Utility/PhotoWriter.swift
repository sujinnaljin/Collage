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

import Foundation
import UIKit
import Photos

import Combine

class PhotoWriter {
  enum Error: Swift.Error {
    case couldNotSavePhoto
    case generic(Swift.Error)
  }
    
    //future는 publisher의 한 종류. 다른 타입이 결과를 섭스크라이브 할 수 있게함.
    //이 API의 consumer가 구독하게 될 것.
    static func save(_ image: UIImage) -> Future<String, PhotoWriter.Error> {
        return Future { resolve in
            do {
                //sync하게 포토 라이브러리 접근.
                //Future의 clousre 자체는 async하게 동작하므로 main 스레드에서의 블라킹은 걱정 할 필요 없음.
                try PHPhotoLibrary.shared().performChangesAndWait {
                    // 1. 이미지 저장을 위한 요청
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    
                    // 2. 새롭게 생성된 asset의 id 요청
                    guard let savedAssetID =
                        request.placeholderForCreatedAsset?.localIdentifier else {
                            return resolve(.failure(.couldNotSavePhoto))
                    }
                    resolve(.success(savedAssetID))
                }
            } catch {
                resolve(.failure(.generic(error)))
            }
        }
    }

  
}
