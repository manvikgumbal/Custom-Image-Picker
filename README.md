# Custom-Image-Picker

Now it's easy to crop Image according to image View. Just a single Class add CustomImagePickerView.swift to your project and give the size of image you want using.



CustomImagePickerView.sharedInstace.delegate = self

CustomImagePickerView.sharedInstace.imageSize = CGSizeMake(200,200)


Call methods to use camera or Gallery image


CustomImagePickerView.sharedInstace.pickImageUsing(target: self, mode: .Gallery)

CustomImagePickerView.sharedInstace.pickImageUsing(target: self, mode: .Camera)



Use the delegates to get image or perforam action on cancel




func didImagePickerFinishPicking(image: UIImage)

func didCancelImagePicking()
