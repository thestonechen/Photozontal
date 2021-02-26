//
//  MediaPreviewViewController.swift
//  Photozontal
//
//  Created by Stone Chen on 2/19/21.
//

import UIKit

class MediaPreviewViewController: UIViewController {
    
    let mediaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let mediaImage: UIImage

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.view.addSubview(mediaImageView)
        self.setupNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupConstraints()
    }
    
    init(image: UIImage) {
        self.mediaImage = image
        self.mediaImageView.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
    }
    
    func setupConstraints() {
        mediaImageView.anchor(top: self.view.topAnchor, bottom: self.view.bottomAnchor, leading: self.view.leadingAnchor, trailing: self.view.trailingAnchor)
    }
    
    @objc
    func doneTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
