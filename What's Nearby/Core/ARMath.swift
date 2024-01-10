//
//  ARMath.swift
//  Whats Nearby
//
//  Created by Luis David Ortiz on 3/09/23.
//

import Foundation
import CoreLocation

class ARMath {
    static func deg2rad(_ degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }
    
    static func rad2deg(_ rads: Double) -> Double {
        return rads * 180.0 / Double.pi
    }
    
    // atag ( sin ( dif. long.) * cos (long2),
    //        cos (lat1) * sin (lat2) - sin (lat1) * cos (lat2) * cos (dif. long.) )
    
    static func direction(from p1: CLLocation, to p2: CLLocation) -> Double {
        let difLong = p2.coordinate.longitude - p1.coordinate.longitude
        
        let y = sin(difLong) * cos(p2.coordinate.longitude)
        let x = cos(p1.coordinate.latitude) * sin(p2.coordinate.latitude) - sin(p1.coordinate.latitude) * cos(p2.coordinate.latitude) * cos(difLong)
        
        let atanRad = atan2(y, x)
        
        return rad2deg(atanRad)
    }
    
    static func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
        return min(max(value, lower), upper)
    }
}
