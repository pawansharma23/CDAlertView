//
//  AlertView.swift
//  AlertView
//
//  Created by Candost Dagdeviren on 10/30/2016.
//  Copyright (c) 2016 Candost Dagdeviren. All rights reserved.
//

import Foundation

public enum AlertViewType {
    case error, warning, success, notification
}

fileprivate protocol AlertViewActionDelegate: class {
    func didTap(action: AlertViewAction)
}

open class AlertViewAction: NSObject {
    public var buttonTitle: String?
    public var buttonTextColor: UIColor?
    public var buttonFont: UIFont?
    public var buttonBackgroundColor: UIColor?

    fileprivate weak var delegate: AlertViewActionDelegate?

    private var handlerBlock: ((AlertViewAction) -> Swift.Void)?

    public convenience init(title: String?,
                            font: UIFont? = UIFont.systemFont(ofSize: 17),
                            textColor: UIColor? = UIColor(red: 27/255, green: 169/255, blue: 225/255, alpha: 1),
                            backgroundColor: UIColor? = UIColor.white.withAlphaComponent(0.9),
                            handler: ((AlertViewAction) -> Swift.Void)? = nil) {
        self.init()
        buttonTitle = title
        buttonTextColor = textColor
        buttonFont = font
        buttonBackgroundColor = backgroundColor
        handlerBlock = handler
    }

    func didTap() {
        if let handler = handlerBlock {
            handler(self)
        }
        self.delegate?.didTap(action: self)
    }
}

open class AlertView: UIView {

    public var actionSeparatorColor: UIColor? = UIColor(red: 50/255, green: 51/255, blue: 53/255, alpha: 0.12)

    private struct AlertViewConstants {
        let headerHeight: CGFloat = 56
        let popupWidth: CGFloat = 256
    }


    private var buttonsHeight: Int {
        get {
            return self.actions.count > 0 ? 44 : 0
        }
    }

    private let constants = AlertViewConstants()
    private var backgroundView: UIView = UIView(frame: .zero)
    private var popupView: UIView = UIView(frame: .zero)
    private var coverView: UIView = UIView(frame: .zero)
    private var completionBlock: ((AlertView) -> Swift.Void)?
    private var contentStackView: UIStackView = UIStackView(frame: .zero)
    private var buttonContainer: UIStackView = UIStackView(frame: .zero)
    private var headerView: AlertHeaderView!
    private var buttonView: UIView = UIView(frame: .zero)
    private var titleLabel: UILabel = UILabel(frame: .zero)
    private var messageLabel: UILabel = UILabel(frame: .zero)
    private var type: AlertViewType!
    private lazy var actions: [AlertViewAction] = [AlertViewAction]()

    public convenience init(title: String?, message: String?, type: AlertViewType? = .notification) {
        self.init(frame: .zero)

        self.type = type
        backgroundColor = UIColor(red: 50/255, green: 51/255, blue: 53/255, alpha: 0.4)
        if let t = title {
            titleLabel.text = t
        }

        if let m = message {
            messageLabel.text = m
        }

        self.type = type
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        popupView.layer.shadowColor = UIColor.black.cgColor
        popupView.layer.shadowOpacity = 0.2
        popupView.layer.shadowRadius = 4
        popupView.layer.shadowOffset = CGSize.zero
        popupView.layer.masksToBounds = false
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.0, y: popupView.bounds.size.height))
        path.addLine(to: CGPoint(x: 0, y: constants.headerHeight))
        path.addLine(to: CGPoint(x: popupView.bounds.size.width, y: CGFloat(constants.headerHeight-5)))
        path.addLine(to: CGPoint(x: popupView.bounds.size.width, y: popupView.bounds.size.height))
        path.close()
        popupView.layer.shadowPath = path.cgPath
        popupView.layer.masksToBounds = false
    }

    public func show(with completion:((AlertView) -> Swift.Void)?) {
        UIApplication.shared.keyWindow?.addSubview(self)
        self.alignToParent(with: 0)
        self.addSubview(self.backgroundView)
        backgroundView.alignToParent(with: 0)
        self.createViews()
        self.reloadActionButtons()
        completionBlock = completion
    }

    public func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.alpha = 0
        }, completion: { (finished) in
            if finished {
                self.removeFromSuperview()
                if let completion = self.completionBlock {
                    completion(self)
                }
            }
        })
    }

    public func add(action: AlertViewAction) {
        assert(actions.count < 3, "There can't be more than 3 actions")
        actions.append(action)
    }

    // MARK: Private

    private func createViews() {
        popupView.backgroundColor = UIColor.clear
        backgroundView.addSubview(popupView)
        createHeaderView()
        createButtonContainer()
        createStackView()
        createTitleLabel()
        createMessageLabel()

        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.centerHorizontally()
        popupView.centerVertically()
        popupView.setWidth(constants.popupWidth)
        popupView.setMaxHeight(430)
        popupView.sizeToFit()
        popupView.layoutIfNeeded()
        if actions.count == 0 {
            roundBottomOfCoverView()
        }
    }

    private func roundBottomOfCoverView() {
        let roundCornersPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: Int(constants.popupWidth), height: Int(coverView.frame.size.height)), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8.0, height: 8.0))
        let roundLayer = CAShapeLayer()
        roundLayer.path = roundCornersPath.cgPath
        coverView.layer.mask = roundLayer
    }

    private func createHeaderView() {
        headerView = AlertHeaderView(type: type)
        headerView.backgroundColor = UIColor.clear
        popupView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.alignTopToParent(with: 0, multiplier: 1)
        headerView.alignLeftToParent(with: 0)
        headerView.alignRightToParent(with: 0)
        headerView.setHeight(constants.headerHeight)
    }

    private func createButtonContainer() {
        buttonView.backgroundColor = UIColor.clear
        buttonView.layer.masksToBounds = true
        let roundCornersPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: Int(constants.popupWidth), height: buttonsHeight), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8.0, height: 8.0))
        let roundLayer = CAShapeLayer()
        roundLayer.path = roundCornersPath.cgPath
        buttonView.layer.mask = roundLayer
        popupView.addSubview(buttonView)
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        buttonView.alignBottomToParent(with: 0)
        buttonView.alignLeftToParent(with: 0)
        buttonView.alignRightToParent(with: 0)
        if actions.count == 0 {
            buttonView.setHeight(0)
        } else {
            buttonView.setHeight(CGFloat(buttonsHeight))
            let backgroundColoredView = UIView(frame: .zero)
            backgroundColoredView.backgroundColor = actionSeparatorColor
            buttonView.addSubview(backgroundColoredView)
            backgroundColoredView.alignToParent(with: 0)

            buttonContainer.spacing = 1
            buttonContainer.axis = .horizontal
            backgroundColoredView.addSubview(buttonContainer)
            buttonContainer.translatesAutoresizingMaskIntoConstraints = false
            let constraint = buttonContainer.alignTopToParent(with: 1, multiplier: 0.5)
            buttonContainer.alignBottomToParent(with: 0)
            buttonContainer.alignLeftToParent(with: 0)
            buttonContainer.alignRightToParent(with: 0)
        }
    }

    private func createStackView() {
        coverView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        popupView.addSubview(coverView)
        coverView.translatesAutoresizingMaskIntoConstraints = false
        coverView.alignLeftToParent(with: 0)
        coverView.alignRightToParent(with: 0)
        coverView.place(below: headerView, margin: 0)
        coverView.place(above: buttonView, margin: 0)
        contentStackView.distribution = .equalSpacing
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        coverView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.alignTopToParent(with: 0, multiplier: 1)
        contentStackView.alignBottomToParent(with: 16)
        contentStackView.alignRightToParent(with: 16)
        contentStackView.alignLeftToParent(with: 16)
    }

    private func createTitleLabel() {
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.setMaxHeight(100)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        contentStackView.addArrangedSubview(titleLabel)
    }

    private func createMessageLabel() {
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.setMaxHeight(290)
        messageLabel.font = UIFont.systemFont(ofSize: 13)
        contentStackView.addArrangedSubview(messageLabel)
    }

    private func reloadActionButtons() {
        for action in buttonContainer.arrangedSubviews {
            buttonContainer.removeArrangedSubview(action)
        }

        for action in actions {
            action.delegate = self
            let button = UIButton(type: .system)
            button.backgroundColor = action.buttonBackgroundColor
            button.setTitle(action.buttonTitle, for: .normal)
            button.setTitleColor(action.buttonTextColor, for: .normal)
            button.titleLabel?.font = action.buttonFont
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.addTarget(action, action: #selector(action.didTap), for: .touchUpInside)
            buttonContainer.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setWidth(buttonContainer.frame.size.width/CGFloat(actions.count))
            button.setHeight(CGFloat(buttonsHeight - 1))
        }
    }
}

extension AlertView: AlertViewActionDelegate {
    internal func didTap(action: AlertViewAction) {
        self.hide()
    }
}