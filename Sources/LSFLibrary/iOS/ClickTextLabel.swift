//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/26.
//

import UIKit

extension NSAttributedString.Key {
    
    public static let click: Self = .init(rawValue: "ClickTextLabel.Click")
    public static let highlightedColor: Self = .init(rawValue: "ClickTextLabel.HighlightedColor")
}

extension AttributedInterpotationString.Style {
    
    public static func click(_ wrappedValue: Any) -> Self {
        .init(attributes: [.click: wrappedValue])
    }
    
    public static func highlightedColor(_ color: UInt) -> Self {
        .init(attributes: [.highlightedColor: UIColor(hex: color)])
    }
}

public class ClickTextLabel: UILabel {
    
    public typealias Handler = (_ text: String, _ wrappedValue: Any) -> Void
    
    public var handler: Handler?
    
    private var textStorage: NSTextStorage?
    private var textContainer: NSTextContainer?
    private var textLayoutManager: NSLayoutManager?
    private var lineRanges: [NSRange] = []
    private var clickRanges: [NSRange: Model] = [:]
    
    private let defaultAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16),
        .foregroundColor: UIColor.black
    ]
    
    public override var text: String? {
        get { attributedText?.string }
        set {
            if let txt = newValue {
                attributedText = .init(string: txt, attributes: defaultAttributes)
            } else {
                attributedText = nil
            }
        }
    }
    
    public override var attributedText: NSAttributedString? {
        get { super.attributedText }
        set {
            var mAttrTxt: NSMutableAttributedString? = nil
            if let attrTxt = newValue {
                let defaultFont: UIFont = .systemFont(ofSize: 16)
                mAttrTxt = .init(attributedString: attrTxt)
                let wholeRange: NSRange = .init(location: 0, length: attrTxt.length)
                attrTxt.enumerateAttributes(in: wholeRange,
                                            options: [.init(rawValue: 0)],
                                            using: { attributes, range, stop in
                    if let _ = attributes[.font] {
                        mAttrTxt?.addAttribute(.font, value: defaultFont, range: wholeRange)
                    }
                    if let wrappedValue = attributes[.click],
                       let text = attrTxt.string[range] {
                        let model: Model = .init(text: text,
                                                 range: range,
                                                 wrappedValue: wrappedValue)
                        model.normalColor = attributes[.foregroundColor] as? UIColor
                        model.highlightedColor = attributes[.highlightedColor] as? UIColor
                        clickRanges[range] = model
                    }
                })
            }
            super.attributedText = mAttrTxt
        }
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        numberOfLines = 0
        isUserInteractionEnabled = true
    }
    
    public override func sizeToFit() {
        let fitsSize: CGSize
        if let superViewFrame = superview?.frame {
            fitsSize = superViewFrame.size
        } else {
            fitsSize = app.screen?.bounds.size ?? .init(width: CGFLOAT_MAX, height: CGFLOAT_MAX)
        }
        size = sizeThatFits(fitsSize)
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        var re_size: CGSize = .zero
        if let attrTxt = attributedText {
            re_size = attrTxt .boundingRect(with: size,
                                            options: [.usesFontLeading, .usesLineFragmentOrigin],
                                            context: nil).size
            re_size = .init(width: ceil(re_size.width),
                            height: ceil(re_size.height))
            updateTextLayout(.init(width: re_size.width, height: re_size.height + 100), attrTxt)
        } else {
            lineRanges.removeAll()
            clickRanges.removeAll()
            textStorage = nil
            textContainer = nil
            textLayoutManager = nil
        }
        return re_size
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchedPoint = touch.location(in: self)
        guard let model = clickRanges.first(where: { $0.value.contains(point: touchedPoint) })?.value else { return }
//        print("model = \(model)")
        if let attrTxt = attributedText, let highlightedColor = model.highlightedColor {
            let mAttrTxt: NSMutableAttributedString = .init(attributedString: attrTxt)
            mAttrTxt.addAttribute(.foregroundColor, value: highlightedColor, range: model.range)
            super.attributedText = mAttrTxt
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchedPoint = touch.location(in: self)
        guard let model = clickRanges.first(where: { $0.value.contains(point: touchedPoint) })?.value else { return }
//        print("model = \(model)")
        if let attrTxt = attributedText, let normalColor = model.normalColor {
            let mAttrTxt: NSMutableAttributedString = .init(attributedString: attrTxt)
            mAttrTxt.addAttribute(.foregroundColor, value: normalColor, range: model.range)
            super.attributedText = mAttrTxt
        }
        handler?(model.text,model.wrappedValue)
    }
    
    private func updateTextLayout(_ size: CGSize, _ attrTxt: NSAttributedString) {
        if clickRanges.isEmpty { return }
        textStorage = .init(attributedString: attrTxt)
        let txtLayout: NSLayoutManager = .init()
        textStorage?.addLayoutManager(txtLayout)
        let txtContainer: NSTextContainer = .init(size: size)
        txtContainer.lineBreakMode = lineBreakMode
        txtContainer.lineFragmentPadding = 0
        txtLayout.addTextContainer(txtContainer)
        textContainer = txtContainer
        textLayoutManager = txtLayout
        updateLines(with: size, attrTxt)
        updateClickRects()
    }
    
    private func updateLines(with size: CGSize, _ attrTxt: NSAttributedString) {
        let path: CGMutablePath = .init()
        path.addRect(.init(origin: .zero, size: size))
        let framesetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attrTxt as CFAttributedString)
        let ctframe: CTFrame = CTFramesetterCreateFrame(framesetter, .init(location: 0, length: 0), path, nil)
        let lines = CTFrameGetLines(ctframe)
        var index: CFIndex = 0
        let numberOfLines = CFArrayGetCount(lines)
        while index < numberOfLines {
            let line: CTLine = unsafeBitCast(CFArrayGetValueAtIndex(lines, index), to: CTLine.self)
            let lineRange: CFRange = CTLineGetStringRange(line)
            self.lineRanges.append(.init(location: lineRange.location, length: lineRange.length))
            index += 1
        }
//        print("lineRanges = \(lineRanges)")
    }
    
    private func updateClickRects() {
        if !lineRanges.isEmpty {
            lineRanges.forEach { lineRange in
                clickRanges.forEach { _, value in
                    let intersection = NSIntersectionRange(value.leftRange, lineRange)
                    if intersection.length > 0 {
                        if NSMaxRange(value.leftRange) > NSMaxRange(lineRange) {
                            value.add(rect: rect(forCharacter: intersection))
                            value.leftRange = .init(location: NSMaxRange(intersection),
                                                    length: value.leftRange.length - intersection.length)
                            
                        } else {
                            value.add(rect: rect(forCharacter: value.leftRange))
                        }
                    }
                }
            }
        } else {
            clickRanges.forEach { _, value in
                value.add(rect: rect(forCharacter: value.range))
            }
        }
//        print("clickRanges = \(clickRanges)")
    }
    
    private func rect(forCharacter range: NSRange) -> CGRect {
        guard range.length > 0 else { return .zero }
        guard let txtLayout = textLayoutManager,
              let txtContainer = textContainer else { return .zero }
        var glyphRange: NSRange = .init(location: NSNotFound, length: 0)
        _ = txtLayout.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        guard glyphRange.length > 0 else { return .zero }
        return txtLayout.boundingRect(forGlyphRange: glyphRange, in: txtContainer)
    }
}

extension ClickTextLabel {
    
    fileprivate final class Model {
        let text: String
        let range: NSRange
        let wrappedValue: Any
        
        var normalColor: UIColor? = nil
        var highlightedColor: UIColor? = nil
        var leftRange: NSRange = .init(location: NSNotFound, length: 0)
        
        private var clickRects: [CGRect] = []
        private var pushedRanges: [NSRange] = []
        
        init(text: String, range: NSRange, wrappedValue: Any, clickRects: [CGRect] = []) {
            self.text = text
            self.range = range
            self.leftRange = range
            self.wrappedValue = wrappedValue
            self.clickRects = clickRects
        }
        
        func add(rect: CGRect) {
            if rect == .zero { return }
            if clickRects.contains(rect) { return }
            clickRects.append(rect)
        }
        
        func contains(point: CGPoint) -> Bool {
            clickRects.first(where: { $0.contains(point) }) != nil
        }
    }
}

extension ClickTextLabel.Model: CustomStringConvertible {
    var description: String {
        "{text = \(text)\nrange = \(range)\nwrapped = \(wrappedValue)\nrects = \(clickRects)}\n"
    }
}
