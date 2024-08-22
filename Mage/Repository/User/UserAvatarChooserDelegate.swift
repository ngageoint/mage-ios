//
//  UserAvatarChooserDelegate.swift
//  MAGE
//
//  Created by Dan Barela on 8/21/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class UserAvatarChooserDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @Injected(\.userRepository)
    var repository: UserRepository
    
    var user: UserModel
    
    init(user: UserModel) {
        self.user = user
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil);
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let chosenImage: UIImage = info[.editedImage] as? UIImage {
            Task {
                await repository.avatarChosen(user: user, image: chosenImage)
            }
        }
    }
}
