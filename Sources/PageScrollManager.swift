//
//  JLPageScrollManager.swift
//  niuwa
//
//  Created by dcj on 16/3/9.
//  Copyright © 2016年 Knoala. All rights reserved.
//

import Foundation

struct PageScrollModel {
    var pageViewCotroller: UIViewController
    var pageTitle: String
}

protocol PageScrollManagerDelegate : class {

    func pageScrollMainViewController() -> BaseViewController
    func pageScrollModels() -> [PageScrollModel]
    func didSelectViewController(_ selectedViewController: UIViewController?)

}
extension PageScrollManagerDelegate {
    func didSelectViewController(_ selectedViewController: UIViewController?) {}

}

class PageScrollManager: NSObject {

    var loopable: Bool = false
    private var animationFinish: Bool = true
    var pageTitleWidth: CGFloat = -1.0
    var titleLeftSpace: CGFloat = 0 // 整个title容器距离左边的距离
    var titleRightSpace: CGFloat = 0 // 整个title容器距离右边的距离
    var showDividerLine: Bool = false

    typealias TabButtonCustomizer = (_ button: UIButton, _ index: NSInteger) -> Void
    var customizer: TabButtonCustomizer?

    //定义titleview的内容，点击事件还是会放在 scrollmanager 统一定义和实现
    typealias TabViewCustomizer = (_ index: NSInteger) -> UIView?
    var tabViewCustomizer: TabViewCustomizer?

    fileprivate weak var pageScrollManagerDelegate: PageScrollManagerDelegate!
    fileprivate var pageViewController: UIPageViewController

    fileprivate var pageScrollModels   = [PageScrollModel]()

    fileprivate var selecteIndex       = 0
    var defaultIndex       = 0

    fileprivate var titleTabScrollView: UIScrollView?

    fileprivate var animationView: UIView?
    fileprivate var dividerLineImageView: UIImageView?

    init(delegate: PageScrollManagerDelegate) {

        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        super.init()

        pageViewController.delegate = self
        pageViewController.dataSource = self

        pageScrollManagerDelegate = delegate

        pageScrollModels = pageScrollManagerDelegate.pageScrollModels()
    }

    func scrollToIndex(_ index: Int) {
        selectedAnimation(index)
        setSelectedTitle(index)
        rollToSelectedPage(index)
        pageScrollManagerDelegate.didSelectViewController(self.pageScrollModels[index].pageViewCotroller)
    }

    //MARK: - private

    fileprivate func setContentViewContrains() {
        let contentView = self.contentView()
        mainViewController().view.insertSubview(contentView, at:0)
        let height = self.titleLabelHeight() + CGFloat(20)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        mainViewController().view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[contentView]-0-|", options:.directionLeadingToTrailing, metrics:nil, views:["contentView":contentView]))
        let top = NSLayoutConstraint(item:contentView, attribute:.top, relatedBy:.equal, toItem:mainViewController().view, attribute:.top, multiplier:1, constant:height)
        let bottom = NSLayoutConstraint(item:contentView, attribute:.bottom, relatedBy:.equal, toItem:mainViewController().view, attribute:.bottom, multiplier:1, constant:0)
        mainViewController().view.addConstraints([top, bottom])

    }
    fileprivate func createAnimationView() {

        if animationView == nil {

            let titleleft = titleTabScrollView!.viewWithTag(tltleButtonTag() + selecteIndex)?.left ?? 0

            
            animationView = UIView(frame: CGRect(x: titleleft, y: titleLabelHeight()-2, width: titleLabelWidth(), height: 2))
            titleTabScrollView?.addSubview(animationView!)
            animationView?.autoresizingMask = [.flexibleWidth, .flexibleRightMargin, .flexibleLeftMargin]
            animationView?.backgroundColor = Theme.Color.brandGreen
        }
    }

    func updateWidth() {

        guard let titleTabScrollView = titleTabScrollView, let animationView = animationView else {return}

        titleTabScrollView.frame = CGRect(x: titleLeftSpace, y: 20, width: mainWidth() - titleLeftSpace - titleRightSpace, height: titleLabelHeight())
        animationView.frame = CGRect(x: titleSpace(), y: titleLabelHeight()-2, width: titleLabelWidth(), height: 2)
        selectedAnimation(selecteIndex)
    }

    fileprivate func createTitleView() {

        titleTabScrollView = UIScrollView(frame: CGRect(x: titleLeftSpace, y: 20, width: mainWidth() - titleLeftSpace - titleRightSpace, height: titleLabelHeight()))
        titleTabScrollView?.autoresizingMask = .flexibleWidth
        titleTabScrollView!.backgroundColor = UIColor.white
        mainViewController().view.addSubview(titleTabScrollView!)
        mainViewController().view.sendSubview(toBack: titleTabScrollView!)

        for index in 0 ..< pageScrollModels.count {
            var titleView: UIView
            if let tempTitleView = tabViewCustomizer?(index) {
                titleView = tempTitleView
                titleView.autoresizingMask = [.flexibleWidth, .flexibleRightMargin, .flexibleLeftMargin]
                titleView.tag = tltleButtonTag() + index
            } else {

                let titleButton = UIButton(type:.custom)
                titleButton.autoresizingMask = [.flexibleWidth, .flexibleRightMargin, .flexibleLeftMargin]
                titleButton.setTitle(pageScrollModels[index].pageTitle, for:.normal)
                titleButton.addTarget(self, action:#selector(PageScrollManager.titleButtonPress(_:)), for:.touchUpInside)
                titleButton.setTitleColor(Theme.Color.brandGreen, for:.selected)
                titleButton.setTitleColor(Theme.Color.darkGrey, for:.normal)
                if index == defaultIndex {
                    titleButton.isSelected = true
                }
                titleButton.titleLabel?.font = Theme.Font.pageTitle
                titleButton.tag = tltleButtonTag() + index

                if let customizer = customizer {
                    customizer(titleButton, index)
                }
                titleView = titleButton
            }


            titleView.frame = CGRect(x: CGFloat(index) * titleLabelWidth() + CGFloat(index + 1)*titleSpace(), y: 0, width: titleLabelWidth(), height: titleLabelHeight())


            titleTabScrollView?.addSubview(titleView)
        }
        dividerLineImageView = UIImageView(frame:CGRect(x: 0, y: titleTabScrollView!.height-1, width: titleTabScrollView!.width, height: 1))
        titleTabScrollView?.addSubview(dividerLineImageView!)
        dividerLineImageView?.image = UIImage(named:"Divider-Line")
        dividerLineImageView?.autoresizingMask = .flexibleWidth
        dividerLineImageView?.isHidden = !showDividerLine

    }

    fileprivate func cleanUpTitleView() {
        guard let views = titleTabScrollView?.subviews else { return }
        for tempView in views {
            (tempView as AnyObject).removeFromSuperview()
        }
    }
    fileprivate func selectedAnimation(_ selectedIndex: Int) {

        let titleleft = titleTabScrollView!.viewWithTag(tltleButtonTag() + selectedIndex)?.left ?? 0

        if shouldNoAnimation() {
            animationView?.left = titleleft

        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.animationView?.left = titleleft
                }, completion:nil)

        }
    }
    fileprivate func setSelectedTitle(_ selectedIndex: Int) {
        for index in 0 ..< pageScrollModels.count {
            if let tempButton = titleTabScrollView?.viewWithTag(index + tltleButtonTag()) as? UIButton {
                if index == selectedIndex {
                    tempButton.isSelected = true
                } else {
                    tempButton.isSelected = false
                }
            }
            if var titleView = titleTabScrollView?.viewWithTag(index + tltleButtonTag()) as? Selectable {
                if index == selectedIndex {
                    titleView.selected = true
                } else {
                    titleView.selected = false
                }
            }
        }
    }
    fileprivate func rollToSelectedPage(_ selectedIndex: Int) {

        let selectedViewController = pageScrollModels[selectedIndex].pageViewCotroller
        if self.selecteIndex == selectedIndex {
            pageViewController.setViewControllers([selectedViewController], direction: .forward, animated: !shouldNoAnimation(), completion: {done in
                //http://stackoverflow.com/questions/14220289/removing-a-view-controller-from-uipageviewcontroller 
                //为了修复pageview controller 在Scroll transition style 下的 crash
                if !self.shouldNoAnimation() {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.pageViewController.setViewControllers([selectedViewController], direction : .forward, animated : false, completion: nil)
                    })
                }

                self.selecteIndex = selectedIndex
//                self.animationFinish = true;
            })
        } else {

            if selectedIndex>selecteIndex {
                pageViewController.setViewControllers([selectedViewController], direction: .forward, animated: !shouldNoAnimation(), completion: {done in

                    if !self.shouldNoAnimation() {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.pageViewController.setViewControllers([selectedViewController], direction: .forward, animated: false, completion:nil)
                        })
                    }

                    self.selecteIndex = selectedIndex
//                    self.animationFinish = true;
                })
            } else {
                pageViewController.setViewControllers([selectedViewController], direction: .reverse, animated: !shouldNoAnimation(), completion: {done in
                    if !self.shouldNoAnimation() {
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.pageViewController.setViewControllers([selectedViewController], direction: .reverse, animated: false, completion:nil)
                        })
                    }
                    self.selecteIndex = selectedIndex
//                    self.animationFinish = true
                })
            }
        }
    }
    //MARK: -title button 点击
    func titleButtonPress(_ sender: UIView) {

        let clickIndex = sender.tag - tltleButtonTag()
        if selecteIndex == clickIndex {
            return
        }
//        guard animationFinish else {return}
//        self.animationFinish = false;

        scrollToIndex(clickIndex)
    }

    //MARK: - reload

    func setupView() {
        mainViewController().addChildViewController(pageViewController)
        mainViewController().view.addSubview(pageViewController.view)
        let defaultViewController = pageScrollModels[defaultIndex].pageViewCotroller
        selecteIndex = defaultIndex
        pageViewController.setViewControllers([defaultViewController], direction: .forward, animated: true, completion: {done in
        })
        createTitleView()
        setContentViewContrains()
        createAnimationView()
    }
}
//MARK: - getter
extension PageScrollManager {
    //这里用screen的width 是因为加入xib文件后，viewdidload取到的frame大小可能并不是正确的size，所以暂时考虑用mainscreen
    func mainWidth() -> CGFloat {
        return mainViewController().view.width
    }

    func mainViewController() -> BaseViewController {
        return (pageScrollManagerDelegate?.pageScrollMainViewController())!
    }
    func titleLabelHeight() -> CGFloat {
        return 44
    }
    func titleLabelWidth() -> CGFloat {
        if pageTitleWidth <= 0 {
            return (mainWidth() - titleLeftSpace - titleRightSpace)/CGFloat(pageScrollModels.count)
        } else {
            return pageTitleWidth
        }
    }

    func titleSpace() -> CGFloat {

        return (mainWidth() - titleLeftSpace - titleRightSpace - CGFloat(pageScrollModels.count) * titleLabelWidth())/5
    }

    func contentView() -> UIView {
        return pageViewController.view
    }
    func tltleButtonTag() -> Int {
        return 2000
    }
}
//MARK: - pageViewController delegate
extension PageScrollManager:UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index: Int = indexOfViewController(viewController)
        index -= 1
        if index >= 0 {
            return pageScrollModels[index].pageViewCotroller
        } else {
            if loopable {
                index = (index + pageScrollModels.count) % pageScrollModels.count
                return pageScrollModels[index].pageViewCotroller
            }
        }
        return nil
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index: Int = indexOfViewController(viewController)
        index += 1
        if index < (pageScrollModels.count) {
            return pageScrollModels[index].pageViewCotroller
        } else {
            if loopable {
                index = index % pageScrollModels.count
                return pageScrollModels[index].pageViewCotroller
            }
        }
        return nil
    }
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
//        self.animationFinish = true;
        let viewController = pageViewController.viewControllers?[0]
        let index = indexOfViewController(viewController!)
        if index != selecteIndex {
            setSelectedTitle(index)
            selectedAnimation(index)
            selecteIndex = index
            pageScrollManagerDelegate.didSelectViewController(viewController)
        }

    }
    func indexOfViewController(_ viewController: UIViewController) -> Int {
        for index in 0 ..< pageScrollModels.count {
            if viewController == pageScrollModels[index].pageViewCotroller {
                return index
            }
        }
        return 0
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {

    }
    func shouldNoAnimation() -> Bool {
        return true
//        let size = UIScreen.mainScreen().bounds.size;
//        return __CGSizeEqualToSize(size, CGSizeMake(320,480))
    }

}
