//
//  AddToWalletButton.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/11/24.
//

import SwiftUI
import PassKit

struct AddToWalletButton: UIViewRepresentable {
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> PKAddPassButton {
        let button = PKAddPassButton(addPassButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.addPass), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKAddPassButton, context: Context) {
        if isLoading {
            uiView.isHidden = true
        } else {
            uiView.isHidden = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: AddToWalletButton
        
        init(_ parent: AddToWalletButton) {
            self.parent = parent
        }

        @objc func addPass() {
            self.parent.isLoading = true
            guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/user/get_user_id/pkpass") else {
                return
            }

            let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    print("Failed to download PKPASS: \(error)")
                    self.parent.isLoading = false
                    return
                }

                guard let localURL = localURL else {
                    print("Failed to download PKPASS: No local URL returned")
                    self.parent.isLoading = false
                    return
                }

                do {
                    let passData = try Data(contentsOf: localURL)
                    let passController = PKAddPassesViewController(pass: try PKPass(data: passData))
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController?.present(passController!, animated: true, completion: nil)
                    }
                    self.parent.isLoading = false
                } catch {
                    print("Failed to read PKPASS file: \(error)")
                    self.parent.isLoading = false
                }
            }

            task.resume()
        }
    }
}
