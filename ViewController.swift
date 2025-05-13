import UIKit
import RealmSwift

class ViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true
    }

    // Giriş ekranına geri dönüldüğünde alanlar temizlenir
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailTextField.text = ""
        passwordTextField.text = ""
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard !email.isEmpty, !password.isEmpty else {
            showAlert(message: "Lütfen tüm alanları doldurun.")
            return
        }

        do {
            let realm = try Realm()
            if let user = realm.objects(User.self)
                .filter("email == %@ AND password == %@", email, password)
                .first
            {
                AppState.shared.currentUserEmail = user.email

                showAlertWithAction(message: "Giriş başarılı!") {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let examVC = storyboard
                        .instantiateViewController(withIdentifier: "ExamCalendarViewController")
                        as? ExamCalendarViewController else {
                        self.showAlert(message: "Ekran bulunamadı.")
                        return
                    }

                    if let nav = self.navigationController {
                        nav.pushViewController(examVC, animated: true)
                    } else {
                        examVC.modalPresentationStyle = .fullScreen
                        self.present(examVC, animated: true)
                    }
                }
            } else {
                showAlert(message: "E-posta veya şifre yanlış.")
            }
        } catch let error as NSError {
            print("⚠️ Realm hatası:", error.localizedDescription)
            showAlert(message: "Veritabanı hatası: \(error.localizedDescription)")
        }
    }

    // MARK: - Alert Yardımcıları

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Tamam", style: .default))
        present(alert, animated: true)
    }

    func showAlertWithAction(message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "Bilgi", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Tamam", style: .default) { _ in
            completion()
        })
        present(alert, animated: true)
    }
}
