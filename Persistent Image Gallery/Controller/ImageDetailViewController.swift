//
//  ImageDetailViewController.swift
//  Image Gallery
//
//  Created by Yuki Orikasa on 2018/07/10.
//  Copyright © 2018 Yuki Orikasa. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController {

    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.addSubview(imageView)
        }
    }
    
    var imageURL: URL? {
        didSet {
            if imageView.image != nil {
                imageView.image = nil
                fetchImage(from: imageURL!)
            }
        }
    }
    var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if imageView.image == nil, imageURL != nil {
            fetchImage(from: imageURL!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // copied from ImageColletionViewController...
    private func fetchImage(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url) {
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.imageView.sizeToFit()
                    self.scrollView.contentSize = self.imageView.frame.size
                    self.scrollView.zoomScale = self.zoomScaleToFit()
                }
            }
        }
    }
    
    private func zoomScaleToFit() -> CGFloat {
        let widthScale = self.scrollView.frame.width / self.imageView.frame.width
        let heightScale = self.scrollView.frame.height / self.imageView.frame.height
        let zoomScale = min(widthScale, heightScale) < 1 ? min(widthScale, heightScale) : 1
        self.scrollView.minimumZoomScale = zoomScale
        self.scrollView.maximumZoomScale = zoomScale*2
        return zoomScale
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension ImageDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
