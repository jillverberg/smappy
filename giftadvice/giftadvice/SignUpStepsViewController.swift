//
//  SignUpStepsViewController.swift
//  giftadvice
//
//  Created by George Efimenko on 20.02.2019.
//  Copyright © 2019 George Efimenko. All rights reserved.
//

import UIKit

class SignUpStepsViewController: GAViewController {

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var firstStepView: PageIndicatorView!
    @IBOutlet weak var secondStepView: PageIndicatorView!
    @IBOutlet weak var thirdStepView: PageIndicatorView!
    @IBOutlet weak var forthStepView: PageIndicatorView!

    var type: LoginRouter.SignUpType!
    var pageControllers = [PageIndicatorView]()
    var loginService: LoginService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControllers.append(contentsOf: [firstStepView, secondStepView, thirdStepView, forthStepView])
        firstStepView.setAppearence(active: true)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.navigationBar.tintColor = AppColors.Common.active()
    }
    
    override func inject(propertiesWithAssembly assembly: AssemblyManager) {
        loginService = assembly.loginService
    }
    
    func loginRouter() -> LoginRouterInput {
        guard let router = router as? LoginRouterInput else {
            fatalError("\(self) router isn't LoginRouter")
        }
        
        return router
    }
}
