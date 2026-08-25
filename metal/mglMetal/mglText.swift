//
//  mglText.swift
//  mglMetal
//
//  Created by Justin Gardner and GPT-5.6-terra on Aug 24, 2026
//  Copyright © 2026 GRU.
//

import Foundation
import MetalKit
import CoreText
import CoreGraphics


// The result of rendering a string into a normal mgl Metal texture.
struct mglRenderedTextTexture {
    let texture: MTLTexture
    let width: UInt32
    let height: UInt32
}


// Render text with Core Text/Core Graphics, then convert it into the
// .rgba32Float buffer-backed texture format used by mglCreateTexture.
enum mglTextTextureRenderer {

    // Create an mgl-compatible Metal texture containing rendered text.
    //
    // The resulting texture:
    // - has pixel format .rgba32Float
    // - is backed by an MTLBuffer
    // - can be used by mglBltTextureCommand
    // - can be read by mglReadTextureCommand
    // - can be removed by mglDeleteTextureCommand
    static func makeTexture(
        device: MTLDevice,
        text: String,
        parameters: mglTextRenderingParameters,
        logger: mglLogger
    ) -> mglRenderedTextTexture? {

        guard parameters.fontSize.isFinite, parameters.fontSize > 0 else {
            logger.error(
                component: "mglTextTextureRenderer",
                details: "Cannot render text with invalid font size \(parameters.fontSize)."
            )
            return nil
        }

        guard !parameters.fontName.isEmpty else {
            logger.error(
                component: "mglTextTextureRenderer",
                details: "Cannot render text with an empty font name."
            )
            return nil
        }

        // Create a Core Text font.
        //
        // Core Text will generally provide a fallback font if it cannot find
        // the requested name.
        let font = CTFontCreateWithName(
            parameters.fontName as CFString,
            CGFloat(parameters.fontSize),
            nil
        )

        // Clamp colors defensively.  The current state setter verifies that
        // values are finite, but it intentionally does not yet require [0, 1].
        let foregroundRed = clampColor(parameters.foregroundRed)
        let foregroundGreen = clampColor(parameters.foregroundGreen)
        let foregroundBlue = clampColor(parameters.foregroundBlue)
        let foregroundAlpha = clampColor(parameters.foregroundAlpha)

        let backgroundRed = clampColor(parameters.backgroundRed)
        let backgroundGreen = clampColor(parameters.backgroundGreen)
        let backgroundBlue = clampColor(parameters.backgroundBlue)
        let backgroundAlpha = clampColor(parameters.backgroundAlpha)

        let foregroundColor = CGColor(
            red: CGFloat(foregroundRed),
            green: CGFloat(foregroundGreen),
            blue: CGFloat(foregroundBlue),
            alpha: CGFloat(foregroundAlpha)
        )

        let backgroundColor = CGColor(
            red: CGFloat(backgroundRed),
            green: CGFloat(backgroundGreen),
            blue: CGFloat(backgroundBlue),
            alpha: CGFloat(backgroundAlpha)
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor
        ]

        let attributedText = NSAttributedString(
            string: text,
            attributes: attributes
        )

        let line = CTLineCreateWithAttributedString(attributedText)

        // Measure the actual text width, but use the font's full line height.
        //
        // This matches the intent of the existing Python implementation:
        //
        //   text width:  actual string
        //   text height: representative full font height
        //
        // Using ascent + descent + leading gives short strings such as "."
        // or "i" a normal, useful text texture height.
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0

        let textAdvanceWidth = CTLineGetTypographicBounds(
            line,
            &ascent,
            &descent,
            &leading
        )

        let fontLineHeight = max(
            1,
            Int(ceil(ascent + descent + leading))
        )

        let paddingPixels = Int(parameters.paddingPixels)

        let textureWidth = max(
            1,
            Int(ceil(textAdvanceWidth)) + 2 * paddingPixels
        )

        let textureHeight = max(
            1,
            fontLineHeight + 2 * paddingPixels
        )

        guard textureWidth <= Int(UInt32.max),
              textureHeight <= Int(UInt32.max) else {
            logger.error(
                component: "mglTextTextureRenderer",
                details: "Requested text texture is too large: \(textureWidth) x \(textureHeight)."
            )
            return nil
        }

        // First render into a normal Core Graphics bitmap:
        //
        //   4 UInt8 components per pixel
        //   premultiplied alpha
        //   little-endian memory layout
        //
        // On current little-endian Apple platforms this gives BGRA bytes:
        //
        //   byte 0: blue
        //   byte 1: green
        //   byte 2: red
        //   byte 3: alpha
        let bitmapBytesPerPixel = 4
        let bitmapBytesPerRow = textureWidth * bitmapBytesPerPixel
        let bitmapByteCount = bitmapBytesPerRow * textureHeight

        var bitmapPixels = [UInt8](
            repeating: 0,
            count: bitmapByteCount
        )

        let didDrawText = bitmapPixels.withUnsafeMutableBytes {
            rawBitmapBytes -> Bool in

            guard let bitmapBaseAddress = rawBitmapBytes.baseAddress else {
                return false
            }

            guard let context = CGContext(
                data: bitmapBaseAddress,
                width: textureWidth,
                height: textureHeight,
                bitsPerComponent: 8,
                bytesPerRow: bitmapBytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:
                    CGImageAlphaInfo.premultipliedFirst.rawValue |
                    CGBitmapInfo.byteOrder32Little.rawValue
            ) else {
                return false
            }

            let wholeTextureRect = CGRect(
                x: 0,
                y: 0,
                width: textureWidth,
                height: textureHeight
            )

            // Fill the whole bitmap with the configured background color.
            //
            // With the initial defaults this is transparent black, matching:
            //
            // Image.new("RGBA", size, (0, 0, 0, 0))
            context.setFillColor(backgroundColor)
            context.fill(wholeTextureRect)

            // Core Text uses Core Graphics' usual y-up coordinate system.
            context.textMatrix = .identity

            // Place the text baseline above the bottom padding.
            //
            // descent provides room below the baseline for glyph descenders
            // such as g, j, p, q, and y.
            context.textPosition = CGPoint(
                x: CGFloat(paddingPixels),
                y: CGFloat(paddingPixels) + descent
            )

            CTLineDraw(line, context)

            return true
        }

        guard didDrawText else {
            logger.error(
                component: "mglTextTextureRenderer",
                details: "Could not create Core Graphics bitmap context for text."
            )
            return nil
        }

        // Create the same Metal texture type as mglCreateTexture().
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: textureWidth,
            height: textureHeight,
            mipmapped: false
        )

        textureDescriptor.usage = [
            .renderTarget,
            .shaderRead,
            .shaderWrite
        ]

        // .rgba32Float means:
        //
        // 4 channels * 4 bytes per Float = 16 bytes/pixel.
        let imageRowByteCount =
            textureWidth * 4 * MemoryLayout<Float>.stride

        // A buffer-backed Metal texture requires each row to satisfy Metal's
        // platform/device-specific alignment requirement.
        let rowAlignment = device.minimumLinearTextureAlignment(
            for: textureDescriptor.pixelFormat
        )

        let alignedRowByteCount =
            ((imageRowByteCount + rowAlignment - 1) / rowAlignment) *
            rowAlignment

        let textureBufferByteCount =
            alignedRowByteCount * textureHeight

        guard let textureBuffer = device.makeBuffer(
            length: textureBufferByteCount,
            options: .storageModeManaged
        ) else {
            logger.error(
                component: "mglTextTextureRenderer",
                details: """
                Could not allocate text texture buffer of \
                \(textureBufferByteCount) bytes for \
                \(textureWidth) x \(textureHeight) text texture.
                """
            )
            return nil
        }

        // Convert Core Graphics BGRA8 premultiplied-alpha pixels into mgl's
        // RGBA Float32 format.
        //
        // Core Graphics stores RGB premultiplied by alpha.  The existing mgl
        // texture blend pipeline uses sourceAlpha blending:
        //
        // source RGB factor: sourceAlpha
        // destination RGB factor: oneMinusSourceAlpha
        //
        // Therefore we convert to straight-alpha RGB by unpremultiplying.
        let textureBufferBaseAddress = textureBuffer.contents()

        for destinationRow in 0 ..< textureHeight {
            let sourceRow = destinationRow

            let sourceRowOffset = sourceRow * bitmapBytesPerRow

            let destinationRowAddress = textureBufferBaseAddress.advanced(
                by: destinationRow * alignedRowByteCount
            )

            let destinationPixels = destinationRowAddress.bindMemory(
                to: Float.self,
                capacity: textureWidth * 4
            )

            for column in 0 ..< textureWidth {
                let sourceOffset =
                    sourceRowOffset + column * bitmapBytesPerPixel

                let bluePremultiplied =
                    Float(bitmapPixels[sourceOffset + 0]) / 255.0

                let greenPremultiplied =
                    Float(bitmapPixels[sourceOffset + 1]) / 255.0

                let redPremultiplied =
                    Float(bitmapPixels[sourceOffset + 2]) / 255.0

                let alpha =
                    Float(bitmapPixels[sourceOffset + 3]) / 255.0

                let destinationOffset = column * 4

                if alpha > 0 {
                    destinationPixels[destinationOffset + 0] =
                        redPremultiplied / alpha

                    destinationPixels[destinationOffset + 1] =
                        greenPremultiplied / alpha

                    destinationPixels[destinationOffset + 2] =
                        bluePremultiplied / alpha
                } else {
                    destinationPixels[destinationOffset + 0] = 0
                    destinationPixels[destinationOffset + 1] = 0
                    destinationPixels[destinationOffset + 2] = 0
                }

                destinationPixels[destinationOffset + 3] = alpha
            }
        }

        // Notify Metal that the CPU wrote into this managed buffer.
        textureBuffer.didModifyRange(0 ..< textureBufferByteCount)

        // Create an MTLTexture that uses the buffer's memory.
        guard let texture = textureBuffer.makeTexture(
            descriptor: textureDescriptor,
            offset: 0,
            bytesPerRow: alignedRowByteCount
        ) else {
            logger.error(
                component: "mglTextTextureRenderer",
                details: """
                Could not make Metal text texture from \
                \(textureWidth) x \(textureHeight) texture buffer.
                """
            )
            return nil
        }

        return mglRenderedTextTexture(
            texture: texture,
            width: UInt32(textureWidth),
            height: UInt32(textureHeight)
        )
    }

    // Clamp an incoming text color component to the normal [0, 1] range.
    private static func clampColor(_ value: Float) -> Float {
        return min(max(value, 0.0), 1.0)
    }
}
