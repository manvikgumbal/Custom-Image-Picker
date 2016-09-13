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
    func didImagePickerFinishPicking(image: UIImage)
    optional func didCancelImagePicking()
}

public enum PickerMode {
    case Camera
    case Gallery
}

class CustomImagePickerView: NSObject {
    static let  sharedInstace = CustomImagePickerView()
    var imagePicker = UIImagePickerController()
    weak var delegate: CustomPickerViewDelegate?
    var viewController: UIViewController!
    var customView: UIView!
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    var scrollValue: CGFloat = 1.0
    var cropPath = UIBezierPath()
    var imageSize: CGSize!
    var cornerRadius: CGFloat = 0.0
    
    func pickImageUsing(target target: UIViewController, mode:PickerMode) {
        imagePicker.delegate = self
        if(mode == .Camera && UIImagePickerController.isSourceTypeAvailable(.Camera)) {                imagePicker.sourceType = .Camera
        }
        else {
            imagePicker.sourceType = .PhotoLibrary
        }
        viewController = target
        target.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func createViewToCropImage(image image: UIImage) {
        customView = UIView(frame: viewController.view.frame)
        customView.backgroundColor = UIColor.blackColor()
        viewController.view.addSubview(customView)
        
        //Add scroll view to Zoom IN and Zoom OUT the Image
        scrollView = UIScrollView(frame: customView.frame)
        let imageRatio = image.size.height/image.size.width
        let newSize = CGSize(width: customView.frame.width, height: customView.frame.width*imageRatio)
        scrollView.frame.size = newSize
        scrollView.frame.origin = CGPointMake(scrollView.frame.origin.x, scrollView.frame.origin.y+64)
        scrollView.center = customView.center
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.clearColor()
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
        imageView = UIImageView(frame: CGRectMake(0, 0, scrollView.frame.width, scrollView.frame.height))
        imageView.image = image
        imageView.contentMode = .ScaleAspectFit
        imageView.backgroundColor = UIColor.redColor()
        scrollView.addSubview(imageView)
        
        //Add Navigation Bar to Handle Actions
        let navigationBarView = UIView(frame: CGRectMake(0,0,customView.frame.width,64))
        navigationBarView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
        customView.addSubview(navigationBarView)
        
        //Add Navigations Buttons
        //Cancel Button
        let cancelButton = UIButton(frame: CGRectMake(0,25,70,40))
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Medium", size: 15.0)
        cancelButton.titleLabel!.shadowColor = UIColor.clearColor()
        cancelButton.setTitleColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1.0), forState: .Normal)
        cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), forControlEvents: .TouchUpInside)
        navigationBarView.addSubview(cancelButton)
        
        //Done Button
        let doneButton = UIButton(frame: CGRectMake(navigationBarView.frame.width-65,25,65,40))
        doneButton.setTitle("Done", forState: .Normal)
        doneButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Medium", size: 15.0)
        doneButton.titleLabel!.shadowColor = UIColor.clearColor()
        doneButton.setTitleColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1.0), forState: .Normal)
        doneButton.addTarget(self, action: #selector(self.doneButtonAction(_:)), forControlEvents: .TouchUpInside)
        navigationBarView.addSubview(doneButton)
        createCropView()
        customView.bringSubviewToFront(navigationBarView)
    }
    
    //MARK: Create View to crop Image
    func createCropView() {
        let path = UIBezierPath(roundedRect: customView.frame, cornerRadius: 0)
        cropPath = UIBezierPath(roundedRect: CGRectMake((customView.frame.width/2)-(imageSize.width/2), (customView.frame.height/2)-(imageSize.height/2), imageSize.width, imageSize.height), cornerRadius: cornerRadius)
        path.appendPath(cropPath)
        path.usesEvenOddFillRule = true
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.CGPath
        fillLayer.fillRule = kCAFillRuleEvenOdd
        fillLayer.fillColor = UIColor.whiteColor().CGColor
        fillLayer.opacity = 0.8
        customView.layer.addSublayer(fillLayer)
    }
    
    
    //MARK: Center the content of scroll view After Zoom
    func centerScrollViewContents(){
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width{
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2
        }else{
            contentsFrame.origin.x = 0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2
        }else{
            contentsFrame.origin.y = 0
        }
        imageView.frame = contentsFrame
    }
    
    //MARK: IBActions
    func cancelButtonAction(sender: UIButton) {
        if(customView != nil) {
            customView.removeFromSuperview()
            delegate?.didCancelImagePicking?()
        }
    }
    
    func doneButtonAction(sender: UIButton) {
        if(customView != nil) {
            //Crop Image to scroll View Content Size
            UIGraphicsBeginImageContextWithOptions(scrollView.bounds.size, true, UIScreen.mainScreen().scale)
            let offset = scrollView.contentOffset
            CGContextTranslateCTM(UIGraphicsGetCurrentContext(), -offset.x, -offset.y)
            scrollView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            //Change Image Size according to scroll view visible content
            let imageRatio = image.size.height/image.size.width
            let newSize = CGSize(width: customView.frame.width, height: customView.frame.width*imageRatio)
            let newImage = imageWithImage(image, newSize: newSize)
            let image1 = cropToBounds(newImage, width: imageSize.width, height: imageSize.height)
            delegate?.didImagePickerFinishPicking(image1)
            customView.removeFromSuperview()
        }
    }
    
    //MARK: Image Cropping Methods
    
    //Crop Image to exact size
    func imageWithImage(image: UIImage, newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    //Crop Image from Center to Croppable Area
    func cropToBounds(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        let contextImage: UIImage = UIImage(CGImage: image.CGImage!)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        return image
    }
    
    //MARK: Tap Gesture Handler
    func handleTapGesture(sender: UITapGestureRecognizer) {
        if(scrollValue >= scrollView.minimumZoomScale && scrollValue <= scrollView.maximumZoomScale) {
            scrollValue += 2
        }
        else {
            scrollValue = 1
        }
        scrollView.setZoomScale(scrollValue, animated: true)
    }
}

//MARK: Scroll View Delegate
extension CustomImagePickerView: UIScrollViewDelegate {
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()
    }
}

//MARK: Image Picker Delegate
extension CustomImagePickerView
: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        createViewToCropImage(image: image)
    }
}