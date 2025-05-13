import UIKit
import RealmSwift
import UserNotifications

class ProfileViewController: UIViewController,
    UITableViewDataSource, UITableViewDelegate
{

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    private var exams: [Exam] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profilim"

        tableView.delegate = self
        tableView.dataSource = self

        if let email = AppState.shared.currentUserEmail {
            emailLabel.text = "Giriş yapan kullanıcı: \(email)"
        } else {
            emailLabel.text = "Kullanıcı bilgisi alınamadı"
        }

        requestNotificationPermission()
        fetchUserExams()
    }

    // MARK: - Bildirim izni

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print(granted ? "✅ Bildirim izni verildi" : "❌ Bildirim reddedildi")
        }
    }

    // MARK: - Sınavları çek

    func fetchUserExams() {
        guard let email = AppState.shared.currentUserEmail else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            autoreleasepool {
                let realm = try! Realm()
                let examResults = realm.objects(Exam.self)
                    .filter("ownerEmail == %@", email)
                    .sorted(byKeyPath: "date", ascending: true)
                
                // Thread-safe kopya oluştur
                self.exams = examResults.map { exam in
                    let examCopy = Exam()
                    examCopy.id = exam.id
                    examCopy.subject = exam.subject
                    examCopy.date = exam.date
                    examCopy.ownerEmail = exam.ownerEmail
                    return examCopy
                }
                
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exams.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exam = exams[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = exam.subject

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        let detail = formatter.string(from: exam.date)
        
        // Önce varsayılan durumu ayarla
        cell.accessoryType = .none
        cell.detailTextLabel?.text = detail
        
        // Bildirim durumunu kontrol et
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            let hasNotification = requests.contains(where: { $0.identifier == exam.id })
            DispatchQueue.main.async {
                // Cell hala görünür durumdaysa güncelle
                if let visibleCells = self?.tableView.visibleCells,
                   visibleCells.contains(cell) {
                    cell.accessoryType = hasNotification ? .detailButton : .none
                    cell.detailTextLabel?.text = detail + (hasNotification ? " 🔔" : "")
                }
            }
        }

        return cell
    }

    // MARK: - Satıra tıklanınca seçim menüsü

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exam = exams[indexPath.row]

        let alert = UIAlertController(title: "İşlem Seç", message: "Bu sınavla ilgili ne yapmak istersiniz?", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "📅 Sınavı Güncelle", style: .default) { _ in
            self.editExam(exam)
        })

        alert.addAction(UIAlertAction(title: "🔔 Bildirim Ayarla / İptal Et", style: .default) { _ in
            self.showNotificationOptions(for: exam)
        })

        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))

        present(alert, animated: true)
    }

    // MARK: - Sınavı Güncelle

    func editExam(_ exam: Exam) {
        let alert = UIAlertController(title: "Sınavı Güncelle", message: nil, preferredStyle: .alert)

        alert.addTextField { tf in
            tf.placeholder = "Ders adı"
            tf.text = exam.subject
        }

        alert.addTextField { tf in
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy HH:mm"
            tf.placeholder = "Tarih ve saat"
            tf.text = formatter.string(from: exam.date)

            let datePicker = UIDatePicker()
            datePicker.date = exam.date
            datePicker.datePickerMode = .dateAndTime
            datePicker.minimumDate = Date()
            datePicker.locale = Locale(identifier: "tr_TR")
            if #available(iOS 13.4, *) {
                datePicker.preferredDatePickerStyle = .wheels
            }
            tf.inputView = datePicker
            tf.tag = 99
            datePicker.addTarget(self, action: #selector(self.dateChanged(_:)), for: .valueChanged)
        }

        alert.addAction(.init(title: "İptal", style: .cancel))
        alert.addAction(.init(title: "Kaydet", style: .default) { [weak self] _ in
            guard
                let self = self,
                let newSubject = alert.textFields?[0].text, !newSubject.isEmpty,
                let newDateStr = alert.textFields?[1].text,
                let newDate = self.parseDate(newDateStr)
            else { return }

            DispatchQueue.main.async {
                autoreleasepool {
                    let realm = try! Realm()
                    if let examToUpdate = realm.object(ofType: Exam.self, forPrimaryKey: exam.id) {
                        try? realm.write {
                            examToUpdate.subject = newSubject
                            examToUpdate.date = newDate
                        }
                    }

                    UNUserNotificationCenter.current()
                        .removePendingNotificationRequests(withIdentifiers: [exam.id])

                    self.fetchUserExams()
                }
            }
        })

        present(alert, animated: true)
    }

    // MARK: - Bildirim Seçenekleri

    func showNotificationOptions(for exam: Exam) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        let dateStr = formatter.string(from: exam.date)

        let alert = UIAlertController(title: "Bildirim Ayarı",
                                      message: "\(exam.subject)\n(\(dateStr)) için bildirim seç:",
                                      preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "1 gün önce bildir", style: .default) { _ in
            self.scheduleNotification(for: exam, minutesBefore: 1440)
        })
        alert.addAction(UIAlertAction(title: "1 saat önce bildir", style: .default) { _ in
            self.scheduleNotification(for: exam, minutesBefore: 60)
        })
        alert.addAction(UIAlertAction(title: "Bildirim iptal", style: .destructive) { _ in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [exam.id])
        })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))

        present(alert, animated: true)
    }

    // MARK: - Bildirim Planla

    func scheduleNotification(for exam: Exam, minutesBefore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Sınav Hatırlatma"
        content.body = "\(exam.subject) sınavına \(minutesBefore >= 60 ? "\(minutesBefore/60) saat" : "\(minutesBefore) dakika") kaldı!"
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: exam.date) else {
            return
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: exam.id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            print(error == nil ? "✅ Bildirim ayarlandı" : "❌ Bildirim hatası: \(error!.localizedDescription)")
        }
    }

    // MARK: - Yardımcılar

    @objc func dateChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        if let tf = self.presentedViewController?.view.viewWithTag(99) as? UITextField {
            tf.text = formatter.string(from: sender.date)
        }
    }

    func parseDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.date(from: text)
    }

    // MARK: - Silme (güncellenmiş)

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let examToDelete = exams[indexPath.row]
            let deletedId = examToDelete.id

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                autoreleasepool {
                    let realm = try! Realm()
                    if let examToDelete = realm.object(ofType: Exam.self, forPrimaryKey: deletedId) {
                        try? realm.write {
                            realm.delete(examToDelete)
                        }
                    }

                    UNUserNotificationCenter.current()
                        .removePendingNotificationRequests(withIdentifiers: [deletedId])

                    self.fetchUserExams()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // MARK: - Çıkış

    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        AppState.shared.currentUserEmail = nil
        navigationController?.popToRootViewController(animated: true)
    }
}
