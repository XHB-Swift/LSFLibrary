//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/17.
//

import UIKit

public struct AttributedInterpotationString {
    
    public let attributedString: NSAttributedString
}

extension AttributedInterpotationString: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.attributedString = NSAttributedString(string: value)
    }
}

extension AttributedInterpotationString: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.attributedString)
    }
}

extension AttributedInterpotationString: ExpressibleByStringInterpolation {
    
    public init(stringInterpolation: StringInterpolation) {
        self.attributedString = NSAttributedString(attributedString: stringInterpolation.attributedString)
    }
    
    public struct StringInterpolation: StringInterpolationProtocol {
        
        public var attributedString: NSMutableAttributedString
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            self.attributedString = NSMutableAttributedString()
        }
        
        public func appendLiteral(_ literal: String) {
            let attrs: [NSAttributedString.Key : Any] = [
                .font : UIFont.systemFont(ofSize: 16) as Any,
                .foregroundColor : UIColor.black as Any
            ]
            appendInterpolation(literal, attrs)
        }
        
        public func appendInterpolation(_ string: String, _ attributes: [NSAttributedString.Key : Any]) {
            let astr = NSAttributedString(string: string, attributes: attributes)
            self.attributedString.append(astr)
        }
        
        public func appendInterpolation(image: UIImage, scale: CGFloat = 1.0) {
            let attachment = NSTextAttachment()
            let size = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            attachment.image = image
            attachment.bounds = CGRect(origin: .zero, size: size)
            self.attributedString.append(NSAttributedString(attachment: attachment))
        }
    }
}

extension AttributedInterpotationString {
    
    public struct Style {
        
        public let attributes: [NSAttributedString.Key : Any]
        
        public static func font(_ font: UIFont) -> Style {
            return .init(attributes: [.font : font])
        }
        
        public static func color(_ color: UIColor) -> Style {
            return .init(attributes: [.foregroundColor : color])
        }
        
        public static func color(_ hex: UInt, _ alpha: CGFloat = 1.0) -> Style {
            return .init(attributes: [.foregroundColor : UIColor(hex: hex, alpha: alpha)])
        }
        
        public static func bgColor(_ color: UIColor) -> Style {
            return .init(attributes: [.backgroundColor : color])
        }
        
        public static func bgColor(_ hex: UInt, _ alpha: CGFloat = 1.0) -> Style {
            return .init(attributes: [.backgroundColor : UIColor(hex: hex, alpha: alpha)])
        }
        
        public static func link(_ link: URL) -> Style {
            return .init(attributes: [.link : link])
        }
        
        public static func link(_ link: String) -> Style {
            return .init(attributes: [.link : link])
        }
        
        public static func underline(_ color: UIColor, _ style: NSUnderlineStyle) -> Style {
            return .init(attributes: [
                .underlineStyle : style.rawValue,
                .underlineColor : color,
            ])
        }
        
        public static func underline(_ hexColor: UInt, _ alpha: CGFloat = 1.0, _ style: NSUnderlineStyle) -> Style {
            return .init(attributes: [
                .underlineStyle : style.rawValue,
                .underlineColor : UIColor(hex: hexColor, alpha: alpha),
            ])
        }
        
        public static func oblique(_ oblique: CGFloat = 0.1) -> Style {
            return .init(attributes: [.obliqueness : oblique])
        }
        
        public static func paragraph(_ closure: () -> NSParagraphStyle) -> Style {
            return .init(attributes: [
                .paragraphStyle: closure()
            ])
        }
        
        public static func alignment(_ alignment: NSTextAlignment) -> Self {
            return .paragraph({
                let p = NSMutableParagraphStyle()
                p.alignment = alignment
                return p
            })
        }
        
        public static func lineHeight(_ lineHeight: CGFloat) -> Self {
            return .paragraph({
                let p = NSMutableParagraphStyle()
                p.minimumLineHeight = lineHeight
                p.maximumLineHeight = lineHeight
                return p
            })
        }
        
        public static func lineSpacing(_ lineSpacing: CGFloat) -> Self {
            return .paragraph({
                let p = NSMutableParagraphStyle()
                p.lineSpacing = lineSpacing
                return p
            })
        }
        
        public static func paragraphSpacing(_ paragraphSpacing: CGFloat) -> Self {
            return .paragraph({
                let p = NSMutableParagraphStyle()
                p.paragraphSpacing = paragraphSpacing
                return p
            })
        }
        
        public static func lineBreakMode(_ lineBreakMode: NSLineBreakMode) -> Self {
            return .paragraph({
                let p = NSMutableParagraphStyle()
                p.lineBreakMode = lineBreakMode
                return p
            })
        }
        
        public static func minimumLineHeight(_ minimumLineHeight: CGFloat) -> Self {
            return .paragraph({
                let p = NSMutableParagraphStyle()
                p.minimumLineHeight = minimumLineHeight
                return p
            })
        }
        
        public static func maximumLineHeight(_ maximumLineHeight: CGFloat) -> Self {
            return .paragraph({
                let p = NSMutableParagraphStyle()
                p.maximumLineHeight = maximumLineHeight
                return p
            })
        }
    }
}

extension AttributedInterpotationString.StringInterpolation {
    public func appendInterpolation(_ string: String, _ styles: AttributedInterpotationString.Style...) {
        var attrs: [NSAttributedString.Key : Any] = [
            .font : UIFont.systemFont(ofSize: 16) as Any,
            .foregroundColor : UIColor.black as Any
        ]
        let p: NSMutableParagraphStyle = .init()
        styles.forEach { style in
            var attributes = style.attributes
            if let ps = attributes[.paragraphStyle] as? NSParagraphStyle {
                p.setParagraphStyle(ps)
            }
            attrs.merge(style.attributes, uniquingKeysWith: { $1 })
        }
        if attrs[.paragraphStyle] != nil {
            attrs[.paragraphStyle] = p
        }
        attributedString.append(.init(string: string, attributes: attrs))
    }
    
    public func appendInterpolation(_ string: AttributedInterpotationString, _ styles: AttributedInterpotationString.Style...) {
        var attrs: [NSAttributedString.Key : Any] = [
            .font : UIFont.systemFont(ofSize: 16) as Any,
            .foregroundColor : UIColor.black as Any
        ]
        let p: NSMutableParagraphStyle = .init()
        styles.forEach { style in
            var attributes = style.attributes
            if let ps = attributes[.paragraphStyle] as? NSParagraphStyle {
                p.setParagraphStyle(ps)
            }
            attrs.merge(style.attributes, uniquingKeysWith: { $1 })
        }
        if attrs[.paragraphStyle] != nil {
            attrs[.paragraphStyle] = p
        }
        let mas = NSMutableAttributedString(attributedString: string.attributedString)
        let fullRange = NSRange(mas.string.startIndex..<mas.string.endIndex, in: mas.string)
        mas.addAttributes(attrs, range: fullRange)
        attributedString.append(mas)
    }
}

