//
//  SettingsViewController.swift
//  giftadvice
//
//  Created by George Efimenko on 15.03.2019.
//  Copyright © 2019 George Efimenko. All rights reserved.
//

import UIKit
import OwlKit
import Kingfisher
import MessageUI
import PhotosUI
import SafariServices

class SettingsViewController: GAViewController {

    // MARK: - IBOutlet Properties
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var viewModel: SettingsViewModel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var placeholder: UIView!
    @IBOutlet weak var reportButton: BorderedButton!
    @IBOutlet weak var editingImageView: UIImageView!
    @IBOutlet weak var signOutButton: BorderedButton!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var autorizeButton: BorderedButton!

    // MARK: - Private Properties

    private var loginService: LoginService!

    // MARK: - Override Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Title.Settings".localized

        viewModel.setupTableView(adapters: [infoItemAdapter])
        viewModel.reloadData(sections: poluteInfo())
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func inject(propertiesWithAssembly assembly: AssemblyManager) {
        loginService = assembly.loginService
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let path = UIBezierPath(roundedRect: placeholder.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12))
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = placeholder.bounds
        maskLayer.path = path.cgPath
        
        placeholder.layer.mask = maskLayer
    }
    
    // MARK: - Action Methods

    @IBAction func logout(_ sender: Any) {
        settingsRouter().showLoginRouter()
        loginService.removeUserModel()
    }
    
    @IBAction func openSettings(_ sender: Any) {
        showPopupView(title: "Settings.Title.Edit.Information".localized, adapters: [settingsItemAdapter], sections: poluteInfo(), CommandWith<Any>(action: { [unowned self] models in
            self.hidePopupView()
            if let models = models as? [Setting] {
                self.saveUserEditings(models: models)
            }
        }))
    }
    
    @IBAction func report(_ sender: Any) {
        let models: [Report] = [Report(value: "")]
        let section = TableSection(elements: models)
        
        showPopupView(title: "Settings.Title.Report".localized, adapters: [reportItemAdapter], sections: [section], CommandWith<Any>(action: { [unowned self] some in
            if let report = self.popupView?.tableDirector.sections[0].elements.first as? Report {
                self.sendEmail(withReport: report)
            }
            self.hidePopupView()
        }))
    }
    
    @IBAction func showImagePicker(_ sender: Any) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.delegate = self
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Alert.Photo".localized, style: .default, handler: { [unowned self] alert in
                picker.sourceType = .photoLibrary
                self.present(picker, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Alert.Camera".localized, style: .default, handler: { [unowned self] alert in
                picker.sourceType = .camera
                self.present(picker, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Alert.Cancel" .localized, style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                
            }
        case .restricted, .denied:
            let alert = UIAlertController(title: "Error".localized, message: "Permission.Error.Photo".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Alert.Understand".localized, style: .default, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func socialAction(_ sender: Any) {
        let url = URL(string: "https://oauth.vk.com/authorize?client_id=7174687&redirect_uri=https://ml.ideaback.net/auth&display=mobile&scope=friends&response_type=code&v=5.102&state=\(loginService.userModel?.identifier ?? "")")!
        let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
        present(vc, animated: true)
    }
}

private extension SettingsViewController {
    func setupViews() {
        editingImageView.tintColor = AppColors.Common.active()
        signOutButton.backgroundColor = AppColors.Common.active()
        
        if let user = loginService.userModel {
            if let url = user.photo  {
                DispatchQueue.main.async {
                    self.profileImageView.kf.setImage(with: URL(string: url)!)
                }
            }
        }
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        settingsButton.layer.cornerRadius = settingsButton.frame.size.height / 2
        
        view.backgroundColor = AppColors.Common.active()
        reportButton.backgroundColor = AppColors.Common.active()
        settingsButton.setTitleColor(AppColors.Common.active(), for: .normal)
        loadingIndicatorView.color = AppColors.Common.active()

        if let user = loginService.userModel, user.type! == .buyer {
            autorizeButton.isHidden = false

            loginService.checkIntegrationStatus(withUser: user) { (error, intagrated) in

            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.autorizeButton.isHidden = true
            }
        }
    }
    
    func poluteInfo() -> [TableSection] {
        guard let user = loginService.userModel else { return [] }
        
        var models: [Setting] = []
        
        do {
            if let name = user.name {
                let setting = Setting(title: "Settings.Title.Name".localized, value: name)
                models.append(setting)
            }
        }
        
//        do {
//            if let phone = user.phoneNumber {
//                let setting = Setting(title: "Settings.Title.Phone".localized, value: phone, keyType: .phonePad)
//                models.append(setting)
//            }
//        }
        
        do {
            if let companyName = user.companyName {
                let setting = Setting(title: "Settings.Title.CompanyName".localized, value: companyName)
                models.append(setting)
            }
        }
        
        do {
            if let address = user.address {
                let setting = Setting(title: "Settings.Title.Address".localized, value: address, keyType: .emailAddress)
                models.append(setting)
            }
        }
        
        do {
            if let webSite = user.webSite {
                let setting = Setting(title: "Settings.Title.WebSite".localized, value: webSite, keyType: .URL)
                models.append(setting)
            }
        }
        
        return [TableSection(elements: models)]
    }
    
    func saveUserEditings(models: [Setting]) {
        guard var user = loginService.userModel else { return }

        do {
            let title = "Settings.Title.Name".localized + ":"
            if let value = models.filter({$0.title == title}).first {
                user.name = value.value
                user.username = value.value
            }
        }
        
        do {
            let title = "Settings.Title.CompanyName".localized + ":"
            if let value = models.filter({$0.title == title}).first {
                user.companyName = value.value
            }
        }
        
        do {
            let title = "Settings.Title.Address".localized + ":"
            if let value = models.filter({$0.title == title}).first {
                user.address = value.value
            }
        }
        
        do {
            let title = "Settings.Title.WebSite".localized + ":"
            if let value = models.filter({$0.title == title}).first {
                user.webSite = value.value
            }
        }
        
        loginService.update(user: user)
        loginService.userModel = user
        
        viewModel.reloadData(sections: poluteInfo())
    }
    
    func sendEmail(withReport report: Report) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["admin@ideaforyou.co"])
            mail.setMessageBody(report.value, isHTML: true)
            
            present(mail, animated: true)
        } else {
            showErrorAlertWith(title: "Error".localized, message: "Email.Error".localized)
        }
    }
    
    var infoItemAdapter: TableCellAdapterProtocol {
        let adapter = TableCellAdapter<Setting, SettingsTableViewCell>()
        adapter.reusableViewLoadSource = .fromXib(name: "SettingsTableViewCell", bundle: nil)

        adapter.events.dequeue = { ctx in
            ctx.cell?.render(props: ctx.element!)
            ctx.cell?.valueLabel.isUserInteractionEnabled = false
        }
        
        return adapter
    }
    
    var settingsItemAdapter: TableCellAdapterProtocol {
        let adapter = TableCellAdapter<Setting, SettingsTableViewCell>()
        adapter.reusableViewLoadSource = .fromXib(name: "SettingsTableViewCell", bundle: nil)

        adapter.events.dequeue = { ctx in
            ctx.cell?.tableView = ctx.table
            ctx.cell?.render(props: ctx.element!)
            ctx.cell?.valueLabel.isUserInteractionEnabled = false
        }
        
        adapter.events.didSelect = { [unowned self] ctx in
            ctx.cell?.setFirstResponer()
            
            return .deselectAnimated
        }
        
        return adapter
    }
    
    var reportItemAdapter: TableCellAdapterProtocol {
        let adapter = TableCellAdapter<Report, ReportTableViewCell>()
        adapter.reusableViewLoadSource = .fromXib(name: "ReportTableViewCell", bundle: nil)

        adapter.events.dequeue = { ctx in
            ctx.cell?.render(props: ctx.element!)
        }
        
        adapter.events.didSelect = { [unowned self] ctx in
            let model = ctx.element!
  
            return .deselectAnimated
        }
        
        return adapter
    }
    
    private func settingsRouter() -> ProfileRouterInput {
        guard let router = router as? ProfileRouterInput else {
            fatalError("\(self) router isn't LaunchRouter")
        }
        
        return router
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        DispatchQueue.main.async {
            self.profileImageView.image = image
        }
        
        if let user = loginService.userModel {
            self.loadingIndicatorView.startAnimating()
            loginService.update(user: user, image: image) { [unowned self] (error, user) in
                self.loadingIndicatorView.stopAnimating()
            }
        }
    }
}
