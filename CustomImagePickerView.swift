//
//  customImagePickerView.swift
//  ImagePickerDemo
//
//  Created by Manvik on 09/09/16.
//  Copyright © 2016 Deftsoft. All rights reserved.
//

import Foundation
import UIKit

@objc protocol CustomPickerViewDelegate {
    func didImagePickerFinishPicking(_ image: UIImage)
    @objc optional func didCancelImagePicking()
}

public enum PickerMode {
    case camera
    case gallery
}

class CustomImagePickerView: NSObject {
    static let  sharedInstace = CustomImagePickerView()
    var imagePicker = UIImagePickerController()
    weak var delegate: CustomPickerViewDelegate?
    var viewController: UIViewController!
    var customView: UIView!
    var imageView: UIImageView!
    var imageView1: UIImageView!
    
    var scrollView: UIScrollView!
    var scrollValue: CGFloat = 1.0
    var cropPath = UIBezierPath()
    var imageSize: CGSize!
    var cornerRadius: CGFloat = 0.0
    var frameValue: CGSize!
    var frameRect: CGRect!
    var maxZoom :CGFloat!
    var minZoom:CGFloat!
    
    func pickImageUsing(target: UIViewController, mode:PickerMode) {
        imagePicker.delegate = self
        if(mode == .camera && UIImagePickerController.isSourceTypeAvailable(.camera)) {                imagePicker.sourceType = .camera
        }
        else {
            imagePicker.sourceType = .photoLibrary
        }
        viewController = target
        target.present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func createViewToCropImage(image: UIImage) {
        customView = UIView(frame: viewController.view.frame)
        customView.backgroundColor = UIColor.black
        viewController.view.addSubview(customView)
        
        //Add scroll view to Zoom IN and Zoom OUT the Image
        scrollView = UIScrollView(frame: customView.frame)
        // let imageRatio = image.size.height/image.size.width
        let newSize = CGSize(width: customView.frame.width, height: customView.frame.width)
        scrollView.frame.size = newSize
        scrollView.frame.origin = CGPoint(x: scrollView.frame.origin.x, y: scrollView.frame.origin.y+64)
        scrollView.center = customView.center
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.clear
        scrollView.bouncesZoom = false
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.flashScrollIndicators()
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 2.0
        
        customView.addSubview(scrollView)
        
        //Add Double Tap Gesture on Scroll View to Zoom out
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:)))
        tapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tapGesture)
        
        //Add ImageView to show Image
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: scrollView.frame.height))
        imageView.image = image
        imageView.contentMode = .scaleToFill
        imageView.backgroundColor = UIColor.red
        scrollView.addSubview(imageView)
       //Add BlurView on Image to show Image blurred
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = imageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        imageView.addSubview(blurEffectView)
        
        //Add another ImageView on Blured Image View
        imageView1 = UIImageView(frame: CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height))
        
        imageView1.image = image
        imageView1.contentMode = .scaleAspectFit
        imageView.addSubview(imageView1)
        
        //Add Navigation Bar to Handle Actions
        let navigationBarView = UIView(frame: CGRect(x: 0,y: 0,width: customView.frame.width,height: 64))
        navigationBarView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        customView.addSubview(navigationBarView)
        
        //Add Navigations Buttons
        //Cancel Button
        let cancelButton = UIButton(frame: CGRect(x: 0,y: 25,width: 70,height: 40))
        cancelButton.setTitle("Cancel", for: UIControlState())
        cancelButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Medium", size: 15.0)
        cancelButton.titleLabel!.shadowColor = UIColor.clear
        cancelButton.setTitleColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1.0), for: UIControlState())
        cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        navigationBarView.addSubview(cancelButton)
        
        //Done Button
        let doneButton = UIButton(frame: CGRect(x: navigationBarView.frame.width-65,y: 25,width: 65,height: 40))
        doneButton.setTitle("Done", for: UIControlState())
        doneButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Medium", size: 15.0)
        doneButton.titleLabel!.shadowColor = UIColor.clear
        doneButton.setTitleColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1.0), for: UIControlState())
        doneButton.addTarget(self, action: #selector(self.doneButtonAction(_:)), for: .touchUpInside)
        navigationBarView.addSubview(doneButton)
        createCropView()
        customView.bringSubview(toFront: navigationBarView)
    }
    
    //MARK: Create View to crop Image
    func createCropView() {
        let path = UIBezierPath(roundedRect: customView.frame, cornerRadius: 0)
        cropPath = UIBezierPath(roundedRect: CGRect(x: (customView.frame.width/2)-(imageSize.width/2), y: (customView.frame.height/2)-(imageSize.height/2), width: imageSize.width, height: imageSize.height), cornerRadius: cornerRadius)
        //Save CropPath CGSize & CGRect Value for cutting the Image acc to crapView
        frameValue = CGSize(width: imageSize.width, height: imageSize.height)
        frameRect = CGRect(x: (customView.frame.width/2)-(imageSize.width/2), y: (customView.frame.height/2)-(imageSize.height/2), width: imageSize.width, height: imageSize.height)
        path.append(cropPath)
        path.usesEvenOddFillRule = true
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = kCAFillRuleEvenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        fillLayer.opacity = 0.5
        customView.layer.addSublayer(fillLayer)
    }
    
    
    //MARK: Center the content of scroll view After Zoom
    func centerScrollViewContents(){
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        var contentsFrame1 = imageView1.frame
        
        if contentsFrame.size.width < boundsSize.width{
            
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2
            contentsFrame1.origin.x = (imageView.bounds.size.width - contentsFrame1.size.width) / 2
            
            
        }else{
            contentsFrame.origin.x = 0
            contentsFrame1.origin.x = 0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2
            contentsFrame1.origin.y = (imageView.bounds.size.height - contentsFrame1.size.height) / 2
            
            
        }else{
            contentsFrame.origin.y = 0
            
            contentsFrame1.origin.y = 0
        }
        
        
        imageView.frame = contentsFrame
        imageView1.frame = contentsFrame1
        
    }
    
  //MARK: Set minimum Image size as same size of crop view
    func actionFinalCropImage(imageFrame: CGRect) {
        
        if((imageFrame.size.width <= frameValue.width) && (imageFrame.size.height <= frameValue.height) ){
            
            imageView.frame = frameRect
            imageView1.center = imageView.center
            imageView1.layoutIfNeeded()
            centerScrollViewContents()
        }
    }
    
    
    //MARK: IBActions
    func cancelButtonAction(_ sender: UIButton) {
        if(customView != nil) {
            customView.removeFromSuperview()
            delegate?.didCancelImagePicking?()
        }
    }
    
    func doneButtonAction(_ sender: UIButton) {
        if(customView != nil) {
            var image = UIImage()
            //Crop Image to scroll View & Image View Content Size
            if((scrollView.contentSize.width > viewController.view.frame.size.width) || (scrollView.contentSize.height > viewController.view.frame.size.height)){
                UIGraphicsBeginImageContextWithOptions(scrollView.bounds.size, true, UIScreen.main.scale)
                let offset = scrollView.contentOffset
                UIGraphicsGetCurrentContext()?.translateBy(x: -offset.x, y: -offset.y)
                scrollView.layer.render(in: UIGraphicsGetCurrentContext()!)
                image = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
             //Change Image Size according to scroll view visible content
                let imageRatio = (image.size.height)/(image.size.width)
                let newSize = CGSize(width: customView.frame.width, height: customView.frame.width*imageRatio)
                let newImage = imageWithImage(image, newSize: newSize)
                let image1 = cropToBounds(newImage, width: newSize.width, height: newSize.height)
                delegate?.didImagePickerFinishPicking(image1)
                customView.removeFromSuperview()
                
            }else{
                UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, true, UIScreen.main.scale)
                imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
                image = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
            //Change Image Size according to image view visible content
                let imageRatio = (image.size.height)/(image.size.width)
                let newSize = CGSize(width: customView.frame.width, height: customView.frame.width*imageRatio)
                let newImage = imageWithImage(image, newSize: newSize)
                delegate?.didImagePickerFinishPicking(newImage)
                customView.removeFromSuperview()
            }
          
        }
    }
    
    //MARK: Image Cropping Methods
    
    //Crop Image to exact size
    func imageWithImage(_ image: UIImage, newSize: CGSize) -> UIImage {
        
        if((scrollView.contentSize.width > viewController.view.frame.size.width) || (scrollView.contentSize.height > viewController.view.frame.size.height)){
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }else{
            return image
        }
        
    }
    
    //Crop Image from Center to Croppable Area
    func cropToBounds(_ image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        let refWidth : CGFloat = CGFloat(image.cgImage!.width)
        let refHeight : CGFloat = CGFloat(image.cgImage!.height)
        
        let x = (refWidth - width) / 2
        let y = (refHeight - height) / 2
        
        let cropRect = CGRect(x:x, y:y, width:width, height:height)
        let imageRef = image.cgImage!.cropping(to: cropRect)
        
        let cropped : UIImage = UIImage(cgImage: imageRef!, scale: 0, orientation: image.imageOrientation)
        
        return cropped
    }
    
    //MARK: Tap Gesture Handler
    func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if(scrollValue >= scrollView.minimumZoomScale && scrollValue <= scrollView.maximumZoomScale) {
            scrollValue +=  2
        }
        else {
            scrollValue = 1
        }
        scrollView.setZoomScale(scrollValue, animated: true)
    }
}

//MARK: Scroll View Delegate
extension CustomImagePickerView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        centerScrollViewContents()
        actionFinalCropImage(imageFrame: imageView.frame)
        
    }
}

//MARK: Image Picker Delegate
extension CustomImagePickerView
: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        picker.dismiss(animated: true, completion: nil)
        createViewToCropImage(image: image)
    }
}
