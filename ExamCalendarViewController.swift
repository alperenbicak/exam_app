//
//  ExamCalendarViewController.swift
//  ExamApp
//
//  Created by SARIÇELİK on 8.05.2025.
//

import UIKit
import RealmSwift
import FSCalendar

class ExamCalendarViewController: UIViewController,
    FSCalendarDelegate, FSCalendarDataSource,
    UITableViewDelegate, UITableViewDataSource
{

    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var tableView: UITableView!

    private var selectedDate: Date = Date()
    private let realm = try! Realm()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sınav Takvimi"

        calendar.delegate = self
        calendar.dataSource = self

        tableView.delegate = self
        tableView.dataSource = self

        // Geri dönüş butonunu kaldır
        navigationItem.hidesBackButton = true
        
        // Başlangıçta bugünü seç ve listeyi yenile
        selectedDate = Date()
        calendar.select(selectedDate)
        tableView.reloadData()
    }

    // MARK: - Yeni Sınav Ekleme

    @IBAction func addExamButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Yeni Sınav", message: nil, preferredStyle: .alert)

        // Ders adı
        alert.addTextField { $0.placeholder = "Ders adı" }

        // Tarih ve saat seçimi
        alert.addTextField { textField in
            textField.placeholder = "Tarih ve saat seç"
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .dateAndTime
            datePicker.minimumDate = Date()
            if #available(iOS 13.4, *) {
                datePicker.preferredDatePickerStyle = .wheels
            }
            datePicker.locale = Locale(identifier: "tr_TR")
            textField.inputView = datePicker
            textField.tag = 99
            datePicker.addTarget(self, action: #selector(self.dateChanged(_:)), for: .valueChanged)
        }

        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Kaydet", style: .default) { _ in
            guard
                let subject = alert.textFields?[0].text, !subject.isEmpty,
                let dateText = alert.textFields?[1].text,
                let date = self.parseDate(dateText)
            else { return }

            let exam = Exam()
            exam.subject = subject
            exam.date = date
            exam.ownerEmail = AppState.shared.currentUserEmail ?? ""

            try? self.realm.write {
                self.realm.add(exam)
            }

            self.selectedDate = date
            self.calendar.select(date)
            self.calendar.reloadData()
            self.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        if let tf = self.presentedViewController?.view.viewWithTag(99) as? UITextField {
            tf.text = formatter.string(from: sender.date)
        }
    }

    private func parseDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.date(from: text)
    }

    // MARK: - FSCalendarDataSource

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        // O günkü sınav sayısını direkt Realm'den çek
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        guard let email = AppState.shared.currentUserEmail else { return 0 }
        return realm.objects(Exam.self)
            .filter("ownerEmail == %@ AND date >= %@ AND date < %@", email, start as NSDate, end as NSDate)
            .count
    }

    // MARK: - FSCalendarDelegate

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        guard let email = AppState.shared.currentUserEmail else { return 0 }
        return realm.objects(Exam.self)
            .filter("ownerEmail == %@ AND date >= %@ AND date < %@", email, start as NSDate, end as NSDate)
            .count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        guard let email = AppState.shared.currentUserEmail else { return cell }
        let examsForDay = realm.objects(Exam.self)
            .filter("ownerEmail == %@ AND date >= %@ AND date < %@", email, start as NSDate, end as NSDate)
            .sorted(byKeyPath: "date", ascending: true)

        let exam = examsForDay[indexPath.row]
        cell.textLabel?.text = exam.subject

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        cell.detailTextLabel?.text = formatter.string(from: exam.date)
        return cell
    }
}
