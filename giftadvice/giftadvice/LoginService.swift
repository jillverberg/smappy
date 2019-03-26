//
//  LoginService.swift
//  giftadvice
//
//  Created by George Efimenko on 25.02.2019.
//  Copyright © 2019 George Efimenko. All rights reserved.
//

import UIKit

private protocol PublicMethods {
    func isUserAuthorised() -> Bool
    func loadUserModel() -> User?
    func saveUserModel(_ model: User)
    func removeUserModel()
    func login(withPhone phone: String, password: String, type: LoginRouter.SignUpType, completion: @escaping (_ error: String?, _ userModel: User?) -> ())
    func signUp(withUser user: User, completion: @escaping (_ error: String?, _ userModel: User?) -> ())
    func verify(withCode code: String, type: LoginRouter.SignUpType, completion: @escaping (_ error: String?, _ userModel: User?) -> ())
    func update(user: User, completion: @escaping (_ error: String?, _ userModel: User?) -> ())
}

class LoginService {
    private struct UserDefaultsKeys {
        static let userModel = "userModel"
        static let accessToken = "accessToken"
    }
    
    var userModel: User?
    
    // MARK: - Private Properties
    
    private let networkManager = NetworkManager.shared

    // MARK: - Init Methods & Superclass Overriders
    
    init() {
        userModel = loadUserModel()
    }
}

// MARK: - Public Methods

extension LoginService: PublicMethods {
    func update(user: User, completion: @escaping (String?, User?) -> ()) {
        networkManager.update(user: user) { (cancelled, error, response) in
            var userModel: User?
            if let data = response, let user = User(JSON: data) {
                userModel = user
                
                self.saveUserModel(user)
            }
            
            DispatchQueue.main.async {
                completion(error, userModel)
            }
        }
    }

    func verify(withCode code: String, type: LoginRouter.SignUpType, completion: @escaping (String?, User?) -> ()) {
        if var user = userModel {
            user.type = type
            networkManager.verify(withUser: user, code: code, completion: { (cancelled, error, response) in
                var userModel: User?
                if let data = response, let user = User(JSON: data) {
                    userModel = user
                    
                    self.userModel = user
                    if let accessToken = user.accessToken {
                        self.saveAccessToken(accessToken)
                    }
                }
                
                DispatchQueue.main.async {
                    completion(error, userModel)
                }
            })
        }
    }
    
    func signUp(withUser user: User, completion: @escaping (String?, User?) -> ()) {
        networkManager.signUp(withUser: user) { (cancelled, error, response) in
            var userModel: User?
            if let data = response, let user = User(JSON: data) {
                userModel = user
                
                self.saveUserModel(user)
            }
            
            DispatchQueue.main.async {
                completion(error, userModel)
            }
        }
    }
    
    func login(withPhone phone: String, password: String, type: LoginRouter.SignUpType, completion: @escaping (_ error: String?, _ userModel: User?) -> ()) {
        networkManager.login(withPhone: phone, password: password, type: type) { (cancelled, error, response) in
            var userModel: User?
            if let data = response, let user = User(JSON: data) {
                userModel = user
                
                self.saveUserModel(user)
            }
            
            DispatchQueue.main.async {
                completion(error, userModel)
            }
        }
    }
    
    func removeUserModel() {
        userModel = nil
        
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.userModel) != nil {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userModel)
            UserDefaults.standard.synchronize()
        }
    }
    
    func isUserAuthorised() -> Bool {
        if let user = userModel, user.accessToken != nil {
            return true
        }
        
        return false
    }
    
    func loadUserModel() -> User? {
        if userModel != nil {
            return userModel
        }
        
        if let dictionary = UserDefaults.standard.object(forKey: UserDefaultsKeys.userModel) as? [String:Any] {
            let userModel = User(JSON: dictionary)
            return userModel
        } else {
            return nil
        }
    }
    
    func saveAccessToken(_ token: String) {
        UserDefaults.standard.setValue(token, forKey: UserDefaultsKeys.accessToken)
        UserDefaults.standard.synchronize()
    }
    
    func saveUserModel(_ model: User) {
        userModel = model
        
        let dictionary = model.toJSON()
        UserDefaults.standard.setValue(dictionary, forKey: UserDefaultsKeys.userModel)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Private Methods

private extension LoginService {
    
}
