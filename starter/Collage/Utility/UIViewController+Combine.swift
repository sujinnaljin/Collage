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

extension UIViewController {
    //값을 return 하는 것엔 관심 없고 유저가 Close 를 탭할때 완료하는 것만 관심
    //🤔근데 이게 기존 코드보다 더 나은지는 잘 모르겠다. 흠.. 핸들러에서 역할이 단순히 dismiss 하는게 아니라 상황에 따라 다양해진다면 유용할거 같기도하고..
  func alert(title: String, text: String?) -> AnyPublisher<Void, Never> {
    let alertVC = UIAlertController(title: title,
                                    message: text,
                                    preferredStyle: .alert)
    return Future { (resolve) in
        alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { (_) in
            resolve(.success(()))
        }))
        self.present(alertVC, animated: true, completion: nil)
    }
    //alert subscription 과 현재 나타나는 뷰컨과 연결시키고, 해당 컨트롤러가 dismiss됐을때를 처리한다.
    .handleEvents(receiveCancel : {
        //subscription이 취소될때 해당 alert를 자동으로 dismiss 시킴
        self.dismiss(animated: true)
    })
    .eraseToAnyPublisher()
    
    }
}
