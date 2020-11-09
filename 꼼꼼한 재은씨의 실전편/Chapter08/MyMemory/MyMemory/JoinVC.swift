//
//  JoinVC.swift
//  MyMemory
//
//  Created by Choi SeungHyuk on 2020/11/09.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit

class JoinVC: UIViewController {
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var fieldAccount: UITextField!
    var fieldPassword: UITextField!
    var fieldName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        
        self.profile.layer.cornerRadius = self.profile.frame.width / 2
        self.profile.layer.masksToBounds = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tappedProfile(_:)))
        self.profile.addGestureRecognizer(gesture)
    }
    
    @IBAction func submit(_ sender: Any) {
    }
}

extension JoinVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        // 각 테이블 뷰 셀 모두에 공통으로 적용될 프레임 객체
        let tfFrame = CGRect(x: 20, y: 0, width: cell.bounds.width - 20, height: 37)
        switch indexPath.row {
        case 0 :
          self.fieldAccount = UITextField(frame: tfFrame)
          self.fieldAccount.placeholder = "계정(이메일)"
          self.fieldAccount.borderStyle = .none
          self.fieldAccount.autocapitalizationType = .none
          self.fieldAccount.font = UIFont.systemFont(ofSize: 14)
          cell.addSubview(self.fieldAccount)
        case 1 :
          self.fieldPassword = UITextField(frame: tfFrame)
          self.fieldPassword.placeholder = "비밀번호"
          self.fieldPassword.borderStyle = .none
          self.fieldPassword.isSecureTextEntry = true
          self.fieldPassword.font = UIFont.systemFont(ofSize: 14)
          cell.addSubview(self.fieldPassword)
        case 2 :
          self.fieldName = UITextField(frame: tfFrame)
          self.fieldName.placeholder = "이름"
          self.fieldName.borderStyle = .none
          self.fieldName.font = UIFont.systemFont(ofSize: 14)
          cell.addSubview(self.fieldName)
        default :
          ()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 40
    }
    
}

extension JoinVC: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @objc func tappedProfile(_ sender: Any) {
      // 액션시트를 열어주는 부분
      let msg = "프로필 이미지를 읽어올 곳을 선택하세요."
      let sheet = UIAlertController(title: msg, message: nil, preferredStyle: .actionSheet)
      
      sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
      sheet.addAction(UIAlertAction(title: "저장된 앨범", style: .default) { (_) in
        selectLibrary(src: .savedPhotosAlbum) // 저장된 앨범에서 이미지 선택하기
      })
      sheet.addAction(UIAlertAction(title: "포토 라이브러리", style: .default) { (_) in
        selectLibrary(src: .photoLibrary) // 포토 라이브러리에서 이미지 선택하기
      })
      sheet.addAction(UIAlertAction(title: "카메라", style: .default) { (_) in
        selectLibrary(src: .camera) // 카메라에서 이미지 촬영하기
      })
      self.present(sheet, animated: false)
      
      // 이미지 피커창을 여는 함수
        func selectLibrary(src: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(src) {
          let picker = UIImagePickerController()
          picker.delegate = self
          picker.allowsEditing = true
          
          self.present(picker, animated: false)
        } else {
          self.alert("사용할 수 없는 타입입니다.")
        }
      }
    }
}
