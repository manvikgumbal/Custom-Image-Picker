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
        imageView = UIImageView(frame: customView.frame)
        imageView.image = image
        imageView.contentMode = .ScaleToFill
        
        //Add Blur Effect to Image View
        let blurEffect = UIBlurEffect(style: .Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = imageView.bounds
        imageView.addSubview(blurEffectView)
        scrollView.addSubview(imageView)
        
        //Add Image to be used
        let subImageView = UIImageView(frame: customView.frame)
        subImageView.backgroundColor = UIColor.clearColor()
        subImageView.image = image
        subImageView.contentMode = .ScaleAspectFit
        imageView.addSubview(subImageView)

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
        
        createView()
        
        customView.bringSubviewToFront(navigationBarView)
    }
    
    //MARK: Create View to crop Image
    
    func createView() {
        let path = UIBezierPath(roundedRect: customView.frame, cornerRadius: 0)
        let circlePath = UIBezierPath(roundedRect: CGRectMake((customView.frame.width/2)-100, (customView.frame.height/2)-100, 200, 200), cornerRadius: 0)
        
        path.appendPath(circlePath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = path.CGPath
        fillLayer.fillRule = kCAFillRuleEvenOdd
        fillLayer.fillColor = UIColor.blackColor().CGColor
        fillLayer.opacity = 0.7
        customView.layer.addSublayer(fillLayer)
    }
    
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
    
    
    func cancelButtonAction(sender: UIButton) {
        if(customView != nil) {
            customView.removeFromSuperview()
            delegate?.didCancelImagePicking?()
        }
    }
    
    func doneButtonAction(sender: UIButton) {
        if(customView != nil) {
            delegate?.didImagePickerFinishPicking(imageView!.image!)
            customView.removeFromSuperview()
        }
    }
    
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

extension CustomImagePickerView: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()
    }
}

extension CustomImagePickerView
: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        createViewToCropImage(image: image)
        //delegate?.didImagePickerFinishPicking(image)
    }
}