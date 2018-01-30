//
//  ViewBundle.swift
//  SwipeMenuViewController
//
//  Created by 森下 侑亮 on 2018/01/30.
//  Copyright © 2018年 yysskk. All rights reserved.
//

import UIKit

protocol Initializable {
    init()
}

extension NSObject: Initializable {}

struct ViewBundle<T: Initializable> where T: NSObjectProtocol {
    private var nib: [String: UINib] = [:]
    private var `class`: [String: T.Type] = [:]
    
    mutating func register(ofNib nib: UINib?, for identifier: String) {
        self.nib[identifier] = nib
        self.class[identifier] = nil
    }
    
    mutating func register(ofClass cellClass: T.Type, for identifier: String) {
        self.class[identifier] = cellClass
        self.nib[identifier] = nil
    }
    
    private func nibInstantiate(with identifier: String) -> T? {
        return self.nib[identifier]?.instantiate(withOwner: nil, options: nil).first as? T
    }
    
    private func classInstantiate(with identifier: String) -> T? {
        return self.class[identifier]?.init()
    }
    
    func instantiate(with identifier: String) -> T {
        if let cell = nibInstantiate(with: identifier) ?? classInstantiate(with: identifier) {
            return cell
        } else {
            fatalError()
        }
    }
}
