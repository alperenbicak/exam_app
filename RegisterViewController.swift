//
//  RegisterViewController.swift
//  ExamApp
//
//  Created by SARIÇELİK on 8.05.2025.
//

import UIKit
import RealmSwift

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showAlert(message: "Lütfen tüm alanları doldurun.")
            return
        }

        guard password == confirmPassword else {
            showAlert(message: "Şifreler uyuşmuyor.")
            return
        }

        // Realm'e kullanıcı kaydetme
        let user = User()
        user.email = email
        user.password = password

        do {
            let realm = try Realm()
            try realm.write {
                realm.add(user)
            }
            
            // Başarılı kayıt sonrası login ekranına yönlendir
            let alert = UIAlertController(title: "Başarılı", message: "Kayıt işlemi başarılı! Giriş yapabilirsiniz.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self.present(alert, animated: true)
            
        } catch {
            showAlert(message: "Kayıt sırasında hata oluştu.")
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Bilgi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        self.present(alert, animated: true)
    }
}
