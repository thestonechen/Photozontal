//
//  ViewController.swift
//  Photozontal
//
//  Created by Stone Chen on 2/13/21.
//

import UIKit
import AVFoundation

enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

class CameraViewController: UIViewController {
    
    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var videoDeviceInput: AVCaptureDeviceInput?
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    var setupResult: SessionSetupResult = .success
    
    let cameraButtonSize: CGFloat = 75
    
    lazy var recordButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = self.cameraButtonSize / 2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var flashButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        button.setImage(UIImage(systemName: "bolt.fill"), for: .selected)
        button.imageView?.tintColor = .white
        button.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Checking video authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            self.sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        
        case .authorized:
            self.setupResult = .success
            
        default:
            self.setupResult = .notAuthorized
        }
        
        sessionQueue.async {
            self.configureSession()
        }
        
        [self.recordButton, self.flashButton].forEach { self.view.addSubview($0) }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.addObservers()
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Photozontal doesn't have permission to use the camera, please change the permission in settings", comment: "")
                    let alertController = UIAlertController(title: "Photozontal", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: ""),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                                                            }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Error with configuration. Unable to capture media", comment: "")
                    let alertController = UIAlertController(title: "Photozontal", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeObservers()
    }
    
    @objc
    func orientationChanged() {
        self.rotateButton(self.flashButton)
    }
    
    @objc
    func recordButtonTapped() {
        if self.canTakePicture() {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = flashButton.isSelected ? .on : .off
            if let photoOutputConnection = self.photoOutput .connection(with: AVMediaType.video) {
                photoOutputConnection.videoOrientation = self.getVideoOrientation()
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
        else {
            DispatchQueue.main.async {
                let message = NSLocalizedString("This app only takes photo in landscape mode. Please rotate your device.", comment: "")
                let alertController = UIAlertController(title: "Photozontal", message: message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                                        style: .cancel,
                                                        handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc
    func flashButtonTapped() {
        self.flashButton.isSelected = !self.flashButton.isSelected
    }
    
    
    func rotateButton(_ button: UIButton) {
        var rotationAngle: CGFloat = 0
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            rotationAngle = (CGFloat.pi/2)
        case .landscapeRight:
            rotationAngle = -CGFloat.pi/2
        case .portraitUpsideDown:
            rotationAngle = CGFloat.pi
        default:
            rotationAngle = 0
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            button.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupConstraints()
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
   
    func setupConstraints() {
        
        // Record button
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        recordButton.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: self.cameraButtonSize).isActive = true
        recordButton.widthAnchor.constraint(equalToConstant: self.cameraButtonSize).isActive = true
        
        // Flash button
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        flashButton.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
    }
    
    func configureSession() {
        if self.setupResult != .success {
            return
        }
        
        self.session.beginConfiguration()
        self.session.sessionPreset = .photo
        
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            // https://stackoverflow.com/questions/39563155/how-to-add-autofocus-to-avcapturesession-swift
            // SHOULD MOVE THIS ELSEWHERE?
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                try! videoDevice.lockForConfiguration()
                videoDevice.focusMode = .continuousAutoFocus
                videoDevice.unlockForConfiguration()
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add the photo output.
        if self.session.canAddOutput(photoOutput) {
            self.session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.cameraPreviewLayer?.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            self.cameraPreviewLayer?.frame = self.view.bounds
            self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
        }
        session.commitConfiguration()
    }
    
    // Delete this later
    func displayCapturedPhoto(capturedPhoto: UIImage) {
        let vc = MediaPreviewViewController(image: capturedPhoto)
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func getVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    func canTakePicture() -> Bool {
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print(error!.localizedDescription)
            return
        }
                
        guard let data = photo.fileDataRepresentation(),  let image = UIImage(data: data) else {
            print("error")
            return
        }
        
        // Flicker the screen to signal photo was taken
        DispatchQueue.main.async {
            self.view.layer.opacity = 0
            UIView.animate(withDuration: 0.25) {
                self.view.layer.opacity = 1
            }
        }
        
        
        // SHOULD BE HANDLED BY A SEPARATE CLASS. Maybe a ImageSaver class?
        //UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil) // need to handle if rejects saving
        // Separate class to handle saving image?
        
       self.displayCapturedPhoto(capturedPhoto: image)
    }
    
    @objc
    func saveError(_ image: UIImage, didFinishSavingWithError: Error?, contextInfo: UnsafeRawPointer) {
        print("SAVE FINISHED")
    }
}
