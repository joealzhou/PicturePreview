//
//  PicturePreview.swift
//  ImageViewer
//
//  Created by zhouqiang on 15/8/11.
//  Copyright © 2015年 msy. All rights reserved.
//

import UIKit
import SDWebImage
extension UIImage {
    /**
     使用颜色实例化图片，大小为1像素

     - parameter color: 颜色

     - returns: 图片
     */
    public convenience init?(color: UIColor) {
        self.init(color: color, rect: CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    //MARK: - 创建图片
    /**
     使用颜色实例化图片

     - parameter color: 颜色值
     - parameter rect:  图片大小

     - returns: 图片
     */
    public convenience init?(color: UIColor, rect: CGRect) {

        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext();

        context?.setFillColor(color.cgColor);
        context?.fill(rect);

        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        guard let data = UIImageJPEGRepresentation(image!, 1.0) else {self.init(); return}
        self.init(data: data)
    }
}

public class PicturePreview: UIView, UIScrollViewDelegate {
    private let blackImage = UIImage(color: UIColor.black)
    private var title: UILabel = UILabel()
    private var imageScrollView: UIScrollView = UIScrollView()
    private var imageURLs: [String] = []
    private var viewFrame: CGRect!
    private var indexOfCurrentPage: Int = 1
    private var allImageView: [UIScrollView] = []
    var lastScale: CGFloat = 0
    
    private var totalScale: CGFloat = 0
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(imageURLs: [String], index: Int) {
        let mainWindow: UIWindow =
            UIApplication.shared.keyWindow! as UIWindow
        self.init(frame: mainWindow.frame)
        
        self.imageURLs = imageURLs
        self.viewFrame = frame

        self.initScrollViewItemView(startIndex: index)
        self.addSubview(self.imageScrollView)
        
        self.initNumberTitle()
        self.addSubview(self.title)
        
        self.movingToFocus(index: index)
        
        self.initGestures()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func getDataFromUrl(urL:NSURL, completion: @escaping ((_ data: NSData?) -> Void)) {
        URLSession.shared.dataTask(with: urL as URL) { (data, response, error) in
            completion(data as NSData?)
            }.resume()
    }
    
    private func downloadImage(urlString: String, imageView: UIImageView?, waitView: UIView?){
        let url: NSURL = NSURL(string: urlString)!
        self.getDataFromUrl(urL: url) { data in
            DispatchQueue.main.async {
                if let imageData: NSData = data {
                    imageView?.image = UIImage(data: imageData as Data)
                    imageView?.isHidden = false
                    waitView?.removeFromSuperview()
                }
            }

        }
    }
    
    private func loadImageFromNetwork(urlString: String,
        imageView: UIImageView, waitView: UIView) {
            self.downloadImage(urlString: urlString, imageView: imageView, waitView: waitView)
    }
    
    private func initScrollViewItemView(startIndex: Int) {
        let imageScrollViewFrame: CGRect =
            CGRect(x: self.viewFrame.origin.x,
                y: self.viewFrame.origin.y,
                width: self.viewFrame.width,
                height: self.viewFrame.height)
        self.imageScrollView.frame = imageScrollViewFrame
        self.imageScrollView.center = self.center
        
        var xpoint: CGFloat = 0
        
        for index in 0 ..< self.imageURLs.count {
            /* 图片显示视图 */
            let imageViewFrame: CGRect = CGRect(x: xpoint, y: 0, width: imageScrollViewFrame.width, height: imageScrollViewFrame.height)
            
            let imageView: UIImageView = UIImageView(frame: CGRect(x:0, y: 0, width: imageScrollViewFrame.width, height: imageScrollViewFrame.height))
            imageView.contentMode = .scaleAspectFit
//            allImageView.append(imageView)
            xpoint += imageScrollViewFrame.width
            
            let waitView: UIActivityIndicatorView = UIActivityIndicatorView()
            waitView.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
            waitView.activityIndicatorViewStyle =
                UIActivityIndicatorViewStyle.whiteLarge
            waitView.center = self.center
            waitView.startAnimating()
            imageView.addSubview(waitView)
            
            let smallImgSv = UIScrollView(frame: imageViewFrame)
            smallImgSv.addSubview(imageView)
            smallImgSv.bounces = false
            smallImgSv.showsVerticalScrollIndicator = false
            smallImgSv.showsHorizontalScrollIndicator = false
            allImageView.append(smallImgSv)
            
            self.imageScrollView.addSubview(smallImgSv)
            /* 加载图片 */
//            self.loadImageFromNetwork(urlString: self.imageURLs[index],
//                imageView: imageView, waitView: waitView)
            if startIndex == index {
                imageView.sd_setImage(with: URL(string: imageURLs[startIndex]), placeholderImage: blackImage, options: SDWebImageOptions.retryFailed, completed: { [weak imageView, weak waitView] (img: UIImage?, err: Error?, type: SDImageCacheType, url: URL?) in
                    imageView?.isHidden = false
                    waitView?.removeFromSuperview()
                })
            }
        }
        
        let width: CGFloat =
        imageScrollViewFrame.width * CGFloat(self.imageURLs.count)
        self.imageScrollView.contentSize =
            CGSize(width: width, height: imageScrollViewFrame.height)
        /* 相关属性 */
        self.imageScrollView.isPagingEnabled = true
        self.imageScrollView.delegate = self
        self.imageScrollView.showsHorizontalScrollIndicator = false
        
        self.imageScrollView.isUserInteractionEnabled = true
        self.imageScrollView.isMultipleTouchEnabled = true
    }
    
    private func movingToFocus(index: Int) {
        if index != 0 {
            if index >= self.imageURLs.count {
                return
            } else {
                let xpoint: CGFloat = CGFloat(index) * self.viewFrame.width
                self.imageScrollView.setContentOffset(CGPoint(x: xpoint, y: 0),
                    animated: false)
                self.indexOfCurrentPage = index + 1
                self.updateNumberTitle()
            }
        }
    }
    
    private func initNumberTitle() {
        var bottomSpace: CGFloat = 0
        if UIScreen.main.bounds.height == 812 {
            bottomSpace = 35
        }
        let titleWidth: CGFloat = 100
        self.title.frame = CGRect(x: (self.frame.width - titleWidth) / 2,
            y: 10 + bottomSpace, width: titleWidth, height: 30)
        self.title.font = UIFont.boldSystemFont(ofSize: 20)
        self.title.textColor = UIColor.white
        self.title.textAlignment = .center
        self.title.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.title.layer.masksToBounds = true
        self.title.layer.cornerRadius = 5
        self.updateNumberTitle()
    }
    
    private func updateNumberTitle() {
        self.title.text = "\(self.indexOfCurrentPage) / \(self.imageURLs.count)"
    }
    
    @objc private func dismissImageViewer(sender:UITapGestureRecognizer){
        self.title.isHidden = true
        self.setCloseWindowLebel()
        UIView.animate(withDuration: 0.3, delay: 0.0,
            options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.backgroundColor = UIColor(white:1, alpha: 0)
                self.allImageView[self.indexOfCurrentPage - 1].alpha = 0
            }, completion: {(value:Bool) in
                self.removeFromSuperview()
        })
    }
    
    @objc private func imageScalingAction(sender: UIPinchGestureRecognizer) {
        
        if let imageV = sender.view {
            if sender.state == .ended {
                
                if self.totalScale < 1 {
                    imageV.transform = CGAffineTransform(scaleX: 1, y: 1)
                    if let sv = imageV.superview as? UIScrollView {
                        sv.contentSize = CGSize(width: self.frame.size.width, height: self.frame.size.height)
                        (sv.subviews.first)?.center = CGPoint(x: sv.contentSize.width / 2 , y: sv.contentSize.height / 2)
                    }
                    
                }
                
                if self.totalScale > 1 {
                    imageV.transform = CGAffineTransform(scaleX: totalScale, y: totalScale)
                    if let sv = imageV.superview as? UIScrollView {
                        let imgV = imageV as! UIImageView
                        let originImgW = imgV.image?.size.width ?? 0
                        let originImgH = imgV.image?.size.height ?? 0
                        var r: CGFloat = 1.0
                        var imageW: CGFloat = 0
                        var imageH: CGFloat = 0

                        if originImgW < originImgH {
                            r = originImgH / UIScreen.main.bounds.height
                            imageH = UIScreen.main.bounds.height
                            imageW = originImgW / r
                        } else {
                            r = originImgW / UIScreen.main.bounds.width
                            imageW = UIScreen.main.bounds.width
                            imageH = originImgH / r
                        }


                        let h: CGFloat = imageH * totalScale > UIScreen.main.bounds.height ? imageH * totalScale : UIScreen.main.bounds.height
                        let w: CGFloat = imageW * totalScale > UIScreen.main.bounds.width ? imageW * totalScale : UIScreen.main.bounds.width
                        sv.contentSize = CGSize(width: w, height: h)

                        let x = ((sv.contentSize.width - bounds.width) / 2) > 0 ?  ((sv.contentSize.width - bounds.width) / 2) : 0
                        let y = ((sv.contentSize.height - bounds.height) / 2) > 0 ? ((sv.contentSize.height - bounds.height) / 2) : 0
                        sv.contentOffset = CGPoint(x: x, y: y)

                        (sv.subviews.first)?.center = CGPoint(x: sv.contentSize.width / 2 , y: sv.contentSize.height / 2)
                       
                    }
                }
                
                self.lastScale = 1.0
                return
            }
            
            let newScale: CGFloat = 1.0 - (self.lastScale - sender.scale)
            
            let currentTransform: CGAffineTransform = imageV.transform
            let newTransform: CGAffineTransform =
                currentTransform.scaledBy(x: newScale, y: newScale)
            imageV.transform = newTransform
            totalScale = newTransform.a
            self.lastScale = sender.scale
        }
    }
    
    private func initGestures() {
        //close
        let closeTap: UITapGestureRecognizer =
        UITapGestureRecognizer(target: self,
            action: #selector(PicturePreview.dismissImageViewer(sender:)))
        
        closeTap.numberOfTapsRequired = 1
        self.addGestureRecognizer(closeTap)
        
        //scaling
        for imageSV in self.allImageView {
            if let imgV = imageSV.subviews.first {
                let scalingTap: UIPinchGestureRecognizer =
                    UIPinchGestureRecognizer(target: self,
                                             action: #selector(PicturePreview.imageScalingAction(sender:)))
                imgV.isUserInteractionEnabled = true
                imgV.isMultipleTouchEnabled = true
                imgV.addGestureRecognizer(scalingTap)
            }
            
        }
    }
    
//    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        let translation = scrollView.panGestureRecognizer.translationInView(scrollView).x
//        if translation < 0 {
//            if self.indexOfCurrentPage < self.imageURLs.count {
//                self.indexOfCurrentPage += 1
//            }
//        } else {
//            if self.indexOfCurrentPage > 1 {
//                self.indexOfCurrentPage -= 1
//            }
//        }
//        self.updateNumberTitle()
//    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === imageScrollView {
            let imageSV = allImageView[indexOfCurrentPage -   1]
            if let imgv = imageSV.subviews.first as? UIImageView {
                if let waitView = imgv.subviews.first as? UIActivityIndicatorView {
                    imgv.sd_setImage(with: URL(string: imageURLs[indexOfCurrentPage - 1]), placeholderImage: blackImage, options: SDWebImageOptions.retryFailed, completed: { [weak imgv, weak waitView] (img: UIImage?, err: Error?, type: SDImageCacheType, url: URL?) in
                        imgv?.isHidden = false
                        waitView?.removeFromSuperview()
                    })
                }
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === imageScrollView {
            let page = (scrollView.contentOffset.x + scrollView.bounds.size.width / 2) / scrollView.bounds.size.width
            
            if indexOfCurrentPage != Int(page) + 1{
                for imageSV in self.allImageView {
                    imageSV.contentSize = CGSize(width: self.frame.size.width, height: self.frame.size.height)
                    
                    imageSV.contentOffset = CGPoint.zero
                    if let imgv = imageSV.subviews.first as? UIImageView {
                        imgv.transform = CGAffineTransform(scaleX: 1, y: 1)
                        imgv.center = CGPoint(x: imageSV.contentSize.width / 2 , y: imageSV.contentSize.height / 2)
                    }
                }
            }
            self.indexOfCurrentPage = Int(page + 1)
            if indexOfCurrentPage > 0 && indexOfCurrentPage <= imageURLs.count{
                
                self.updateNumberTitle()
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
    }
    
    private func setOpenWindowLevel() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.keyWindow {
                window.windowLevel = UIWindowLevelStatusBar + 1
            }
        }

    }
    
    private func setCloseWindowLebel() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.keyWindow {
                window.windowLevel = UIWindowLevelNormal
            }
        }
    }
    
    internal func show() {
        let mainWindow: UIWindow =
            UIApplication.shared.keyWindow! as UIWindow
        mainWindow.addSubview(self)
        self.setOpenWindowLevel()
        UIView.animate(withDuration: 0.3, animations:{
            self.backgroundColor = UIColor(white:0, alpha: 1)
        })
    }
}
