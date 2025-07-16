#if os(iOS) || os(tvOS)
import UIKit
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

/// Most GIFs run between 15 and 24 Frames per second.
///
/// If a GIF does not have (frame-)durations stored in its metadata,
/// this default framerate is used to calculate the GIFs duration.
private let defaultFrameRate: Double = 15.0

/// Default Fallback Frame-Duration based on `defaultFrameRate`
private let defaultFrameDuration: Double = 1 / defaultFrameRate

/// Threshold used in `capDuration` for a FrameDuration
private let capDurationThreshold: Double = 0.01

/// Frameduration used, if a frame-duration is below `capDurationThreshold`
private let minFrameDuration: Double = 0.01

/// Retruns the duration of a frame at a specific index using an image source (an `CGImageSource` instance).
///
/// - returns: A frame duration.
func CGImageFrameDuration(with imageSource: CGImageSource, atIndex index: Int) -> TimeInterval {
  guard imageSource.isAnimatedGIF else { return 0.0 }
  
    // Return nil, if the properties do not store a FrameDuration or FrameDuration <= 0
    guard let duration = imageSource.duration(at: index),
          duration > 0
    else {
        return defaultFrameDuration
    }
  
    return capDuration(with: duration)
}

/// Ensures that a duration is never smaller than a threshold value.
///
/// - returns: A capped frame duration.
func capDuration(with duration: Double) -> Double {
  let cappedDuration = duration < capDurationThreshold ? 0.1 : duration
  return cappedDuration
}

/// An extension of `CGImageSourceRef` that adds GIF introspection and easier property retrieval.
public extension CGImageSource {

    var isTypeGIF: Bool {
        UTType((CGImageSourceGetType(self) as? String ?? ""))?.conforms(to: .gif) ?? false
    }
    
    var isTypeHEICS: Bool {
        (CGImageSourceGetType(self) as? String) == "public.heics"
    }
    
    var isTypeAPNG: Bool {
        UTType((CGImageSourceGetType(self) as? String ?? ""))?.conforms(to: .png) ?? false
    }
    
    var isTypeWebp: Bool {
        UTType((CGImageSourceGetType(self) as? String ?? ""))?.conforms(to: .webP) ?? false
    }
  
    /// Returns whether the image source contains an animated GIF.
    ///
    /// - returns: A boolean value that is `true` if the image source contains animated GIF data.
    var isAnimatedGIF: Bool {
        let imageCount = CGImageSourceGetCount(self)
        return imageCount > 1
    }
    
    func duration(at index: Int) -> TimeInterval? {
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(self, index, nil) as? [CFString: AnyObject] else {
            return nil
        }
         
        return duration(imageProperties: imageProperties)
    }
    
    func duration(imageProperties: [CFString: Any]) -> TimeInterval? {
        if isTypeGIF {
            guard let gifProperties = imageProperties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
                return nil
            }
            
            return duration(
                withUnclampedTime: gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval,
                andClampedTime: gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
            )
        } else if isTypeHEICS {
            if #available(iOS 13.0, *) {
                guard let heicsProperties = imageProperties[kCGImagePropertyHEICSDictionary] as? [CFString: Any] else {
                    return nil
                }
                
                return duration(
                    withUnclampedTime: heicsProperties[kCGImagePropertyHEICSUnclampedDelayTime] as? TimeInterval,
                    andClampedTime: heicsProperties[kCGImagePropertyHEICSDelayTime] as? TimeInterval
                )
            } else {
                return nil
            }
        } else if isTypeAPNG {
            guard let apngProperties = imageProperties[kCGImagePropertyPNGDictionary] as? [CFString: Any] else {
                return nil
            }
            
            return duration(
                withUnclampedTime: apngProperties[kCGImagePropertyAPNGUnclampedDelayTime] as? TimeInterval,
                andClampedTime: apngProperties[kCGImagePropertyAPNGDelayTime] as? TimeInterval
            )
        } else if isTypeWebp {
            guard let webpProperties = imageProperties[kCGImagePropertyWebPDictionary] as? [CFString: Any] else {
                return nil
            }
            
            return duration(
                withUnclampedTime: webpProperties[kCGImagePropertyWebPUnclampedDelayTime] as? TimeInterval,
                andClampedTime: webpProperties[kCGImagePropertyWebPDelayTime] as? TimeInterval
            )
        } else {
            return nil
        }
    }
    
    /// Calculates frame duration based on both clamped and unclamped times.
    ///
    /// - returns: A frame duration.
    func duration(withUnclampedTime unclampedDelayTime: Double?, andClampedTime delayTime: Double?) -> TimeInterval? {
        let delayArray = [unclampedDelayTime, delayTime]
        return delayArray.compactMap { $0 }.filter({ $0 >= 0 }).first
    }
    
}

#endif
