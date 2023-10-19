//
//  ObjectDetection.swift
//  Object_Detection
//
//  Created by Hồ Bảo An on 18/10/2023.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class CameraDetection: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var nameObject: UILabel!
    
    var labelsOnScreen: [UILabel] = []
    
    var request: VNCoreMLRequest!
    var requestHandler: VNImageRequestHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getModelYolo()
        setUpCamera()
        
    }
    
    func getModelYolo () {
        if let model = try? VNCoreMLModel(for: yolov8n().model) {
            request = VNCoreMLRequest(model: model, completionHandler: handleDetection)
        }
    }
    
    func setUpCamera () {
        // Khởi tạo AVCaptureSession để lấy dữ liệu từ máy ảnh
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        
        // Hiển thị hình ảnh lên view
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        cameraView.layer.addSublayer(previewLayer)
        
        // Bắt đầu chạy session trên luồng nền
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        // Khởi tạo AVCaptureVideoDataOutput để nhận dữ liệu hình ảnh từ máy ảnh
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(output)
    }
    
    // Xử lý hàm callback từ AVCaptureVideoDataOutput
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // Tạo VNImageRequestHandler và gửi request để phát hiện vật thể
            requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
            do {
                try requestHandler?.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    func handleDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }

        var detectedObjectLabels = [String]() // Tạo mảng để lưu trữ các nhãn vật thể mới
        
        // Xoá tất cả các nhãn vật thể cũ
                DispatchQueue.main.async {
                    for labelView in self.labelsOnScreen {
                        labelView.removeFromSuperview()
                        self.removeOldBoundingBoxes()
                    }
                    self.labelsOnScreen.removeAll() // Xoá khỏi mảng
                }

        // Tiếp tục vẽ khung và nhãn vật thể mới
        for observation in observations {
            let boundingBox = observation.boundingBox
            let objectLabel = observation.labels.first?.identifier // Lấy tên của vật thể

            DispatchQueue.main.async {
                let transformedRect = self.transformRect(boundingBox, viewRect: self.cameraView.bounds)

                // Vẽ khung vật thể mới trên luồng chính cùng với tên vật thể
                self.drawBoundingBox(rect: transformedRect, label: objectLabel)

                if let label = objectLabel {
                    detectedObjectLabels.append(label)
                }
            }
        }

        // Hiển thị danh sách các vật thể mới trên label
        DispatchQueue.main.async {
            let detectedObjectsText = detectedObjectLabels.joined(separator: ", ")
            self.nameObject.text = detectedObjectsText
        }
    }

    func removeOldBoundingBoxes() {
        for subview in cameraView.subviews {
            if subview.tag == 100 {
                subview.removeFromSuperview()
            }
        }
    }
    
    // Hàm chuyển đổi tọa độ
    func transformRect(_ rect: CGRect, viewRect: CGRect) -> CGRect {
        let x = rect.origin.x * viewRect.width
        let y = (1 - rect.origin.y) * viewRect.height
        let width = rect.width * viewRect.width
        let height = -rect.height * viewRect.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func drawBoundingBox(rect: CGRect, label: String?) {
        DispatchQueue.main.async {
            let boxView = UIView(frame: rect)
            boxView.layer.borderColor = UIColor.red.cgColor
            boxView.layer.borderWidth = 2
            boxView.tag = 100 // Gán một tag cụ thể
            self.cameraView.addSubview(boxView)
            
            if let label = label {
                let labelView = UILabel(frame: CGRect(x: rect.origin.x, y: rect.origin.y - 20, width: rect.width, height: 20))
                labelView.text = label
                labelView.textColor = UIColor.red
                labelView.backgroundColor = UIColor.black
                labelView.textAlignment = .center
                self.cameraView.addSubview(labelView)
                self.labelsOnScreen.append(labelView) // Thêm vào mảng
            }
        }
    }


}

